---
title: 分析 Idris2 中 Control.App 的动机
date: 2023-06-15 21:28:41
tags:
- 编程
- PL
---

Control.App 是 Idris2 用来对一个「应用」和外部世界交互特性建模的类型，和 IO 类似，但是支持和错误处理、State Monad 之类的东西绑定。

## Has 类型

Has 类型的定义如下：

```haskell
public export
0 Has : List (a -> Type) -> a -> Type
Has [] es = ()
Has [e] es = e es
Has (e :: es') es = (e es, Has es' es)
```

其中 `e es` 是一个关于 es 具有性质 e 的证明（博客暂时没有写完整的 Markdown 渲染，其实应该直接用一个轮子的，只是我之前在 github 上面没找到 Flutter 的 Markdown 渲染器）。Has 类型相等于一大堆证明的数组，因为 Idris2 中有大量函数依靠隐式参数，有这个数组之后 Idris2 可以自动利用这个数组中的元素去填充隐式参数，就不需要自己手动填写了，十分方便。

## Environment

注意上面 Has 的第二个参数虽然是个隐式的 a，但在 App 中这个参数的典型值是所谓 Environment，也就是 App 在运行时可能会产生的错误种类的集合，相当于对世界有多不友好的一种表征（？

## IO Monad 接口

既然 Has 的第二个参数是环境，那么 Has 类型想要表达的是这个环境符合某些性质。在 App 中，这些性质通常例如「这个环境下可以实现这个接口」。例如，命令行 IO 不会报任何错，因此对于任意环境都可以实现命令行 IO 的接口。但文件 IO 可能报错，例如文件找不到之类的错误，因此只有对于支持文件错误的环境可以实现文件 IO 的接口。

对于命令行 IO，Idris2 选择了使用 PrimIO 去封装 IO：

```haskell
public export
interface PrimIO e where
  primIO : IO a -> App {l} e a
  primIO1 : (1 act : IO a) -> App1 e a
  -- fork starts a new environment, so that any existing state can't get
  -- passed to it (since it'll be tagged with the wrong environment)
  fork : (forall e' . PrimIO e' => App {l} e' ()) -> App e ()
```

正如前面提到，IO 是对 PrimIO 的封装，PrimIO 是对 %World 的封装，结果这里 PrimIO 又是 IO 的封装，这个重名属实逆天！不过如果理清楚封装关系是 PrimIO -> IO -> PrimIO -> %World 的话，其实也挺清晰。但实际上封装这么多层，我感觉很大程度上是因为底层 prim__getStr 签名写死了 PrimIO a 而不是 %World -> (%World, a) 导致的。

但这个封装只是一个 Interface，它是怎么实现的呢？尤其是这个 fork，虽然在例子里没有用到，但这玩意已经涉及多线程了，极其玄学。

```haskell
export
HasErr AppHasIO e => PrimIO e where
  primIO op =
        MkApp $ \w =>
            let MkAppRes r w = toPrimApp op w in
                MkAppRes (Right r) w

  primIO1 op = MkApp1 $ toPrimApp1 op

  fork thread
      = MkApp $
            prim_app_bind
                (toPrimApp $ Prelude.fork $
                      do run thread
                         pure ())
                    $ \_ =>
               MkAppRes (Right ())
```

可以看到首先 PrimIO e 的实现基于 HasErr AppHasIO e，这等效于 Has [HasErr AppHasIO] e。注意 Has 和 HasErr 的层次不同，一个是说有这个性质但没说性质是什么，另一个只是对性质的客观描述。

注意在实现里面一定会涉及到把 %World 穿过层层封装传递到 IO 里面，找到相关函数的调用栈：

```haskell
toPrimApp : (1 act : IO a) -> PrimApp a
toPrimApp x
    = \w => case toPrim x w of
                 MkIORes r w => MkAppRes r w

export %inline
toPrim : (1 act : IO a) -> PrimIO a
toPrim (MkIO fn) = fn
```

现在应该比较清晰了，x 是 IO a，toPrim x 是 %World -> IORes a，并且注意 IORes a 等效于 (a, %World). primIO 和 primIO1 看起来复杂，实际上只是在封装。

这里 fork 的实现比较有趣。首先多线程是违背函数式程序正常的运行逻辑的，所以一定会有 primitive 函数去实现这个逻辑，只是其封装规则需要尽可能和函数式融为一体。首先看看 Prelude.fork 的调用栈：

```haskell
export
fork : (1 prog : IO ()) -> IO ThreadID
fork act = fromPrim (prim__fork (toPrim act))

%foreign "scheme:blodwen-thread"
         "C:refc_fork"
export
prim__fork : (1 prog : PrimIO ()) -> PrimIO ThreadID

public export
data ThreadID : Type where [external]
```

fork 本身已经能够实现把一段程序「消灭」，然后直接返回它的 ThreadID 之后继续运行后面的程序，所以 App 的 fork 只能是对 Prelude.fork 的封装。可以看到封装的过程实际上也只是先用 run thread 把 thread 从 App e' () 降级成 IO ()，然后用 Prelude.fork 把它变成实际上会跑但是外在上只是瞬间返回 ThreadID 的一个 IO，再用 toPrimApp 把它变成 PrimApp a，把它先和一个表示一定运行成功返回 () 的 \_ => MkAppRes (Right ()) 串联在一起，最后做成最后的 App e t.

## State Monad 接口

仿照 PrimIO 的思想，我们可以用 App 去封装一个 State Monad:

```haskell
export
get : (0 tag : _) -> State tag t e => App {l} e t
get tag @{MkState r}
    = MkApp $
          prim_app_bind (toPrimApp $ readIORef r) $ \val =>
          MkAppRes (Right val)

export
put : (0 tag : _) -> State tag t e => (val : t) -> App {l} e ()
put tag @{MkState r} val
    = MkApp $
          prim_app_bind (toPrimApp $ writeIORef r val) $ \val =>
          MkAppRes (Right ())
```

不过这里其实不是纯正的 State Monad，借助了 IORef 实现状态存取。如果真的需要 State Monad，由于其 run 的时候需要给定一个初始值，State a b 只能被封装成 (a -> App e b)，但这种理解和官方给的 Linear Resource 例子，(1 prog : (1 d : Store LoggedOut) -> App {l} e ()) 封装成 App {l} e ()，应该如何对应上呢？

## 动机讨论

App 看起来似乎只能对各类依赖 %World 的 Monad 进行封装，如果携带其他 Linear Token 或者信息，则需要另寻他法，但我暂时不知道这个「他法」是什么玩意。

App 相当于是给各种错误提供了一个统一的标准，并且后续对资源是否线性进行了一个建模，但正如前面提到有悬而未决的问题，或许我需要看看论文后面用 App 实现 Dependent Session Types 的例子。
