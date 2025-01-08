---
title: FStar 官方习题 Case Study - Quicksort
date: 2023-01-20 23:12:33
tags:
- 编程
- PL
---

## 概要

这一小节讲述了如何用 `F*` 实现快排算法，并且证明其确实有排序的功能。

## 铺垫：快排实现

递归计算 `list` 长度：

```fstar
let rec length #a (l:list a)
  : nat
  = match l with
    | [] -> 0
    | _ :: tl -> 1 + length tl
```

递归实现将一个 `list` 与另一个 `list` 合并：

```fstar
let rec append #a (l1 l2:list a)
  : list a
  = match l1 with
    | [] -> l2
    | hd :: tl -> hd :: append tl l2
```

递归实现将列表根据大于或小于等于 `pivot` 分成两半，

注意在函数签名中指定该函数不改变列表总长，

这样在排序时可以让 SMT Prover 相信递归会结束。

```fstar
let rec partition (#a:Type) (f:a -> bool) (l:list a)
  : x:(list a & list a) { length (fst x) + length (snd x) = length l }
  = match l with
    | [] -> [], []
    | hd::tl ->
      let l1, l2 = partition f tl in
      if f hd
      then hd::l1, l2
      else l1, hd::l2
```

递归实现排序：

```fstar
let rec sort (l:list int)
  : Tot (list int) (decreases (length l))
  = match l with
    | [] -> []
    | pivot :: tl ->
      let hi, lo  = partition ((<=) pivot) tl in
      append (sort lo) (pivot :: sort hi)
```

## 习题一

### 目标

- 给定任意偏序函数，实现快排
- 证明排序后列表有序
- 证明排序后出现在原列表的元素一定出现在新的列表中
- 给出 `extrinsic` 和 `intrinsic` 两种形式的证明

### 思路

考虑递归证明，假设 `partition` 后的两个子列表均有序，

要证整体有序，我们需要将 `partition` 的意义告知 SMT Prover：

`partition` 后所有左侧元素 `x` 满足 `f pivot x`，右侧则不满足，

其中 `f` 是偏序函数。

要证原列表元素一定出现在新列表，还需要 `partition` 的另一重意义：

在 `partition` 列表参数中出现的元素，一定出现在返回值两个列表中的一个。

同时，由于涉及 `append` 操作，也需要证明 `append` 不损失元素的性质。

因此，用 `partition_mem` 证明 `partition` 和 `mem` 相关的性质，

用 `append_mem` 证明 `append` 和 `mem` 相关的性质，

`sorted_concat` 表示子序列有序，合并后也有序，

`sort_correct` 表示排序满足给定的要求。

对于 `intrinsic` 的证明，只需把需要满足的条件用提纯类型的方式表述出来，

然后在算法内部补充必要的证明即可。

由于证明的递归方式和算法的递归方式一致，不需要重复书写证明的递归方式。

### 坑

- 在每个 `sort` 及其相关的证明都需要输入偏序函数！

### 感想

`intrinsic` 的方式美丽至极！这种方式把类型论、算法、证明天衣无缝地连结在一起！

自证明的魅力真的让人为之倾倒……

这可比算法竞赛有意思多了！

### 背景

```fstar
module Part1.Quicksort.Generic

//Some auxiliary definitions to make this a standalone example
let rec length #a (l:list a)
  : nat
  = match l with
    | [] -> 0
    | _ :: tl -> 1 + length tl

let rec append #a (l1 l2:list a)
  : list a
  = match l1 with
    | [] -> l2
    | hd :: tl -> hd :: append tl l2

let total_order (#a:Type) (f: (a -> a -> bool)) =
    (forall a. f a a)                                         (* reflexivity   *)
    /\ (forall a1 a2. (f a1 a2 /\ a1=!=a2)  <==> not (f a2 a1))  (* anti-symmetry *)
    /\ (forall a1 a2 a3. f a1 a2 /\ f a2 a3 ==> f a1 a3)        (* transitivity  *)
    /\ (forall a1 a2. f a1 a2 \/ f a2 a1)                       (* totality  *)

let total_order_t (a:Type) = f:(a -> a -> bool) { total_order f }

let rec sorted #a  (f:total_order_t a) (l:list a)
  : bool
  = match l with
    | [] -> true
    | [x] -> true
    | x :: y :: xs -> f x y && sorted f (y :: xs)

let rec mem (#a:eqtype) (i:a) (l:list a)
  : bool
  = match l with
    | [] -> false
    | hd :: tl -> hd = i || mem i tl
```

### AC 代码

```fstar
 //SNIPPET_START: partition
let rec partition (#a:Type) (f:a -> bool) (l:list a)
  : x:(list a & list a) { length (fst x) + length (snd x) = length l }
  = match l with
    | [] -> [], []
    | hd::tl ->
      let l1, l2 = partition f tl in
      if f hd
      then hd::l1, l2
      else l1, hd::l2
//SNIPPET_END: partition

//SNIPPET_START: sort-impl
let rec sort #a (f:total_order_t a) (l:list a)
  : Tot (list a) (decreases (length l))
  = match l with
    | [] -> []
    | pivot :: tl ->
      let hi, lo  = partition (f pivot) tl in
      append (sort f lo) (pivot :: sort f hi)
//SNIPPET_END: sort-impl

//SNIPPET_START: partition_mem
let rec partition_mem (#a:eqtype)
                      (f:(a -> bool))
                      (l:list a)
  : Lemma (let l1, l2 = partition f l in
           (forall x. mem x l1 ==> f x) /\
           (forall x. mem x l2 ==> not (f x)) /\
           (forall x. mem x l = (mem x l1 || mem x l2)))
  = match l with
    | [] -> ()
    | hd :: tl -> partition_mem f tl
//SNIPPET_END: partition_mem

//SNIPPET_START: sorted_concat
let rec sorted_concat (#a:eqtype)
                      (f:total_order_t a)
                      (l1:list a{sorted f l1})
                      (l2:list a{sorted f l2})
                      (pivot:a)
  : Lemma (requires (forall y. mem y l1 ==> not (f pivot y)) /\
                    (forall y. mem y l2 ==> f pivot y))
          (ensures sorted f (append l1 (pivot :: l2)))
  = match l1 with
    | [] -> ()
    | hd :: tl -> sorted_concat f tl l2 pivot
//SNIPPET_END: sorted_concat

//SNIPPET_START: append_mem
let rec append_mem (#t:eqtype)
                   (l1 l2:list t)
  : Lemma (ensures (forall a. mem a (append l1 l2) = (mem a l1 || mem a l2)))
  = match l1 with
    | [] -> ()
    | hd::tl -> append_mem tl l2
//SNIPPET_END: append_mem

let rec sort_correct (#a:eqtype) (f:total_order_t a) (l:list a)
  : Lemma (ensures (
           let m = sort f l in
           sorted f m /\
           (forall i. mem i l = mem i m)))
          (decreases (length l))
  = match l with
    | [] -> ()
    | pivot :: tl ->
      let hi, lo  = partition (f pivot) tl in
      sort_correct f hi;
      sort_correct f lo;
      partition_mem (f pivot) tl;
      sorted_concat f (sort f lo) (sort f hi) pivot;
      append_mem (sort f lo) (pivot :: sort f hi)

let rec sort_intrinsic (#a:eqtype) (f:total_order_t a) (l:list a)
  : Tot (m:list a {
                sorted f m /\
                (forall i. mem i l = mem i m)
         })
   (decreases (length l))
  = match l with
    | [] -> []
    | pivot :: tl ->
      let hi, lo  = partition (fun x -> f pivot x) tl in
      partition_mem (fun x -> f pivot x) tl;
      sorted_concat f (sort_intrinsic f lo) (sort_intrinsic f hi) pivot;
      append_mem (sort_intrinsic f lo) (pivot :: sort_intrinsic f hi);
partition_mem_permutation      append (sort_intrinsic f lo) (pivot :: sort_intrinsic f hi)
```

## 习题二

### 目标

- 证明排序后任意元素出现在原列表与新列表的次数相同
- 给出 `extrinsic` 和 `intrinsic` 两种形式的证明

### 思路

考虑递归证明，上一阶段的证明结果只涉及两个子序列，但最终要证明子序列加 `pivot` 的性质。

由于 `count` 比较复杂，依照官方提示，考虑单独证明从两个子序列的性质能过渡到最终结果。

考虑到 `append` 对 `count` 具备可加性，而大部分其他函数由 `append` 构造，

因此只需要把涉及到的所有 `append` 操作的保持数量的性质进行证明即可。

官方的答案有较多多余的证明，我的答案相对精简。

### 坑

- `partition` 返回的 `hi` 和 `lo` 在不同函数参数中的预期位置不同！
  - 我花了至少一小时才找到这个问题 qwq

### 背景

```fstar
module Part1.Quicksort.Permutation

//Some auxiliary definitions to make this a standalone example
let rec length #a (l:list a)
  : nat
  = match l with
    | [] -> 0
    | _ :: tl -> 1 + length tl

let rec append #a (l1 l2:list a)
  : list a
  = match l1 with
    | [] -> l2
    | hd :: tl -> hd :: append tl l2

let total_order (#a:Type) (f: (a -> a -> bool)) =
    (forall a. f a a)                                         (* reflexivity   *)
    /\ (forall a1 a2. (f a1 a2 /\ a1=!=a2)  <==> not (f a2 a1))  (* anti-symmetry *)
    /\ (forall a1 a2 a3. f a1 a2 /\ f a2 a3 ==> f a1 a3)        (* transitivity  *)
    /\ (forall a1 a2. f a1 a2 \/ f a2 a1)                       (* totality *)
let total_order_t (a:Type) = f:(a -> a -> bool) { total_order f }

let rec sorted #a  (f:total_order_t a) (l:list a)
  : bool
  = match l with
    | [] -> true
    | [x] -> true
    | x :: y :: xs -> f x y && sorted f (y :: xs)

//SNIPPET_START: count permutation
let rec count (#a:eqtype) (x:a) (l:list a)
  : nat
  = match l with
    | hd::tl -> (if hd = x then 1 else 0) + count x tl
    | [] -> 0

let mem (#a:eqtype) (i:a) (l:list a)
  : bool
  = count i l > 0

let is_permutation (#a:eqtype) (l m:list a) =
  forall x. count x l = count x m

let rec append_count (#t:eqtype)
                     (l1 l2:list t)
  : Lemma (ensures (forall a. count a (append l1 l2) = (count a l1 + count a l2)))
  = match l1 with
    | [] -> ()
    | hd::tl -> append_count tl l2
//SNIPPET_END: count permutation
```

### AC 代码

```fstar
let rec partition (#a:Type) (f:a -> bool) (l:list a)
  : x:(list a & list a) { length (fst x) + length (snd x) = length l }
  = match l with
    | [] -> [], []
    | hd::tl ->
      let l1, l2 = partition f tl in
      if f hd
      then hd::l1, l2
      else l1, hd::l2

let rec sort #a (f:total_order_t a) (l:list a)
  : Tot (list a) (decreases (length l))
  = match l with
    | [] -> []
    | pivot :: tl ->
      let hi, lo  = partition (f pivot) tl in
      append (sort f lo) (pivot :: sort f hi)

let rec partition_mem_permutation (#a:eqtype)
                                  (f:(a -> bool))
                                  (l:list a)
  : Lemma (let l1, l2 = partition f l in
           (forall x. mem x l1 ==> f x) /\
           (forall x. mem x l2 ==> not (f x)) /\
           (is_permutation l (append l1 l2)))
  = match l with
    | [] -> ()
    | hd :: tl ->
      let l1, l2 = partition f tl in
      append_count l1 l2;
      partition_mem_permutation f tl

let rec sorted_concat (#a:eqtype)
                      (f:total_order_t a)
                      (l1:list a{sorted f l1})
                      (l2:list a{sorted f l2})
                      (pivot:a)
  : Lemma (requires (forall y. mem y l1 ==> not (f pivot y)) /\
                    (forall y. mem y l2 ==> f pivot y))
          (ensures sorted f (append l1 (pivot :: l2)))
  = match l1 with
    | [] -> ()
    | hd :: tl -> sorted_concat f tl l2 pivot

let permutation_app_lemma (#a:eqtype) (hd:a) (tl:list a)
                          (l1:list a) (l2:list a)
   : Lemma (requires (is_permutation tl (append l1 l2)))
           (ensures (is_permutation (hd::tl) (append l1 (hd::l2))))
  = append_count l1 l2;
    append_count l1 (hd::l2)

let rec sort_correct (#a:eqtype) (f:total_order_t a) (l:list a)
  : Lemma (ensures (
           sorted f (sort f l) /\
           is_permutation l (sort f l)))
          (decreases (length l))
  = match l with
    | [] -> ()
    | pivot :: tl ->
      let hi, lo  = partition (f pivot) tl in
      sort_correct f hi;
      sort_correct f lo;
      partition_mem_permutation (f pivot) tl;
      sorted_concat f (sort f lo) (sort f hi) pivot;
      append_count hi lo;
      permutation_app_lemma pivot tl (sort f hi) (sort f lo)

let rec sort_intrinsic (#a:eqtype) (f:total_order_t a) (l:list a)
  : Tot (m:list a {
                sorted f m /\
                is_permutation l m
         })
   (decreases (length l))
  = match l with
    | [] -> []
    | pivot :: tl ->
      let hi, lo  = partition (fun x -> f pivot x) tl in
      partition_mem_permutation (fun x -> f pivot x) tl;
      sorted_concat f (sort_intrinsic f lo) (sort_intrinsic f hi) pivot;
      append_count hi lo;
      permutation_app_lemma pivot tl (sort f hi) (sort f lo);
      append (sort_intrinsic f lo) (pivot :: sort_intrinsic f hi)
```
