---
title: Idris2 中 IO Monad 的实现
date: 2023-06-15 19:31:58
tags:
- 编程
- PL
---

上一次我们提到 Idris2 中的 IO 的形式是直接使用 IO Monad，main 函数的类型签名就是 IO (). 然而，我也独立发现了 io# -> io# 的形式。这两种形式之间有什么对应关系？

## %World, PrimIO 和 IO

通过 Idris2 源码可以看到 PrimIO 的定义：

```haskell
public export
PrimIO : Type -> Type
PrimIO a = (1 x : %World) -> IORes a
```

注意 PrimIO 不只是对 %World 的封装，其本身已经是一个函数了。

同时 IORes 的定义如下：

```haskell
public export
data IORes : Type -> Type where
     MkIORes : (result : a) -> (1 x : %World) -> IORes a
```

也就是说，io#a 的写法和 MkIORes a io 是同构的，只是这里 io 对应的是 %World.

再看看 IO 的定义：

```haskell
export
data IO : Type -> Type where
     MkIO : (1 fn : PrimIO a) -> IO a
```

可以看到 IO 确实是对 PrimIO a 的简单封装，只是封装的时候保持了其线性。

这样，如果要用 %World 的层次写 IO，实际上也会变成 %World -> (a, %World). 当 a 是 () 的时候，和 io# -> io# 的写法就是完全同构的了。

同时，由于 prim__getStr 是 PrimIO String 类型的，可以化简成 io# -> io#String, 如果用回合制来理解 Monad，这实际上对应的就是程序逻辑的「另一方」：

```haskell
%foreign "C:idris2_getStr, libidris2_support, idris_support.h"
         "node:support:getStr,support_system_file"
prim__getStr : PrimIO String
```

（修订：其实 IO Monad 的实现里面是直接让变量原封不动 bind 的，来维持线性，所以没有所谓「另一方」，prim__getStr 就是输出不确定的函数。）

至于比较复杂的 Monad 之间如何 bind，还是需要参考 Idris2 的 App 机制。有空继续看源码和论文吧！
