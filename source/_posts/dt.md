---
title: 尝试使用线性类型对内存建模
date: 2023-06-14 21:19:10
tags:
- 编程
- PL
---

在 Idris2 语言里，线性类型一般被用于描述「外部资源」，例如 IO 里面的 %World 以及自定义的一些其他外部资源，并没有强制用户对内存进行这样的建模，因此在内存管理上依然要依赖效率较低的 GC. 然而，如果强制对内存进行建模，或许能解决这个问题。然而，对内存建模是一件相当复杂的事情，所幸我们可以参考 Rust 的内存管理机制和 Unity 的面向数据设计。

## 单个值

假设我们要完成「交换」任务，两个内存地址里面的值的类型都是 A，需要对它们的值进行交换。先尝试随便搓一个：

```haskell
swap : (1 Loc A, 1 Loc A) -> (Loc A, Loc A)
swap (MkLoc a x, MkLoc b y) = (MkLoc a y, MkLoc b x)
```

这样的缺点是在类型签名里反映不出来值的「位置」。但首先如果要反映出来的话，就必须要写成 Dependent Pair 的形式；其次输出的位置和输入的位置并不是同一个变量，而是某种「复制品」，但因为原来那个立即不可用了，所以不需要真的去复制。

写一个 Dependent Pair 的版本试试：

```haskell
swap : ((0 m : Tok ** 1 Loc m A), (0 n : Tok ** 1 Loc n A)) -> ((p : Tok ** Loc p A), (q : Tok ** Loc q A))
swap ((m ** MkLoc m x), (n ** MkLoc n y)) = ((m ** MkLoc m y), (n ** MkLoc n x))
```

但实际上 Dependent Pair 的 LHS 被抹除了，实际使用的时候不需要显式写出 Dependent Pair. 同时在这个场景里面，右边返回 Dependent Pair 也只是为了形式上的一致性。

用一些语法糖便可以写成很简单的形式：

```haskell
swap : m#A, n#A -> p#A, q#A
swap m#x, n#y = m#y, n#x
```

在编译这段程序的时候，如果基础语句里面有 swap 就可以直接调用，没有的话需要手动增加一个临时变量。由于增加临时变量是不符合人类直觉的，其不出现在程序中是一件好事。

## 加入 IO

如果要和 IO 对接，例如处理一个加和的任务，可以：

```haskell
sum : io# -> io#
sum io# = do
  io#a <- io.read#
  m#a, io#b <- MkMem#a, io.read#
  io# <- io.write#(a+b)
  io#
```

为了方便，这里将 Linear Type 弱化为 Affine Type 使 m 被释放。

但通常意义上的 IO 以 Monad 的形式存在，虽然也内置了线性的 %World，但在外面 main 的签名只有一个 IO (). 在这方面我或许需要研究一下 Idris2 的源码，看看我上面写的 io# -> io# 的签名和 IO () 的签名有什么联系。

## 数组

假如要处理数组相加，把结果加到第一个数组里面，如何实现？

```haskell
sum : Vect l m#A, Vect l m#A -> Vect l m#A, Vect l m#A
sum lhs, rhs = unzip ((zip lhs rhs) <$> (\m#a, n#b => m#(a+b), n#b))
```

注意 Dependent Pair 里面新绑定的变量不会和其他 Dependent Pair 之间互相干扰，因为都封装在括号里面。

这里 zip 不能用递归实现，这样可以避免做一些玄学尾递归优化，但通过 zip 之类的函数真的能描述所有的数据并行化处理可能性吗？

还有一种思路是引入类似于 for 循环的东西：

```haskell
sum : Vect l m#A, Vect l m#A -> Vect l m#A, Vect l m#A
sum lhs, rhs = unzip (for l <$> (\i =>
    let m#a = lhs[i] in
    let n#b = rhs[i] in
    m#(a+b), n#b
  ))
```

但看起来似乎更丑了一些，而且问题在于如何检查每个 memory token 都被用到了？玄学和类型检查可不兴叠加在一起啊！

所以或许还是需要尾递归优化：

```haskell
sum : Vect l m#A, Vect l m#A -> Vect l m#A, Vect l m#A
sum [], [] = [], []
sum m#a :: lhs, n#b :: rhs =
  let lans, rans = sum lhs, rhs in
  m#(a+b) :: lans, n#b :: rans
```

这种形式下可以证明内存被正确地使用。

还有一种思路是因为如果将 Vect 视为 Monad，其构造函数将不复存在，因此只需要对其 map 规则里明确 Quantity 就可以检查内存使用。不过这样也会导致一些命题无法被证明，因为 Monad 的表现没有被建模。

考虑到真正的内存建模在于 "m" Tok，这是否意味着采用尾递归不仅对证明友好，而且由于内部使用了 "m" Tok 已经对内存和并行有建模，并不会对编译器优化造成困扰？

## 用 Dependent Pair 的形式真的合理吗？

注意到 swap 的签名 swap : m#A, n#A -> p#A, q#A 其实没有给出任何关于内存的信息。事实上应该去掉 Dependent Pair，采用这种形式：

```haskell
swap : (0 m : Tok) -> (0 n : Tok) -> m#A, n#A -> m#A, n#A
swap m#a, n#b = m#b, n#a
```

其中 m#A 只是 Loc m A，而不是 (m : Tok ** Loc m A). 这样从类型签名里面就可以看出 swap 函数不会占用新的内存。

Quantity 为 0 的 m 和 n 可以被省略掉。

## 回顾

其实 m#A 作为 Loc m A 的简写，可以看出 Loc m 应该至少是一个 Functor. 考虑到 IO 是 Monad，这些之间应该会有联系，同时 IO () 也恰巧可以用 io# -> io# 的方式来表示。这是否意味着 IO () 内部的实现可以化简成 io# -> io# 呢？还是有什么地方我没有考虑到？同时，我提倡将 Vect 看成 Monad，但 Monad 是否有机会和 Linear Type 产生效果上的同构呢？或许看看 Idris2 库里关于 IO 的实现我可以明白更多，并对理解更广泛情况的内存建模有所帮助。
