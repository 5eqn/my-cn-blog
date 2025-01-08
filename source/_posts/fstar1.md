---
title: FStar 官方教程习题 Pt. 1
date: 2023-01-20 19:17:24
tags:
- 编程
- PL
---

## FStar 是什么？

`F*` 是一种面向证明的编程语言，运用大量奇技淫巧实现程序自证明，例如：

- 依值类型，Dependent Type，简而言之就是允许类型依赖于具体的值
- 函数式编程，Functional Programming，函数是一等公民，能像值一样作为参数和返回值
- 元语言，Meta Language，模糊程序与数据的边界，允许程序生成程序
- 提纯类型（瞎翻），Refinement Type，给已存在的类型加上限制，获得新的类型

推荐从 [官网](https://fstar-lang.org/) 了解 `F*`。

## FStar 练习：Part 1, Lemmas and proofs by induction

证明递归实现的阶乘在 $x > 2$ 时满足 $x! > x$。

只需要提示 Z3 SMT 证明器如何进行递归，它可以自动完成剩下的证明。

```ocaml
let rec factorial (n:nat)
  : nat
  = if n = 0 then 1
    else n * factorial (n - 1)

let rec factorial_is_greater_than_arg (x:int)
  : Lemma (requires x > 2)
          (ensures factorial x > x)
  = if x = 3 then ()
    else factorial_is_greater_than_arg (x - 1)
```

证明斐波那契数列在 $n \ge 2$ 时满足 $f(n) \ge n$。

这里偷了点懒，本来要递归到 $n - 1$ 和 $n - 2$，

但是只提示到 $n - 1$ 已经足以让 SMT 完成证明。

```ocaml
let rec fibonacci (n:nat)
  : nat
  = if n <= 1
    then 1
    else fibonacci (n - 1) + fibonacci (n - 2)

val fibonacci_greater_than_arg (n:nat{n >= 2})
  : Lemma (fibonacci n >= n)
let rec fibonacci_greater_than_arg n
  = if n = 2 then ()
    else fibonacci_greater_than_arg (n - 1)
```

证明一个用于合并列表的函数的返回值长度为参数之和。

对列表进行递归即可。

```ocaml
let rec app #a (l1 l2:list a)
  : list a
  = match l1 with
    | [] -> l2
    | hd :: tl -> hd :: app tl l2

let rec length #a (l:list a)
  : nat
  = match l with
    | [] -> 0
    | _ :: tl -> 1 + length tl

val app_length (#a:Type) (l1 l2:list a)
  : Lemma (length (app l1 l2) = length l1 + length l2)
let rec app_length l1 l2
  = match l1 with
    | [] -> ()
    | _ :: tl -> app_length tl l2
```

证明两个列表如果反转后相同，原先也相同。

这里采用了官方答案，直接用教程中出现的对反转操作可逆的证明，来证明反转操作是单射。

```ocaml
let rec append (#a:Type) (l1 l2:list a)
  : list a
  = match l1 with
    | [] -> l2
    | hd::tl -> hd :: append tl l2

let rec reverse #a (l:list a)
  : list a
  = match l with
    | [] -> []
    | hd :: tl -> append (reverse tl) [hd]

(* snoc is "cons" backwards --- it adds an element to the end of a list *)
let snoc l h = append l [h]

let rec snoc_cons #a (l:list a) (h:a)
  : Lemma (reverse (snoc l h) == h :: reverse l)
  = match l with
    | [] -> ()
    | hd :: tl -> snoc_cons tl h

let rec rev_involutive #a (l:list a)
  : Lemma (reverse (reverse l) == l)
  = match l with
    | [] -> ()
    | hd :: tl ->
      // (1) [reverse (reverse tl) == tl]
      rev_involutive tl;
      // (2) [reverse (append (reverse tl) [hd]) == h :: reverse (reverse tl)]
      snoc_cons (reverse tl) hd
      // These two facts are enough for Z3 to prove the lemma:
      //   reverse (reverse (hd :: tl))
      //   =def= reverse (append (reverse tl) [hd])
      //   =(2)= hd :: reverse (reverse tl)
      //   =(1)= hd :: tl
      //   =def= l

let rev_injective_alt (#a:Type) (l1 l2:list a)
  : Lemma (requires reverse l1 == reverse l2)
          (ensures  l1 == l2)
  = rev_involutive l1; rev_involutive l2
```

证明优化后的线性复杂度反转函数和原先的平方复杂度反转函数一致。

这个优化的原理是让反转函数接受两个参数，从而只需要对 `l2` 进行递归，

每次递归后直接把答案放到 `l1` 参数里。

本题官方的解答用到了最后压轴题定义的函数，我尝试写了另外一种方法：

尝试找到 `rev`、`reverse` 和递归的一些性质：

- `rev_aux` 递归时 `l1` 和 `l2` 的总长保持不变
- `rev_aux` 会被拆成 `rev_aux (hd :: []) tl` 的形式
- `reverse` 会被拆成 `append (reverse tl) [hd]` 的形式
- 直接对 `l` 递归，则 `reverse tl` 等于 `rev_aux [] tl`

根据递归规则，找到关键命题 `rev_aux (hd :: []) tl == append (rev_aux [] tl) [hd]`

考虑 `rev_aux` 的递归规律，对 `tl` 和 `[]` 一减一增递归，抽象成 `l2` 和 `l1`。

注意明确 `l2` 的递减标识，便于 SMT 确认该递归函数会终止。

```ocaml
let rec rev_aux #a (l1 l2:list a)
  : Tot (list a) (decreases l2)
  = match l2 with
    | []     -> l1
    | hd :: tl -> rev_aux (hd :: l1) tl

let rev #a (l:list a) : list a = rev_aux [] l

let rec rev_step_snoc #a (l1 l2:list a) (h:a)
  : Lemma (ensures rev_aux (append l1 [h]) l2 ==
                   append (rev_aux l1 l2) [h])
          (decreases l2)
  = match l1, l2 with
    | _, h2 :: t2 ->
      rev_step_snoc (h2 :: l1) t2 h
    | _ -> ()

val rev_is_ok (#a:_) (l:list a)
  : Lemma (rev l == reverse l)
let rec rev_is_ok l
  = match l with
    | [] -> ()
    | hd :: tl ->
      rev_step_snoc [] tl hd;
      rev_is_ok tl
```

证明优化后的线性求斐波那契数列函数与原先的指数复杂度函数一致。

由于 `fib_aux` 使用了三个参数，确认参数的变化规律后证明关键命题（这里是递推关系）即可。

```ocaml
let rec fib_aux (a b n:nat)
  : Tot nat (decreases n)
  = match n with
    | 0 -> a
    | _ -> fib_aux b (a+b) (n-1)

let fib (n:nat) : nat = fib_aux 1 1 n

let rec fib_step_aux (a b:nat) (n:nat{n>1})
  : Lemma (ensures fib_aux a b (n - 2) + fib_aux a b (n - 1) ==
                   fib_aux a b n)
          (decreases n)
  = match n with
    | 2 -> ()
    | _ -> fib_step_aux b (a + b) (n - 1)

let rec fib_is_ok (n:nat)
  : Lemma (fibonacci n == fib n)
  = match n with
    | 0 -> ()
    | 1 -> ()
    | _ ->
      fib_step_aux 1 1 n;
      fib_is_ok (n - 1);
      fib_is_ok (n - 2)
```

为查找函数找到隐式提纯类别和显式性质证明。

隐式需要使用到 `o:option`，在前文没看到，我直接看了答案。

```ocaml
//write a type for find
val find (#a:Type) (f:a -> bool) (l:list a)
  : o:option a{Some? o ==> f (Some?.v o)}
let rec find f l =
  match l with
  | [] -> None
  | hd :: tl -> if f hd then Some hd else find f tl
```

显式的默认在记事本里面已经给出了，注意 `Lemma` 里面也可以 `match` 即可，

剩下的是简单的递归。

```ocaml
let rec find_alt f l =
  match l with
  | [] -> None
  | hd :: tl -> if f hd then Some hd else find_alt f tl

let rec find_alt_ok #a (f:a -> bool) (l:list a)
  : Lemma (match find_alt f l with
           | Some x -> f x
           | _ -> true)
  = match l with
    | [] -> ()
    | _ :: tl -> find_alt_ok f tl
```

证明左折叠 `Cons` 等效于 `reverse`。

这和先前的 `rev_aux` 特别相似，

这里我尝试采用答案思路完成，不过未遂。最后参考答案才做出来。

关键依然在于 `fold_left` 的递归方式，在此基础上把同构的 `fold_left` 替换为 `reverse`。

替换成 `reverse` 后就成为了统一的 `append` 格式，可以利用结合律等自然的规律处理。

不过由于和保持一定的是返回值，相比前面的 `rev_aux` 更难看出规律。

我一度想尝试采用一元递归完成证明，不过失败了。

```ocaml
let rec fold_left #a #b (f: b -> a -> a) (l: list b) (acc:a)
  : a
  = match l with
    | [] -> acc
    | hd :: tl -> fold_left f tl (f hd acc)

let rec append_assoc (#a:Type) (l1 l2 l3:list a)
  : Lemma (append (append l1 l2) l3 == append l1 (append l2 l3))
  = match l1 with
    | [] -> ()
    | hd :: tl -> append_assoc tl l2 l3

let rec fold_generic (#a:Type) (l1 l2:list a)
  : Lemma (fold_left Cons l1 l2 == append (reverse l1) l2)
  = match l1 with
    | [] -> ()
    | hd :: tl ->
      append_assoc (reverse tl) [hd] l2;
      fold_generic tl (hd :: l2)

let rec append_right_unit (#a:Type) (l:list a)
  : Lemma (append l [] == l)
  = match l with
    | [] -> ()
    | hd :: tl -> append_right_unit tl

let fold_left_Cons_is_rev (#a:Type) (l:list a)
  : Lemma (fold_left Cons l [] == reverse l)
  = fold_generic l [];
    append_right_unit (reverse l)
```
