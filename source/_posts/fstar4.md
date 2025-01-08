---
title: FStar 官方习题 Pt.4 Equality Types
date: 2023-01-22 15:12:40
tags:
- 编程
- PL
---

可参考 [官网](http://fstar-lang.org/tutorial/book/part2/part2_equality.html#exercise)

## 内容

讲述了不同的等价关系，例如

- 定义相等
  - 由于采用 Inductive Type 机制，原先表现形式不同的表达式经过自动化简后程序无法区分
  - 例
    - `(fun x -> x) a` 和 `a`
    - `(factorial 3)` 和 `6`
- 证明相等
  - 使用 `equal a b` 这个类型代表 `a == b` 的命题
  - 用 `Reflexivity x` 构造 `equal x x` 的实例
    - 所有 `equal a b` 的实例定义相等
- 布尔相等
  - 仅针对 `eqtype`，例如 `int`, `bool` 等
  - 用 `a = b` 表示，和非依值类型语言的 `a == b` 等价

## 习题一：莱布尼兹等价关系

### 概要

定义莱布尼兹等价关系为

```fstar
let lbz_eq (#a:Type) (x y:a) = p:(a -> Type) -> p x -> p y
```

证明其是等价关系，并且 `lbz_eq a b` 是 `equal a b` 的充要条件。

### 思路

等价关系包括

- 自反性
- 传递性
- 对称性

考虑到 `lbz_eq` 是函数，对这些性质的证明也应当是匿名函数。

```fstar
let lbz_eq_refl #a (x:a)
  : lbz_eq x x
  = fun p h -> h
let lbz_eq_trans #a (x y z:a) (pf1:lbz_eq x y) (pf2:lbz_eq y z)
  : lbz_eq x z
  = fun p h -> pf2 p (pf1 p h)
```

对于对称性，如果只考虑对于一个命题，则 `p y` 推不出 `p x`，因此想办法构造其他命题。

~~考虑构造匿名函数，输入 `x` 返回 `p y`，输入 `y` 返回 `p x`，就可以构造出 `p x`。~~

由于 `x` 和 `y` 不能比较，因此不能采用上面的方法。

然而，由于 `p` 可以构造出任何命题，考虑构造函数。

我们已有 `p y` 和 `p x -> p x` 的实例，

那么我们只要构造出 `p y -> p x` 的实例即可。

```fstar
let lbz_eq_sym #a (x y:a) (pf:lbz_eq x y)
  : lbz_eq y x
  = fun p h -> pf (fun z -> (p z -> p x)) (fun z -> z) h
```

后面的证明采用类似的思路即可。

```fstar
let equals_lbz_eq (#a:Type) (x y:a) (pf:equals x y)
  : lbz_eq x y
  = fun p h -> h
let lbz_eq_equals (#a:Type) (x y:a) (pf:lbz_eq x y)
  : equals x y
  = pf (fun z -> (equals x z)) Reflexivity
```

在 Web 编辑器，似乎 `Reflexivity` 关键字不存在，大概是某种 bug.
