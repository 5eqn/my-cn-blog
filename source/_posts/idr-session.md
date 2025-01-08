---
title: 在 Idris2 中实现多线程会话
date: 2023-06-16 09:54:43
tags:
- 编程
- PL
---

上一篇博客中我提到 fork 函数可以用于创建多线程，那么在 Idris2 中实现多线程通信是否可能呢？在官方的集成测试文档里面，我找到一个例子，这篇博客我们结合论文研究一下这个例子。

## Protocol

要在线程间类型安全地通信，我们首先需要指定发送的包的类型，例如是整数还是字符串。但有时候我们会希望根据收到回复的「值」来决定下一步送什么。指定这样的「类型序列」可以理解成客户端和服务端之间达成了某种「协议」。但根据值而变化的类型序列，在没有依值类型的语言中是不可能不利用反射来描述的，但由于 Idris2 恰好有依值类型，我们看看 Idris2 是如何实现的：

```haskell
public export
data Protocol : Type -> Type where
     Request : (a : Type) -> Protocol a
     Respond : (a : Type) -> Protocol a
     Bind : Protocol a -> (a -> Protocol b) -> Protocol b
     Loop : Inf (Protocol a) -> Protocol a
     Done : Protocol ()
```

注意如果发送的类型序列不能根据值改变，那么 Bind 本应是 Protocol a -> Protocol b -> Protocol b. 现在的 Bind 相比原来的区别就是中间变成了一个关于 a 的「函数」，这也恰巧使得它变成了 Monad Bind 的形式，因此可以使用 do notation 来定义 Protocol:

```haskell
TestProto : Protocol ()
TestProto
    = do b <- Request Bool
         if b
            then do Respond Char; Done
            else do Respond String; Done
```

有 Monad 就有回合制，注意这里每一步相当于给定零个或一个值，由值来决定下一步回复或接受什么类型。而回合制的另一方就是客户端或服务端的具体实现，知道要发送或接受什么类型的值，然后把这个值具体地计算出来。

## 消息传递

这个实现的整体机制和 go channel 非常相似，以 send 为例：

```haskell
export
send : (1 chan : Channel {p} (Send ty next)) -> (val : ty) ->
       One IO (Channel {p} (next val))
send (MkChannel lock cond_lock cond local remote) val
    = do lift $ mutexAcquire lock
         q <- lift $ readIORef remote
         lift $ writeIORef remote (enqueue val q)
         lift $ mutexRelease lock

         lift $ mutexAcquire cond_lock
         lift $ conditionSignal cond
         lift $ mutexRelease cond_lock
         pure (MkChannel lock cond_lock cond local remote)
```

可以看到基本就是先原子地往队列里面加一个 val，然后原子地给 cond 发一个信号。

对于 recv，自然也是接受信号、从队列中取值：

```haskell
export
recv : (1 chan : Channel {p} (Recv ty next)) ->
       One IO (Res ty (\val => Channel {p} (next val)))
recv (MkChannel lock cond_lock cond local remote)
    = do lift $ mutexAcquire lock
         rq <- lift $ readIORef local
         case dequeue rq of
              Nothing => -- ... no message, so wait for condition and try again
                  do lift $ mutexRelease lock
                     lift $ mutexAcquire cond_lock
                     lift $ conditionWait cond cond_lock
                     lift $ mutexRelease cond_lock
                     recv (MkChannel lock cond_lock cond local remote)
              Just (rq', Entry {a=any} val) =>
                  do lift $ writeIORef local rq'
                     lift $ mutexRelease lock
                     pure (believe_me {a=any} val #
                           MkChannel lock cond_lock cond local remote)
```

注意 recv 里面有个不断重试的过程。同时，考虑到有多次写然后多次读的情况（注意队列是有缓冲区的），不能每次读都去等信号，应该直接先尝试能不能读取到值。

## Action

注意上面 send 和 recv 的 Channel 类型签名里面有 Send 和 Recv，这个实际上是 Action 序列，相当于「还有剩下哪些操作要做」。如果说 Protocol 是用于统一 Client 和 Server 的运行逻辑，Action 则是用于给下一步的操作提供类型提示。

Protocol 可以转化成初始的 Action:

```haskell
public export
ClientK : Protocol a -> (a -> Actions b) -> Actions b
ClientK (Request a) k = Send a k
ClientK (Respond a) k = Recv a k
ClientK (Bind act next) k = ClientK act (\res => ClientK (next res) k)
ClientK (Loop proto) k = ClientK proto k
ClientK Done k = k ()
```

## 顶层设计

在有了上面的工作之后，顶层的程序就很清晰了：

```haskell
testClient : (1 chan : Client TestProto) -> Any IO ()
testClient chan
    = do lift $ putStrLn "Starting client"
         lift $ sleep 1
         lift $ putStrLn "Sending value"
         chan <- send chan False
         lift $ putStrLn "Sent"
         c # chan <- recv chan
         lift $ putStrLn ("Result: " ++ c)
         close chan
```

注意由于 chan 携带了一些信息（例如各种锁），IO 没有能力封装这些信息，因此整个程序写成了 IO Monad 的降级形式，如果忽略 close 的话整体上形如 (1 chan : Channel ...) -> (A, chan : Channel ...). 不过这里有一个细节，因为 Channel 的类型签名里面有 Action 的实例，每个步骤之后 Channel 的类型签名会有所变化，因此用到了 Dependent Pair:

```haskell
-- A dependent variant of LPair, pairing a result value with a resource
-- that depends on the result value
public export
data Res : (a : Type) -> (a -> Type) -> Type where
     (#) : (val : a) -> (1 r : t val) -> Res a t
```

同时注意 Idris2 官方写的语法糖形式和我之前自己使用的 chan# -> chan#a 的形式非常相似。

## 昨天的问题

我在 tests 里面还找到 Store 的例子，里面有两种对 Store 这种有状态对象的处理方法：

一种是带着跑：

```haskell
storeProg
    = app1 $ do
         s <- connect
         app $ putStr "Password: "
         pwd <- app $ getLine
         True # s <- login s pwd
              | False # s => do app $ putStrLn "Login failed"
                                app $ disconnect s
         app $ putStrLn "Logged in"
         secret # s <- readSecret s
         app $ putStrLn ("Secret: " ++ secret)
         s <- logout s
         app $ putStrLn "Logged out"
         app $ disconnect s
```

这里 connect 之后直接得到 Store 的线性实例，带着跑就行了，简单直接。同时注意 login 和 readSecret 的语法，这里由于使用的是 App Monad，回合制没有产生效用，所以玄学效应直接由 login 和 readSecret 函数产生。可以看看 login 的类型签名和实现：

```haskell
login : (1 d : Store LoggedOut) -> (password : String) ->
    App1 e (Res Bool (\ok => Store (if ok then LoggedIn else LoggedOut)))
login (MkStore str) pwd
    = if pwd == "Mornington Crescent"
        then pure1 (True # MkStore str)
        else pure1 (False # MkStore str)
```

其类型签名里面有 App，但在实际判断的时候 Idris2 选择了将密码硬编码，就没有玄学效应了。即使有，只需要利用 App 封装的 %World 来实现即可，实际上像 readIORef 这种函数都只是看起来是纯函数，实际上是玄学，并没有依赖 Monad 去封装。

还有一种实现是开个新的存档：

```haskell
storeProg : Has [Console, StoreI] e => App e ()
storeProg
    = let (>>=) = bindL in
      let (>>) = seqL in
        do putStr "Password: "
           password <- Console.getLine
           connect $ \s =>
             do let True # s = login s password
                       | False # s => do putStrLn "Incorrect password"
                                         disconnect s
                putStrLn "Door opened"
                let s = logout s
                putStrLn "Door closed"
                disconnect s
```

注意这里 connect 里面是个全新的世界，虽然里面也要带着 Store 跑；不过注意里面也能访问到 %World，connect 负责给后面的函数喂参数执行，因此 connect 需要把对 %World 的访问权下放到函数里面，其实现应该很有趣：

```haskell
connect : (1 prog : (1 d : Store LoggedOut) ->
          App {l} e ()) -> App {l} e ()
connect f
    = let (>>=) = bindL in
      let (>>) = seqL in
          do putStrLn "Connected"
             f (MkStore "xyzzy")
```

但实际上调用这个函数之后就是一个 App e ()，跟前面带着跑一模一样，不需要特意下放 %World 的所有权。

我们可以得出一个结论：在 Idris2 里面如果要真的带着一堆有状态的东西跑的话是很困难的，但由于 Idris2 的那群开发者喜欢把什么状态都往 IORef 里面存，所以最后有一个 %World 就能走遍天下（他们只是觉得这样性能更高，实际上也觉得丑）。如果我要写语言的话，还是需要找到一个更通用的方法，允许自定义 %World 性质的 Linear Token.

并且由于我发现 Monad 在 IO 中实际上只是起到一个安慰剂的作用，实际上只要把 Monad 的实现展开之后代码里就会充斥着非纯函数，只是如果去掉一些接口（例如不允许透过 IO a 去看里面的内容）就是纯函数了。如果我要写的话，为了统一 IO 和其他状态，我会把 IO 也写成需要带着跑的形式，但对 Monad 的处理不会发生太大变化，因为有个变量作用域的问题：

```haskell
mod : m#A -> m#A
mod m#a = do
  m#b <- m#(f a)
  m#c <- m#(g a b)
  m#c
```

这个运算只依赖一个内存空间不可能完成。但这里我原先的想法是在 m#b 形成后就判定 a 无效，现在感觉允许 f a 出现都是不合理的。这里和 paper 里面的最大不同在于每个变量都对应了一块实际的内存，因此 m 这个 Linear Token 和 a 这个变量应该是绑定的，应该把 m 理解成 (1 a) 里面的 1 本身，但这也会带来无法交换变量的问题……

如果只是单纯强制每个函数（包括构造函数）把值和 token 绑定呢？

```haskell
mod : m#A -> m#A
mod m#a =
  let m#b = f m#a in
  let m#c = g m#a in
  m#c
```

注意 g 不能输入两个参数，否则 m 的使用次数会爆掉。这样虽然 g 在 f 把 b 放到 m 的时候引用了 a，但实际上编译器知道最后的结果是 c，根本不会去计算出 b. 同时也可以交换变量：

```haskell
swap : m#A -> n#A -> m#A, n#A
swap m#a n#b = m#b, n#a
```

编译器最终知道的只是变量的「流向」，至于具体如何用有限的寄存器实现这个流向，是编译器的事情。
 
同时注意到我不再使用 Monad 了，我隐约感觉 Linear Type 的功能完全包括了 Monad 的功能并且更加强大，虽然暂时还无法说明这一点。或许以后我会因此遇到一些问题，但暂时先不用 Monad 吧！
