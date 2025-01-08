---
title: 同伦类型论学习笔记
date: 2023-06-28 17:28:45
tags:
- 数学
---

近期有大量企业参观活动，使用同伦类型论来消磨时间是极好的。

## 和常规类型论的不同

同伦类型论为类型添加了拓扑意义：类型是一个空间，而其实例是这个空间中的点，其实例之间的「相等关系」是两个实例之间的「路径」，将构造出了两个实例之间的「路径」视为它们在「同伦意义上」相等。

遵循依值类型论传统，每个类型对应一个「构造方式」和「析构方式」。构造方式描述这个类型的实例可以被如何构造出来，析构方式描述这个类型的实例可以如何被「归纳」或者「模式匹配」，注意这两种方式是同构的，是理解同伦类型论的重难点，我会在后面进行具体解释。

## 归纳和模式匹配的同构性

例如我想要实现一个函数：

```haskell
f : (n : Nat) -> C n
```

但我只实现了：

```haskell
cz : C Z
cs : (n : Nat) -> C n -> C (S n)
```

在类型论中，最初的规定是可以使用下面的 defining equations 来构造出 f 的实例，注意这只是一种「规定」：

```haskell
f Z = cz
f (S n) = cs n (f n)
```

注意这里我们强行承认 f 的这两种参数涵盖了「所有的」可能性，在这两种情况下经过简单的类型计算就能知道 f 是 well-typed 的。这和 pattern match 的语法非常相似：

```haskell
f : (n : Nat) -> C n
f = case n of
  Z => cz
  S m => cs m (f m)
```

这里可以发现 case 分支里面的东西也不完全是目标类型，在我的类型检查实现里面是把 C n 替换成 C Z 或者 C (S n)，但实际上这只是一种对所有 Inductive Types 成立的一个规定。

同时，defining equations 的写法也可以转换成 ind 函数的写法：

```haskell
ind : (C : Nat -> Type) -> C Z -> ((n : Nat) -> C n -> C (S n)) -> ((n : Nat) -> C n)
ind C cz cs n = case n of
  Z => cz
  S m => cs m (ind C cz cs m)
```

可以看出 ind 只是把 C, cz 和 cs 带着而已。

## Identity Type 的构造和析构规则

由于 identity type 的唯一构造方式是使用 refl : (a : A) -> a = a, 我之前认为在传统依值类型论里面，如果有一个 p : a = a 可以直接析构出 refl a, 但看了下 Lean 的文档我发现这或许是错误的，因为 Lean 对 identity type 的析构进行了一层封装：

```ocaml
example (α : Type) (a b : α) (p : α → Prop)
        (h1 : a = b) (h2 : p a) : p b :=
  Eq.subst h1 h2
```

然后再进行一层封装：

```ocaml
variable (a b c d e : Nat)
variable (h1 : a = b)
variable (h2 : b = c + 1)
variable (h3 : c = d)
variable (h4 : e = 1 + d)

theorem T : a = e :=
  calc
    a = b      := h1
    _ = c + 1  := h2
    _ = d + 1  := congrArg Nat.succ h3
    _ = 1 + d  := Nat.add_comm d 1
    _ = e      := Eq.symm h4
```

导致不太看得出 pattern match 的痕迹。实际上，identity type 的析构和前面用于举例的自然数析构本质上没有不同，都可以写成 defining equation, pattern match 和 ind 这三种同构的形式，但其规则并不符合传统的 pattern match.

Identity type 的析构有两种可以互相推导的形式，这里以 path induction 为例。若要构造出下面 f 的实例：

```haskell
f : (x : A) -> (y : A) -> (p : x = y) -> C x y p
```

但我们只有：

```haskell
c : (x : A) -> C x x (refl x)
```

我们可以强行这样构造出 f 的实例：

```haskell
f x x (refl x) = c x
```

注意我们只考虑了 x y p 符合 x x (refl x) 形式的情况，别的情况被强行忽略了，而在这种情况 f 也是 well-typed 的。

若要写成 pattern matching 的格式，则是：

```haskell
f : (x : A) -> (y : A) -> (p : x = y) -> C x y p
f x y p = case (x ** (y ** p)) of
  (u ** (u ** refl u)) => c u
```

注意 (a ** b) 是 dependent pair，即 Sigma type.

若要写成 ind 函数的格式，则是：

```haskell
ind : (C : (x : A) -> (y : A) -> x = y -> Type) -> ((x : A) -> C x x (refl x)) -> (x : A) -> (y : A) -> C x y p
ind C c x x (refl x) = c x
```

可以看出非常明显的同构性。

注意这里 case 里面的 x 和 y 必须是不同的变量，如果是同一个变量，在拓扑学意义上这是一个「两端固定」的路径，不一定能收缩到一个点，这应当和 Lean 里面的情况是一致的，只是 HoTT 找到了这种关联性，暂时没有发现对原有类型论有什么规则上的修改，只有理念上的不同。或许后续涉及一些 univalence axiom 的时候我能够看到修改，也可能只是一个在原有类型论基础上的「洞见」，从而在原先类型论中已经可能的范围内进行实践的调整。
