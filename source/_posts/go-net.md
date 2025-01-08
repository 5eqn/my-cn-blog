---
title: Go 处理 HTTP 请求的回调机制分析
date: 2023-06-13 13:20:10
tags:
- 编程
- 后端
---

在写 HTTP 服务的时候，我时常感觉 Go 能够对 HTTP 事件注册回调是一件很神奇的事情。来自网络的 HTTP 请求是如何映射到回调函数的参数的？昨天晚上我本来打算 10 点睡觉，看《杀戮尖塔》铁甲战士分析看到 11 点，突然想到这个问题，于是想看看在 LLVM 语言里面是如何实现 HTTP 服务的。

经过一段时间的资料搜寻，我发现核心在于对 Socket 的处理。据我过去对 Socket 的理解，它应该是个和文件很像的东西，但是有一些神秘的事件函数。这引出一个问题：这些函数是如何实现的？是基于文件系统实现的吗？如果是这样的话，感觉两边都要在同一个文件里塞一堆奇奇怪怪的东西，似乎不那么线程安全。今天我想到可以看 Go 的源码，所以准备尝试一下。

## 从 http.ListenAndServe 开始

在 Socket 之前，大部分其实都是一些封装和判断:

```go
func ListenAndServe(addr string, handler Handler) error {
    // 封装
    server := &Server{Addr: addr, Handler: handler}
    return server.ListenAndServe()
}

func (srv *Server) ListenAndServe() error {
    // 判断服务器是否能跑
    if srv.shuttingDown() {
        return ErrServerClosed
    }

    // 封装默认值
    addr := srv.Addr
    if addr == "" {
        addr = ":http"
    }

    // 封装调用
    ln, err := net.Listen("tcp", addr)
    if err != nil {
        return err
    }

    // 我们暂时不管 Serve
    return srv.Serve(ln)
}

func Listen(network, address string) (Listener, error) {
    // 封装
    var lc ListenConfig
    return lc.Listen(context.Background(), network, address)
}

func (lc *ListenConfig) Listen(ctx context.Context, network, address string) (Listener, error) {
    // 获取类型，准备判断
    addrs, err := DefaultResolver.resolveAddrList(ctx, "listen", network, address, nil)
    if err != nil {
        return nil, &OpError{Op: "listen", Net: network, Source: nil, Addr: nil, Err: err}
    }
    sl := &sysListener{
        ListenConfig: *lc,
        network:      network,
        address:      address,
    }
    var l Listener

    // 判断类型
    la := addrs.first(isIPv4)
    switch la := la.(type) {
    case *TCPAddr:
        l, err = sl.listenTCP(ctx, la)
    case *UnixAddr:
        l, err = sl.listenUnix(ctx, la)
    default:
        return nil, &OpError{Op: "listen", Net: sl.network, Source: nil, Addr: la, Err: &AddrError{Err: "unexpected address type", Addr: address}}
    }
    if err != nil {
        return nil, &OpError{Op: "listen", Net: sl.network, Source: nil, Addr: la, Err: err} // l is non-nil interface containing nil pointer
    }
    return l, nil
}
```

到这一层开始略有抽象：

```go
func (sl *sysListener) listenTCP(ctx context.Context, laddr *TCPAddr) (*TCPListener, error) {
    var ctrlCtxFn func(cxt context.Context, network, address string, c syscall.RawConn) error
    if sl.ListenConfig.Control != nil {
        ctrlCtxFn = func(cxt context.Context, network, address string, c syscall.RawConn) error {
            return sl.ListenConfig.Control(network, address, c)
        }
    }
    fd, err := internetSocket(ctx, sl.network, laddr, nil, syscall.SOCK_STREAM, 0, "listen", ctrlCtxFn)
    if err != nil {
        return nil, err
    }
    return &TCPListener{fd: fd, lc: sl.ListenConfig}, nil
}
```

可以看到 Listen 函数返回的都是 Listener 对象，但这个 Listener 是否带有回调函数呢？我们不妨看一下 TCPListener 的定义：

```go
// TCPListener is a TCP network listener. Clients should typically
// use variables of type Listener instead of assuming TCP.
type TCPListener struct {
    // FD 是 Net Socket 的 File Descriptor
    fd *netFD
    lc ListenConfig
}

// Network file descriptor.
type netFD struct {
    pfd poll.FD

    // immutable until Close
    family      int
    sotype      int
    isConnected bool // handshake completed or use of association with peer
    net         string
    laddr       Addr
    raddr       Addr
}

// FD is a file descriptor. The net and os packages use this type as a
// field of a larger type representing a network connection or OS file.
type FD struct {
    // Lock sysfd and serialize access to Read and Write methods.
    fdmu fdMutex

    // System file descriptor. Immutable until Close.
    Sysfd int

    // I/O poller.
    pd pollDesc

    // Writev cache.
    iovecs *[]syscall.Iovec

    // Semaphore signaled when file is closed.
    csema uint32

    // Non-zero if this file has been set to blocking mode.
    isBlocking uint32

    // Whether this is a streaming descriptor, as opposed to a
    // packet-based descriptor like a UDP socket. Immutable.
    IsStream bool

    // Whether a zero byte read indicates EOF. This is false for a
    // message based socket connection.
    ZeroReadIsEOF bool

    // Whether this is a file rather than a network socket.
    isFile bool
}
```

可以看到最后 FD 收敛成了一个 int，和 Linux API 里面一样。

在 fd_unix.go 里面可以看到有 Recv 函数：

```go
// ReadFromInet4 wraps the recvfrom network call for IPv4.
func (fd *FD) ReadFromInet4(p []byte, from *syscall.SockaddrInet4) (int, error) {
    if err := fd.readLock(); err != nil {
        return 0, err
    }
    defer fd.readUnlock()
    if err := fd.pd.prepareRead(fd.isFile); err != nil {
        return 0, err
    }
    for {
        n, err := unix.RecvfromInet4(fd.Sysfd, p, 0, from)
        if err != nil {
            if err == syscall.EINTR {
                continue
            }
            n = 0
            if err == syscall.EAGAIN && fd.pd.pollable() {
                if err = fd.pd.waitRead(fd.isFile); err == nil {
                    continue
                }
            }
        }
        err = fd.eofError(n, err)
        return n, err
    }
}

//go:linkname RecvfromInet4 syscall.recvfromInet4
//go:noescape
func RecvfromInet4(fd int, p []byte, flags int, from *syscall.SockaddrInet4) (int, error)
```

那么回调机制是如何实现的呢？回调意味着没有请求的时候不执行函数，有请求了再执行，但由于这种底层操作并没有异步机制，所以理论上需要疯狂重试。实际上看上面的代码确实有一个 for loop，同时接受 syscall.EAGAIN 错误，这个错误正是表示「现在没有资源可以获取，请重试」。

但同步变异步的机制真的是这样的吗？可以看到还有一个有趣的 fd.pd.waitRead 函数，首先 pd 的类型是：

```go
type pollDesc struct {
    runtimeCtx uintptr
}
```

Golang 官方没有给出注释，继续看 wait 函数：

```go
func (pd *pollDesc) waitRead(isFile bool) error {
    return pd.wait('r', isFile)
}

func (pd *pollDesc) wait(mode int, isFile bool) error {
    if pd.runtimeCtx == 0 {
        return errors.New("waiting for unsupported file type")
    }
    res := runtime_pollWait(pd.runtimeCtx, mode)
    return convertErr(res, isFile)
}

func runtime_pollWait(ctx uintptr, mode int) int
```

可以看到最后也变成了一个 unimplemented 的函数，这个函数是否会延时还是未知数……

但经过一段时间的查找，我发现这玩意实际上在 runtime 包里实现了：

```go
func poll_runtime_pollWait(pd *pollDesc, mode int) int {
    err := netpollcheckerr(pd, int32(mode))
    if err != 0 {
        return err
    }
    if GOOS == "solaris" || GOOS == "illumos" || GOOS == "aix" {
        netpollarm(pd, mode)
    }
    for !netpollblock(pd, int32(mode), false) {
        err = netpollcheckerr(pd, int32(mode))
        if err != 0 {
            return err
        }
    }
    return 0
}
```

这里面有个非常明显的 netpollblock 轮询，所以并不是靠前面的 EAGAIN 实现轮询，而是 runtime_pollWait 本身有延时功能。

## Socket

刚刚 listenTCP 里面的 internetSocket 函数还没看，但可以发现 Socket 最终收敛成了一个 RawSyscall:

```go
func internetSocket(ctx context.Context, net string, laddr, raddr sockaddr, sotype, proto int, mode string, ctrlCtxFn func(context.Context, string, string, syscall.RawConn) error) (fd *netFD, err error) {
    if (runtime.GOOS == "aix" || runtime.GOOS == "windows" || runtime.GOOS == "openbsd") && mode == "dial" && raddr.isWildcard() {
        raddr = raddr.toLocal(net)
    }
    family, ipv6only := favoriteAddrFamily(net, laddr, raddr, mode)
    return socket(ctx, net, family, sotype, proto, ipv6only, laddr, raddr, ctrlCtxFn)
}

// socket returns a network file descriptor that is ready for
// asynchronous I/O using the network poller.
func socket(ctx context.Context, net string, family, sotype, proto int, ipv6only bool, laddr, raddr sockaddr, ctrlCtxFn func(context.Context, string, string, syscall.RawConn) error) (fd *netFD, err error) {
    s, err := sysSocket(family, sotype, proto)
    if err != nil {
        return nil, err
    }

    // 注册 socket...
}

// Wrapper around the socket system call that marks the returned file
// descriptor as nonblocking and close-on-exec.
func sysSocket(family, sotype, proto int) (int, error) {
    s, err := socketFunc(family, sotype|syscall.SOCK_NONBLOCK|syscall.SOCK_CLOEXEC, proto)
    if err != nil {
        return -1, os.NewSyscallError("socket", err)
    }
    return s, nil
}

// 重定向到 syscall
socketFunc        func(int, int, int) (int, error)  = syscall.Socket

// 下面都是 syscall 的函数了
func Socket(domain, typ, proto int) (fd int, err error) {
    if domain == AF_INET6 && SocketDisableIPv6 {
        return -1, EAFNOSUPPORT
    }
    fd, err = socket(domain, typ, proto)
    return
}

func socket(domain int, typ int, proto int) (fd int, err error) {
    r0, _, e1 := RawSyscall(SYS_SOCKET, uintptr(domain), uintptr(typ), uintptr(proto))
    fd = int(r0)
    if e1 != 0 {
        err = errnoErr(e1)
    }
    return
}

func RawSyscall(trap, a1, a2, a3 uintptr) (r1, r2 uintptr, err Errno) {
    return RawSyscall6(trap, a1, a2, a3, 0, 0, 0)
}

func RawSyscall6(trap, a1, a2, a3, a4, a5, a6 uintptr) (r1, r2 uintptr, err Errno)
```

但是在上面的代码中我们没有看到任何回调，只有 netpollwait 这种同步变异步的东西，所以……

## 看 srv.Serve！

首先需要明确回调函数在 Server 结构体里面，Socket 数据结构在 ln 里面，接下来看看能不能找到对 socket 含有 netpollwait 函数的直接调用：

```go
func (srv *Server) Serve(l net.Listener) error {

    // 疑似测试语句`
    if fn := testHookServerServe; fn != nil {
        fn(srv, l) // call hook with unwrapped listener
    }

    // 封装 Listener
    origListener := l
    l = &onceCloseListener{Listener: l}
    defer l.Close()

    // 疑似封装回调函数
    if err := srv.setupHTTP2_Serve(); err != nil {
        return err
    }

    // 判断服务状态
    if !srv.trackListener(&l, true) {
        return ErrServerClosed
    }
    defer srv.trackListener(&l, false)

    // 对尝试获取连接的操作建立上下文
    baseCtx := context.Background()
    if srv.BaseContext != nil {
        baseCtx = srv.BaseContext(origListener)
        if baseCtx == nil {
            panic("BaseContext returned a nil context")
        }
    }

    var tempDelay time.Duration // how long to sleep on accept failure

    ctx := context.WithValue(baseCtx, ServerContextKey, srv)
    for {
        // 调用 socket 建立连接
        rw, err := l.Accept()
        if err != nil {

            // 判断服务状态
            if srv.shuttingDown() {
                return ErrServerClosed
            }

            // 指数提升重试时间
            if ne, ok := err.(net.Error); ok && ne.Temporary() {
                if tempDelay == 0 {
                    tempDelay = 5 * time.Millisecond
                } else {
                    tempDelay *= 2
                }
                if max := 1 * time.Second; tempDelay > max {
                    tempDelay = max
                }
                srv.logf("http: Accept error: %v; retrying in %v", err, tempDelay)
                time.Sleep(tempDelay)
                continue
            }
            return err
        }

        // 对连接初始化上下文
        connCtx := ctx
        if cc := srv.ConnContext; cc != nil {
            connCtx = cc(connCtx, rw)
            if connCtx == nil {
                panic("ConnContext returned nil")
            }
        }
        tempDelay = 0

        // 对连接信息进行侦听
        c := srv.newConn(rw)
        c.setState(c.rwc, StateNew, runHooks) // before Serve can return
        go c.serve(connCtx)
    }
}
```

对 Socket Accept 函数的调用并没有直接导致 srv 回调函数的调用，因为这里有一个「建立连接」的概念，只有连接建立之后才能继续收信息传给 srv. 同时，这里连接建立之后 Golang 选择开一个 goroutine 去处理这个连接。因此我们看一看 newConn 的 serve 函数：

```go
// Serve a new connection.
func (c *conn) serve(ctx context.Context) {
    c.remoteAddr = c.rwc.RemoteAddr().String()
    ctx = context.WithValue(ctx, LocalAddrContextKey, c.rwc.LocalAddr())
    var inFlightResponse *response
    defer func() {
        // 服务器挂了之后的收尾函数...
    }()

    if tlsConn, ok := c.rwc.(*tls.Conn); ok {
        // 处理 HTTPS...
    }

    // HTTP/1.x from here on.

    ctx, cancelCtx := context.WithCancel(ctx)
    c.cancelCtx = cancelCtx
    defer cancelCtx()

    // c.rwc 是 listen 得到的 reader，以下只是封装
    c.r = &connReader{conn: c}
    c.bufr = newBufioReader(c.r)
    c.bufw = newBufioWriterSize(checkConnErrorWriter{c}, 4<<10)

    for {
        // 读取请求
        w, err := c.readRequest(ctx)
        if c.r.remain != c.server.initialReadLimitSize() {
            // If we read any bytes off the wire, we're active.
            c.setState(c.rwc, StateActive, runHooks)
        }
        if err != nil {
            // HTTP 错误处理...
        }

        // 处理请求的一些 Header 性质的特性...
        
        // 调用回调函数，虽然非常封装，输出直接发 writer 里面去
        serverHandler{c.server}.ServeHTTP(w, w.req)
        
        // 收尾...
    }
}
```

函数有删减，原本里面一大堆判断，但我们关注的只是回调函数的调用。基本上可以看出一个读取请求到调用回调函数的结构。不过对 readRequest 进行溯源最多到一个 Reader，至于如何和 Socket 关联，还得回去看 rw 的构造（这个是 l.Accept() 出来的东西）以及 srv.ConnContext 到底干了什么（它怎么是个函数？）

不对，connCtx 和 rw 只是为了更新 Context，实际上 rw 真正生效是在 srv.newConn(rw) 里面。

```go
// Create new connection from rwc.
func (srv *Server) newConn(rwc net.Conn) *conn {
    c := &conn{
        server: srv,
        rwc:    rwc,
    }
    if debugServerConnections {
        c.rwc = newLoggingConn("server", c.rwc)
    }
    return c
}
```

可以看到 newConn 只是一个简单封装，同时 net.Conn 溯源其实最后也是到一些 Reader：

```go
// Conn is a generic stream-oriented network connection.
//
// Multiple goroutines may invoke methods on a Conn simultaneously.
type Conn interface {
    // Read reads data from the connection.
    // Read can be made to time out and return an error after a fixed
    // time limit; see SetDeadline and SetReadDeadline.
    Read(b []byte) (n int, err error)

    // Write writes data to the connection.
    // Write can be made to time out and return an error after a fixed
    // time limit; see SetDeadline and SetWriteDeadline.
    Write(b []byte) (n int, err error)

    // ...
}
```

同时注意 conn.serve 里面对 conn.rwc 的封装，所以最后对 socket 溯源还得看 rw 的生成。然而，net.Listener 只是一个接口，我们需要想办法获取它在我的应用场景下的实现。在前面的小节里，我们知道 TCPListener 是这样的一个实现，因此看其 Listen 函数：

```go
// Accept implements the Accept method in the Listener interface; it
// waits for the next call and returns a generic Conn.
func (l *TCPListener) Accept() (Conn, error) {
    if !l.ok() {
        return nil, syscall.EINVAL
    }
    c, err := l.accept()
    if err != nil {
        return nil, &OpError{Op: "accept", Net: l.fd.net, Source: nil, Addr: l.fd.laddr, Err: err}
    }
    return c, nil
}

func (ln *TCPListener) accept() (*TCPConn, error) {
    fd, err := ln.fd.accept()
    if err != nil {
        return nil, err
    }
    return newTCPConn(fd, ln.lc.KeepAlive, nil), nil
}

func (fd *netFD) accept() (netfd *netFD, err error) {
    d, rsa, errcall, err := fd.pfd.Accept()
    if err != nil {
        if errcall != "" {
            err = wrapSyscallError(errcall, err)
        }
        return nil, err
    }

    if netfd, err = newFD(d, fd.family, fd.sotype, fd.net); err != nil {
        poll.CloseFunc(d)
        return nil, err
    }
    if err = netfd.init(); err != nil {
        netfd.Close()
        return nil, err
    }
    lsa, _ := syscall.Getsockname(netfd.pfd.Sysfd)
    netfd.setAddr(netfd.addrFunc()(lsa), netfd.addrFunc()(rsa))
    return netfd, nil
}

// Accept wraps the accept network call.
func (fd *FD) Accept() (int, syscall.Sockaddr, string, error) {
    if err := fd.readLock(); err != nil {
        return -1, nil, "", err
    }
    defer fd.readUnlock()

    if err := fd.pd.prepareRead(fd.isFile); err != nil {
        return -1, nil, "", err
    }
    for {
        s, rsa, errcall, err := accept(fd.Sysfd)
        if err == nil {
            return s, rsa, "", err
        }
        switch err {
        case syscall.EINTR:
            continue
        case syscall.EAGAIN:
            if fd.pd.pollable() {
                if err = fd.pd.waitRead(fd.isFile); err == nil {
                    continue
                }
            }
        case syscall.ECONNABORTED:
            // This means that a socket on the listen
            // queue was closed before we Accept()ed it;
            // it's a silly error, so try again.
            continue
        }
        return -1, nil, errcall, err
    }
}

// Wrapper around the accept system call that marks the returned file
// descriptor as nonblocking and close-on-exec.
func accept(s int) (int, syscall.Sockaddr, string, error) {
    ns, sa, err := Accept4Func(s, syscall.SOCK_NONBLOCK|syscall.SOCK_CLOEXEC)
    if err != nil {
        return -1, sa, "accept4", err
    }
    return ns, sa, "", nil
}

// Accept4Func is used to hook the accept4 call.
var Accept4Func func(int, int) (int, syscall.Sockaddr, error) = syscall.Accept4
```

可以看到最终到了 unimplemented 的函数，同时也看到了熟悉的 syscall.EAGAIN

## 总结

Go 对 HTTP 回调函数的处理机制就是先尝试形成连接（采用了指数增加的等待时间），然后对于每个连接去开一个 goroutine 去 listen，listen 里面最终的实现应该基于轮询，最终直接调用回调函数。
