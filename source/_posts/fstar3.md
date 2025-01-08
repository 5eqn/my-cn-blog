---
title: FStar 官方习题 Pt.3 Length-indexed Lists
date: 2023-01-21 11:40:46
tags:
- 编程
- PL
---

可参考 [官网](http://fstar-lang.org/tutorial/book/part2/part2_vectors.html#length-indexed-lists)。

## 内容

可以将类型的一些属性作为类型的编号，这样在递归定义类型时就可以将属性直接计算出来。

例如，以下是定长数组的定义：

```fstar
type vec (a:Type) : nat -> Type =
  | Nil : vec a 0
  | Cons : #n:nat -> hd:a -> tl:vec a n -> vec a (n + 1)
```

规定只能用长度为 `n` 的定长数组构造出长度为 `n + 1` 的定长数组，

因此长度可以直接依据类型定义计算出来。

个人理解编号本质上也是一种类型参数。

## 习题一：合并定长数组

### 思路

由于隐式参数的大小关系可以被 SMT Prover 自动证明，

只需要提供递归方式即可。

考虑到 `vec` 的定义方式，只能在数组的左侧一个一个添加元素，

考虑将 `append v1 v2` 拆分成 `Cons hd (append tl v2)`。

### AC 代码

```fstar
let rec append #a #n #m (v1:vec a n) (v2:vec a m)
  : vec a (n + m)
  = match v1 with
    | Nil -> v2
    | Cons hd tl -> Cons hd (append tl v2)
```

## 习题二：分裂定长数组

### 思路

考虑到 `get i v = get (i - 1) tl`，递归时应当对 `i` 和 `v` 同时递归，

注意终止条件是 `i = 0`。

### AC 代码

```fstar
let rec split_at #a #n (v:vec a n) (i:nat { i <= n })
  : vec a i & vec a (n - i)
  = match i with
    | 0 -> Nil, v
    | _ -> let Cons hd tl = v in
           let l, r = split_at tl (i - 1) in
           Cons hd l, r
```

## 补充

后面还有尾递归的习题以及等价性证明，不过由于我不知道尾递归指什么，所以不做了。
