---
title: PL | 使用 Closure 建模 Vector
date: 2023-10-25 13:16:20
tags:
- 草稿
---

## 注

我本打算写成比较大众可读的形式，但我发现这很难实现，因为本篇文章想解决的问题是如何避免在函数式编程里给 Vector 开洞。在人类直觉里，大部分时候都是直接用封装好的 Vector，因此再构建一层底层实现必然不符合正常人的经验。

## Index over Fin

### 表示

```
quant data Arr T n
  index : (x : Fin n) -> Arr T n -> (T, Tok x)
```

`Arr` 是 Coinductive Type，`Tok` 是线性的 Reuse Token，均对 `Fin n` 纤维化。

`quant` 的用处是给所有参数中出现的 `Arr T n` 变成 `X Arr T n`，可以接受任意 Quantity 的参数，但会影响返回值的 Quantity。

### 例子

数组初始化：

```
arr : Arr T n
arr = make arr from
  index x arr = (0, alloc x)
```

获取元素：

```
get : Fin n -> Arr T n -> (T, Arr T n)
get i arr =
  (t, tok) = index i arr
  res = make res from
    index x res = case x of
      i => (t, tok)
      _ => index x arr
  (t, res)
```

不可变获取元素，`arr` 的重数为 0，因此 `tok` 的重数也为 0，不可以被使用。

```
get : Fin n -> 0 Arr T n -> T
get i arr =
  (t, tok) = index i arr
  t
```

修改元素：

```
mod : Fin n -> T -> Arr T n -> Arr T n
mod i val arr =
  make res from
    index x res = 
      (t, tok) = index x arr
      case x of
        i => (val, tok)
        _ => (t, tok)
```

不可以内部跨格赋值：

```
flat' : Fin n -> Arr T n -> Arr T n
flat' i arr =
  make res from
    index x res =
      (t, arr') = get i arr
      -- arr' is not used
      -- tok is not in context
```

如有此类需求，请提前获取需要的值：

```
flat : Fin n -> Arr T n -> Arr T n
flat i arr =
  (t, arr') = get i arr
  make res from
    index x res =
      (_, tok) = index x arr'
      (t, tok)
```

元素并行地变成两倍：

```
double : Arr Int n -> Arr Int n
double arr =
  make res from
    index x res = 
      (num, tok) = index x arr
      (num * 2, tok)
```

前缀和：

```
prefixSum : Arr Int n -> Arr Int n
prefixSum arr =
  fold [0..n-1] ([0 for n], 0)
    ((sums, sum), idx) =>
      sum = sum + get idx arr
      (mod idx sum sums, sum)
```

### 语法糖

元素并行地变成两倍，这里 `(T, Tok x)` 可以直接被当作 `T` 运算。

```
double : Int * n -> Int * n
double nums =
  make res from
    res[i] = nums[i] * 2
```

## Index Tok 的依据不够好！

数组选段：

```
sub : Arr Int n -> (x : Fin n) -> (y : Fin n) -> Arr Int (y - x)
sub arr x y =
  make res from
    index i res = index (i + x) arr  -- type of Tok is not consistent!
```

数组交换：

```
-- this should be invalid!
swap : Arr T n -> Arr T n -> (Arr T n, Arr T n)
swap a b =
  a' = make a' from
    index i a' =
      if isEven i
      then index i b
      else index i a
  b' = make b' from
    index i b' =
      if isEven i
      then index i a
      else index i b
  (a', b')
```

归并排序：

```
sort : Arr Int n -> Arr Int n
sort = -- not know how to implement!
```

### 基座

```
quant data Arr T n base
  index : (x : Fin n) -> Arr T n base -> (T, Tok x base)
  tok : Tok base
```

阴间起来了！

### 类比

对于正常的 inductive type，如果要用 reuse token，会变成：

```
data Pair
  Pair : Tok -> T -> T -> Pair
```

如果变成 coinductive type，就会变成：

```
data Pair
  tok : Pair -> Tok
  lhs : Pair -> T
  rhs : Pair -> T
```

其中 `tok` 是线性的。这意味着 `tok` 并不是每个参数的返回值，而是整体作为一个「容器」。

但这也引出了一个问题：对于参数数量确定的 inductive type，设其占用内存为 $k$，在自赋值的时候则需要申请额外 $O(k)$ 的内存。对于数组，则需要申请额外 $O(n)$ 的内存，这直接相当于滚动数组。换言之，reuse token 无法表达数组的「局部可并行原理」。

不可否认的都是，这种滚动数组非常符合人类心智模型，所以这一性质是需要保留的。这意味着我们同时需要一个「滚动数组」式修改方案和一个点对点式修改方案。

### DT 技巧

```
data Vec
  Vec : (n : Nat) -> Chain n T Vec
                     // T -> ... -> T -> Vec
```

这个对 inductive type 的扩展等效于我先前对 coinductive type 的扩展。

### 人思维方式和机器的区别

人只能尝试去想象「底层数据的排布」，但会自然地给想象的排布加上抽象。

最直观的例子，比如人类想一个 $n \cdot n$ 的置零数组，复杂度并不是 $O(n^2)$ 的，但对机器来说是。人存储的实际数据结构并不是其所表示的东西。

也就是说，对于人所认为直观的「数据排布」，理想状态下机器不应该存这些数据排布，而是表示这些数据排布的数据。但这通常需要神经网络的支持，人和目前计算机的运算方式也有很大的区别。这说明了进行针对机器优化的必要性，比如对于自赋值值不变的数组，不为此申请多余的内存。

这也说明了在心智模型上，我们可以只使用「滚动数组」……

但真的是这样吗？

### 可分性

可分性，即我们可以把数组分成多个**连续的**片段，然后分别处理每一个片段。其中对于每一个片段的处理，应该是可以并行化的，在图示里也是平行的。

不过考虑只对数组使用「单个依值地固定大小的 Reuse Token」，可以实现「滚动数组」式的数组切分。这时候再加个 Ad Hoc 的「如果 index 没变就不申请新内存」的优化即可。

需要额外增加分裂、合并 Token 的操作。

## 进化

归并排序：

```
sort : Arr Int n -> Arr Int n
sort arr =
  lenL = n / 2
  (tokL, tokR) = split tok lenL
  left = make left from
    index i left = index i arr
    tok left = tokL
  right = make right from
    -- binding ad hoc in-place optimization with
    -- special operators is probably better
    index i right = index (i + lenL) arr
    tok right = tokR
  left = sort left
  right = sort right
  tok = merge tokL tokR
  arr = make arr from
    index i arr =
      if i >= lenL
      then index (i - lenL) right
      else index i left
    tok arr = tok
  -- simple merging...
```

## 后续

我打算先学习 [Levity Polymorphism](https://downloads.haskell.org/~ghc/9.2.1-alpha1/docs/html/users_guide/exts/levity_polymorphism.html)，以及[这项工程](https://github.com/AndrasKovacs/staged)。
