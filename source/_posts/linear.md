---
title: PL | 什么时候使用线性类型？
date: 2023-10-04 11:38:02
tags:
- 草稿
---

## 数组和 ADT 的区别

如果在函数式语言中加入基于编号的数组，则该数组的实例显然是线性的。

非递归的 ADT（代数数据类型）可以在寄存器中被传递（此外对于元组，编译器还能跟踪每个变量的使用情况，尽可能避免申请额外的寄存器内存），只有递归的 ADT 需要放在堆中。注意到使用 Recursion Schemes 后递归的 ADT 必须通过组合子创建，这是否意味着可以和组合子联动？

注意到 Koka 使用 reuse credit 来对应一块内存[^1]，因此 Koka 需要形成对 reallocation 的顺序的假设。这和对数组的处理方式不同，在数组中我们直接使用 Lens 来修改。具体地，例如对于链表反转函数，我们用数组的思路可以写成：

```
reverseAcc xs acc =
  case xs of
    ls@(x :: xx) => reverseAcc xx (ls.tail <- acc)
    nil => acc
```

但用 reuse credit 的思路则写成：

```
reverseAcc xs acc =
  case xs  of
    x :: xx => reverseAcc xx (x :: acc)
    nil => acc
```

reuse credit 的思路更符合传统函数式编程的思路，且允许更自由的操作（例如就地修改为一个类型不同但大小相同的数据结构，即使内部数据结构不一样也没问题）。私以为这种 reuse credit 的思路更本质一些，但依然有探索空间，例如：

- 能否令 reuse credit 融入整个 FP 的框架，甚至只写成一个扩展包的形式？允许用户自己手搓 reuse credit
  - 这样的话理论上也可以解决「假设顺序」的问题
  - 把 reuse credit 整成 effect 感觉理论上可行，和 Idris2[^3] 的思路也比较接近，`Store` 中 `connect` 实质上是接受了一个 `%World`（性质和 reuse credit 类似），返回一个 `MkStore`，并自动成为线性的。如果要求 `Store` 的构造函数接受一个 `%World`，则可以反映真实内存中存在的东西
- 上述融入方式能否和 Recursion Schemes[^2] 结合？具体怎么结合还得看 Recursion Schemes 才知道

## 就地遍历

正常而言，`map` 一个二叉树的代码是：

```
map t f =
  case t of
    bin l r => bin (map l f) (map r f)
    tip x => tip (f x)
```

但该函数不是尾递归的。考虑另一种利用 `zipper` 的方式：

```
down t f ctx =
  case t of
    bin l r => down l f (binL ctx r)
    tip x => app (tip (f x)) f ctx

app t f ctx =
  case ctx of
    top => t
    binR l up => app (bin l t) f up
    binL up r => down r f (binR t up)

map t f =
  down t f top
```

这种方式中，我们只会在二叉树中一格一格移动，不需要申请额外的栈空间。

事实上，构造出这种互递归函数有通用的方法。注意到若对原本的 `map` 进行 CPS 变换，我们将得到：

```
map t f cont =
  case t of
    bin l r => map l f (l' =>
      map r f (r' =>
        cont (bin l' r')))
    tip x => cont (tip (f x))
```

可以看到经过 CPS 变换的 `map` 和 `down` 对应。而不同 `cont` 和 `ctx` 的对应是：

- `l' => map r f cont'` 对应 `down r f ctx'`，其中 `cont'` 对应 `ctx'`
- `r' => cont' (bin l' r')` 对应 `app (bin l' t) f ctx'`，其中 `cont'` 对应 `ctx'`
  - `t` 是上次处理函数的返回值，故对应 `cont` 函数的参数 `r'`
  - `cont'` 的 Application 需要写成显式，正如 `f x` 写成 `app f x`
- `x => x` 对应 `t`

因此对于任意 ADT，我们可以先用 Recursion Schemes 生成其 `map` 函数，然后对 `map` 做 CPS 变换，并构造一个和 `cont` 同构的 Zipper ADT，便可以实现纯尾递归的 `map`！

对于尾递归的链表排序，似乎需要创造一个很逆天的 Zipper！有没有能利用上 ADT 的更好的思路？

同时，koka 的样例里似乎把 `(a, b)` 视作和 `a` 占用同等的 Reuse Token，这很混乱邪恶，但又似乎神秘地让事情工作！有没有更符合直觉的解读方式或备选理论？

## 有待了解的东西

- [x] Recursion Schemes
- [x] freer monad 及相关东西，查找已有自动生成 fold / bind 的实践
- [ ] FP 处理 indexed array 的最佳实践
- [x] pointer-tagging，其实就是 `Either Tag Pointer`
- [x] pointer-reversal，其实就是遍历到一个东西之后把指针往回指

[^1]:https://www.microsoft.com/en-us/research/publication/fp2-fully-in-place-functional-programming/
[^2]:https://link.springer.com/chapter/10.1007/3540543961_7
[^3]:https://www.type-driven.org.uk/edwinb/papers/idris2.pdf
