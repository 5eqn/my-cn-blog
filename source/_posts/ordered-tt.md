---
title: PL | 使用顺序类型系统建模 Vector
date: 2023-10-27 09:46:20
tags:
- 草稿
---

## 目标

使用一种尽可能不 ad hoc 的方法建模 Vector。根据「奥卡姆剃刀原则」，这能更本质地把握「Vector 实质上是什么」，从而得到对人类相关直觉更简洁、直观的表述方法。

当前所有研究内容只是「将算法直观化」的基建，真正要直观化还需要一种好的可视化手段，因此本文暂不考虑做通俗化表述。

## 启发式推导

考虑大家都熟悉的 `List`：

```
data List T
  Nil : List T
  Cons : T -> List T -> List T
```

使用 Reuse Token，其中 `Tok` 的所有出现均为 Quantitive 的：

```
data List T
  Nil : List T
  Cons : Tok -> T -> List T -> List T
```

考虑移除元素（这里省略 effect）：

```
remove : T -> List T -> List T
remove t ls =
  case ls of
    Nil => Nil
    Cons tok t tl => free tok; remove t tl
    Cons tok hd tl => Cons tok hd (remove t tl)
```

移除元素会导致无法线性索引，我们希望我们的类型系统能禁止实现这个函数。

考虑禁用对 `List` 的 `Tok` 执行 `free`，这样基于仿射类型只有整个 `List T` 的实例能被回收，只要拆开之后都必然需要拼接上。这样 `Tok` 和 `Cons` 都可以视为和 `Nat` 相似的，因此可以采用和 `Nat` 类似的优化方法，从而实现随机访问。

不过，这样的类型系统可以被破解：

```
swap : List T -> List T -> (List T, List T)
swap ls ls' =
  case (ls, ls') of
    (Cons tok hd tl, Cons tok' hd' tl') => (Cons tok hd tl', Cons tok' hd' tl)
    _ => (ls, ls')
```

我们只希望用户拿到一个 `Cons tok hd tl` 之后改变 `hd`、对 `tl` 进行一个原位、保持位置的操作之后装回去，但现在用户可以随意改变 `tl`（因为在这样的语义下 `tl` 的表现更像是一个指针）。事实上 `tok` 和 `tl` 都本应只表示一个运行时擦除的 Index。

参考 [Ordered Type Theory](https://www.cs.cmu.edu/~rwh/papers/ordered/popl.pdf)，考虑在语境中添加「顺序」。具体地，原先在给 `ls` 解构出 `Cons tok hd tl` 的时候，语境中只有线性的 `tok` 和 `tl`。现在，我们希望强制要求 `tok` 和 `tl` 必须在一个相同的构造函数中被以相同顺序应用。

不过由于内存只能是线性的，这个限制不能被推广到其他数据结构，例如树（除非我们现实中有树状的内存）。这意味着目前而言这一限制只能被应用于数组。因此考虑把这一规则直接施加在一个 built-in 的数组类型上。

### 对应

为方便和现实内存对应，考虑把 `hd` 写到后面。虽然这样写应该叫 `init` 和 `last`，但看起来很怪，所以还是 `Cons tl hd` 罢。

## 例子

归并排序，这里 `[A, B]` 表示有序对，在参数被解构时要求以相同顺序被塞回去。

```
cut : List T -> Nat -> [List T, List T]
cut ls n =
  case (ls, n) of
    (ls, Z) => [Nil, ls]
    (Cons tl hd, S m) =>
      [lhs, rhs] = cut tl m
      [lhs, Cons rhs hd]

sort : List T -> List T
sort ls =
  [lhs, rhs] = cur ls (len ls / 2)
  lhs = sort lhs
  rhs = sort rhs
  -- merge...
```

`cut` 要优化成直接索引较为困难，暂时只知道可以参考对 `Nat` 的优化方式，但不知道具体怎么做。对 `Nat` 的优化和避免为不可变 `List` 申请内存的优化或许有相似之处，这些都是以后可调研的课题。

同时相比令 `Cons : List T -> Tok -> T -> List T`，改为 `Cons : List T -> (Tok T, T) -> List T` 或许更好一些，这样可以直观地看出每个变量都是线性且有序的，只是对多层 Pattern Match 的需求变强了（但这反正本来也要做）。
