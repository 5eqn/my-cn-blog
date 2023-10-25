---
title: PL | 使用 Closure 建模 Vector
date: 2023-10-25 13:16:20
tags:
- 草稿
---

## 注

我本打算写成比较大众可读的形式，但我发现这很难实现，因为本篇文章想解决的问题是如何避免在函数式编程里给 Vector 开洞。在人类直觉里，大部分时候都是直接用封装好的 Vector，因此再构建一层底层实现必然不符合正常人的经验。

## 表示

```
quant data Arr T n
  index : (x : Fin n) -> Arr T n -> (T, Tok x)
```

`Arr` 是 Coinductive Type，`Tok` 是线性的 Reuse Token，均对 `Fin n` 纤维化。

`quant` 的用处是给所有参数中出现的 `Arr T n` 变成 `X Arr T n`，可以接受任意 Quantity 的参数，但会影响返回值的 Quantity。

## 例子

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

### Index Tok 的依据不够好！

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

## 语法糖

元素并行地变成两倍，这里 `(T, Tok x)` 可以直接被当作 `T` 运算。

```
double : Int * n -> Int * n
double nums =
  make res from
    res[i] = nums[i] * 2
```
