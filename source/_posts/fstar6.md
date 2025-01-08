---
title: FStar 官方习题 A First Model of Computational Effects
date: 2023-01-23 22:02:36
tags:
- 编程
- PL
---

[官网](http://fstar-lang.org/tutorial/book/part2/part2_par.html#a-first-model-of-computational-effects)

## 写在前面

`F*` 目前只在 `Emacs` 有功能全面的编辑器插件，

但可惜本人太菜，只会用 `Vim`，因此只能在线写码。

## State Monad

可以理解为封装后的计算，接受初始状态，返回计算结果和后状态。

```fstar
let st a = int -> a & int
```

`read` 是一个计算，不改变状态，返回的结果是状态本身。

```fstar
let read
  : st int
  = fun s -> s, s
```

`write` 是一个计算，忽略原先的状态，接受一个参数 `s0` 并直接把状态修改成 `s0`，无计算结果。

```fstar
let write (s1:int)
  : st unit
  = fun _ -> (), s1
```

`bind` 接受两个计算 `f` 和 `g`，但是 `g` 额外接受 `f` 的计算结果，

最终体现的效果是输入初始状态，直接获得先执行 `f` 后执行 `g` 的最终状态，

以及 `g` 的计算结果。

```fstar
let bind #a #b
         (f: st a)
         (g: a -> st b)
  : st b
  = fun s0 ->
      let x, s1 = f s0 in
      g x s1
```

`return` 不改变状态，接受一个参数 `x`，计算结果直接是 `x`.

```fstar
let return #a (x:a)
  : st a
  = fun s -> x, s
```

使用这种风格构造出自增计算：

```fstar
let read_and_increment_v1 : st int =
  bind read (fun x ->
  bind (write (x + 1)) (fun _ ->
  return x))
```

把 `bind` 转变成神秘的语法糖：

```fstar
let read_and_increment : st int =
  x <-- read;
  write (x + 1);;
  return x
```

## 习题

```fstar
// 先前 st 的状态一直是 int
// 现在需要给出对任意类型状态的 st 的描述
module Part2.ST
// Make st parametric in the state, i.e.,
//   st s a = s -> a & s
// And redefined all the functions below to use it

// 这里我不小心把类型参数搞反了……
let st a s = s -> a & s

// 剩下的就是把参数补全就好了
let read u
  : st u u
  = fun s -> s, s

let write #u (s1:u)
  : st unit u
  = fun _ -> (), s1

let bind #a #b #u
         (f: st a u)
         (g: a -> st b u)
  : st b u
  = fun s0 ->
      let x, s1 = f s0 in
      g x s1

let return #a #u (x:a)
  : st a u
  = fun s -> x, s

// 这些证明 SMT Prover 可以自己完成
let feq #a #b (f g : a -> b) = forall x. f x == g x
let left_identity #a #b #u (x:a) (g: a -> st b u)
  : Lemma ((v <-- return x; g v) `feq` g x)
  = ()
let right_identity #a #u (f:st a u)
  : Lemma ((x <-- f; return x) `feq` f)
  = ()
let associativity #a #b #c #u (f1:st a u) (f2:a -> st b u) (f3:b -> st c u)
  : Lemma ((x <-- f1; y <-- f2 x; f3 y) `feq`
           (y <-- (x <-- f1; f2 x); f3 y))
  = ()

let redundant_read_elim ()
  : Lemma ((read int;; read int) `feq` read int)
  = ()

let redundant_write_elim (x y:int)
  : Lemma ((write x ;; write y) `feq` write y)
  = ()

let read_write_noop ()
  : Lemma ((x <-- read int;  write x) `feq` return ())
  = ()
```

## 又一个习题

```fstar
// Option 因为存储了一个二元状态，Some 或 None
// 因此也可以用于构造 Monad
// 现在需要构造 Monad，并且证明其存在 Monad 的性质
module Part2.Option

// 只需要一些模式匹配即可
let bind #a #b
         (f: option a)
         (g: a -> option b)
  : option b
  = match f with
    | Some a1 -> g a1
    | None -> None

let return #a (x:a)
  : option a
  = Some x

let eq #a (f g : option a) = f == g

// SMT Prover 可以直接证明出来这些
let left_identity #a #b (x:a) (g: a -> option b)
  : Lemma ((v <-- return x; g v) `eq` g x)
  = ()
let right_identity #a (f:option a)
  : Lemma ((x <-- f; return x) `eq` f)
  = ()
let associativity #a #b #c (f1:option a) (f2:a -> option b) (f3:b -> option c)
  : Lemma ((x <-- f1; y <-- f2 x; f3 y) `eq`
           (y <-- (x <-- f1; f2 x); f3 y))
  = ()
```

## Computation Trees

首先定义一个 Action Class，其实例描述 Action 的类别：

```fstar
noeq
type action_class = {
  t : Type;
  input_of : t -> Type;
  output_of : t -> Type;
}
```

对于读写操作，Action Class 长这样：

```fstar
type rw =
  | Read
  | Write

let input_of : rw -> Type =
  fun a ->
    match a with
    | Read -> unit
    | Write -> int

let output_of : rw -> Type =
  fun a ->
    match a with
    | Read -> int
    | Write -> unit

let rw_action_class = { t = rw; input_of ; output_of }
```

Computation Tree 有两种模式：

- `Return` 型，只包含一个结果信息
- `DoThen` 型，`act` 和 `input` 一起描述输入，`continue` 是对每种可能输出的处理方式

这种定义了保证对 `tree` 向下遍历，最终一定会遍历到 `Return` 树。

```fstar
noeq
type tree (acts:action_class) (a:Type) =
  | Return : x:a -> tree acts a
  | DoThen : act:acts.t ->
             input:acts.input_of act ->
             continue: (acts.output_of act -> tree acts a) ->
             tree acts a
```

再定义 Monad 的关键函数，

其中 `bind` 的 `DoThen` 分支中，

`k` 是 `f` 的子节点，因此更接近 `Return`，

在下一步递归中 `k x` 抢占 `g` 的先机，并最终将返回结果传递给 `g`。

考虑到 `bind` 的经典使用场景，`g` 内部是 `f` 计算结果造成的变量的生命周期，

因此在 `f` 没有计算结果时 `g` 不被调用也不是一件奇怪的事情。

```fstar
let return #a #acts (x:a)
  : tree acts a
  = Return x

let rec bind #acts #a #b (f: tree acts a) (g: a -> tree acts b)
  : tree acts b
  = match f with
    | Return x -> g x
    | DoThen act i k ->
      DoThen act i (fun x -> bind (k x) g)
```

设计并无脑归纳证明树之间的相等关系：

```fstar
let rec equiv_refl #acts #a (x:tree acts a)
  : Lemma (equiv x x)
  = match x with
    | Return v -> ()
    | DoThen act i k ->
      introduce forall o. equiv (k o) (k o)
      with (equiv_refl (k o))

let rec equiv_sym #acts #a (x y:tree acts a)
  : Lemma
    (requires equiv x y)
    (ensures equiv y x)
  = match x, y with
    | Return _, Return _ -> ()
    | DoThen act i kx, DoThen _ _ ky ->
      introduce forall o. equiv (ky o) (kx o)
      with equiv_sym (kx o) (ky o)

let rec equiv_trans #acts #a (x y z: tree acts a)
  : Lemma
    (requires equiv x y /\ equiv y z)
    (ensures equiv x z)
  = match x, y, z with
    | Return _, _, _ -> ()
    | DoThen act i kx, DoThen _ _ ky, DoThen _ _ kz ->
      introduce forall o. equiv (kx o) (kz o)
      with equiv_trans (kx o) (ky o) (kz o)
```

证明其遵守 Monad 的规则：

```fstar
let right_identity #acts #a #b (x:a) (g:a -> tree acts b)
  : Lemma (bind (return x) g `equiv` g x)
  = equiv_refl (g x)

let rec left_identity #acts #a (f:tree acts a)
  : Lemma (bind f return `equiv` f)
  = match f with
    | Return _ -> ()
    | DoThen act i k ->
      introduce forall o. bind (k o) return `equiv` (k o)
      with left_identity (k o)

let rec assoc #acts #a #b #c
              (f1: tree acts a)
              (f2: a -> tree acts b)
              (f3: b -> tree acts c)
  : Lemma (bind f1 (fun x -> bind (f2 x) f3) `equiv`
           bind (bind f1 f2) f3)
  = match f1 with
    | Return v ->
      right_identity v f2;
      right_identity v (fun x -> bind (f2 x) f3)
    | DoThen act i k ->
      introduce forall o. bind (k o) (fun x -> bind (f2 x) f3) `equiv`
                     bind (bind (k o) f2) f3
      with assoc (k o) f2 f3
```

这样便可以使用 Computation Trees 定义运算：

```fstar
let read : tree rw_action_class int = DoThen Read () Return
let write (x:int) : tree rw_action_class unit = DoThen Write x Return
let read_and_increment
  : tree rw_action_class int
  = x <-- read ;
    write (x + 1);;
    return x
```

这样的 Computation Trees 可以被解释运行：

```fstar
let st a = int -> a & int
let rec interp #a (f: tree rw_action_class a)
  : st a
  = fun s0 ->
     match f with
     | Return x -> x, s0
     | DoThen Read i k ->
       interp (k s0) s0
     | DoThen Write s1 k ->
       interp (k ()) s1
```

## 又来习题

证明若两个 Computation Tree 相等，`interp` 它们会得到相等的函数。

```fstar
let feq #a #b (f g: a -> b) = forall x. f x == g x
let rec interp_equiv #a (f g:tree rw_action_class a)
  : Lemma
    (requires equiv f g)
    (ensures feq (interp f) (interp g))
  // 用树的思路递归
  = match f, g with
    | Return x, Return y -> ()
    | DoThen act i kf, DoThen _ _ kg ->
      // 尝试证明子树中的结论
      introduce forall o. feq (interp (kf o)) (interp (kg o))
      with interp_equiv (kf o) (kg o)
```

证明若两个 Computation Tree 满足 `equiv` 关系，那么它们满足 `==` 关系。

注意 `==` 关系是 Provably Equal.

定义函数相等如下：

```fstar
let funext =
  #a:Type ->
  #b:(a -> Type) ->
  f:(x:a -> b x) ->
  g:(x:a -> b x) ->
  Lemma (requires (forall (x:a). f x == g x))
        (ensures f == g)
```

在前面的章节使用了奇技淫巧证明 $\eta$-expanded 函数的 `funext` 可以推出 `==`，

虽然这里面有一堆暂未讲到的符号：

```fstar
let eta (#a:Type) (#b: a -> Type) (f: (x:a -> b x)) = fun x -> f x
let funext_on_eta (#a : Type) (#b: a -> Type) (f g : (x:a -> b x))
                  (hyp : (x:a -> Lemma (f x == g x)))
  : squash (eta f == eta g)
  = _ by (norm [delta_only [`%eta]];
          pointwise (fun _ ->
             try_with
                     (fun _ -> mapply (quote hyp))
                     (fun _ -> trefl()));
           trefl())
```

$\eta$-expanded 函数可以认为是将方法变为函数，可以参考 [Stack Overflow](https://stackoverflow.com/questions/39445018/what-is-the-eta-expansion-in-scala).

具体做法就是：

```fstar
let eta (#a:Type) (#b: a -> Type) (f: (x:a -> b x)) = fun x -> f x
```

我的理解是未经 $\eta$-expanded 的函数可能签名不纯，

比如可能带一些 Refinement 或者对象签名，

但是 $\eta$-expand 之后就只剩下函数和返回值。

比如，带有 Refinement 的函数可以满足 `funext`，但是不满足 `==`：

```fstar
let f (x:nat) : int = 0
let g (x:nat) : int = if x = 0 then 1 else 0
let pos = x:nat{x > 0}
let full_funext_false (ax:funext)
  : False
  = ax #pos f g;
    assert (f == g);
    assert (f 0 == g 0);
    false_elim()
```

回到计算树，要对树的 `==` 性质进行探索，首先要引入一些 [奇怪的库](https://github.com/FStarLang/FStar/blob/master/ulib/FStar.FunctionalExtensionality.fst)：

```fstar
module F = FStar.FunctionalExtensionality
open FStar.FunctionalExtensionality
```

然后要限定函数是 $\eta$-expaneded 的：

```fstar
noeq
type tree (acts:action_class) (a:Type) =
  | Return : x:a -> tree acts a
  | DoThen : act:acts.t ->
             input:acts.input_of act ->
             //We have to restrict continuations to be eta expanded
             //that what `^->` does. Its defined in FStar.FunctionalExtensionality
             continue:(acts.output_of act ^-> tree acts a) ->
             tree acts a
```

构造函数步骤也要修改：

```fstar
let rec bind #acts #a #b (f: tree acts a) (g: a -> tree acts b)
  : tree acts b
  = match f with
    | Return x -> g x
    | DoThen act i k ->
      //Now, we have to ensure that continuations are instances of
      //F.( ^-> )
      DoThen act i (F.on _ (fun x -> bind (k x) g))
```

最后调库即可：

```fstar
let rec equiv_is_equal #acts #a (x y: tree acts a)
  : Lemma
    (requires equiv x y)
    (ensures x == y)
  = match x, y with
    | Return _, Return _ -> ()
    | DoThen act i kx, DoThen _ _ ky ->
      introduce forall o. kx o == ky o
      with equiv_is_equal (kx o) (ky o);
      F.extensionality _ _ kx ky
```

## 不确定性事件

`Or` 接受两个 `tree acts a`，返回一个 `tree acts a`，

是对在前两个 `tree` 里面随机选择一个执行（取决于解释器）的封装。

```fstar
noeq
type tree (acts:action_class) (a:Type) =
  | Return : x:a -> tree acts a
  | DoThen : act:acts.t ->
             input:acts.input_of act ->
             continue: (acts.output_of act -> tree acts a) ->
             tree acts a
  | Or :  tree acts a -> tree acts a -> tree acts a
```

注意 `bind` 函数在处理 `Or` 时，应该给每个分支都接上后面的步骤：

```fstar
let rec bind #acts #a #b (f: tree acts a) (g: a -> tree acts b)
  : tree acts b
  = match f with
    | Return x -> g x
    | DoThen act i k ->
      DoThen act i (fun x -> bind (k x) g)
    | Or m0 m1 -> Or (bind m0 g) (bind m1 g)
```

解释器中增加 `Or` 分支，采用随机执行策略：

```fstar
let randomness = nat -> bool
let par_st a = randomness -> pos:nat -> s0:int -> (a & int & nat)
let rec interp #a (f:tree rw_actions a)
  : par_st a
  = fun rand pos s0 ->
      match f with
      | Return x -> x, s0, pos
      | DoThen Read _ k -> interp (k s0) rand pos s0
      | DoThen Write s1 k -> interp (k ()) rand pos s1
      | Or l r ->
        if rand pos
        then interp l rand (pos + 1) s0
        else interp r rand (pos + 1) s0
let st a = int -> a & int
let interpret #a (f:tree rw_actions a)
  : st a
  = fun s0 ->
      let x, s, _ = interp f (fun n -> n % 2 = 0) 0 s0 in
      x, s
```

## 并发

参考 `bind`，对两个事件构建并发事件，运行逻辑是：

```fstar
// 此并发逻辑优先执行 f
let rec l_par #acts #a #b (f:tree acts a) (g:tree acts b)
  : tree acts (a & b)
  = match f with
    // f 任务结束后，专心执行 g
    | Return v -> x <-- g; return (v, x)
    // 如果 f 后面还有任务，执行任务后采用优先执行 g 的并发逻辑
    | DoThen a i k ->
      DoThen a i (fun x -> r_par (k x) g)
    // 如果 f 是不确定性任务，则在每个分支后面加上 g
    | Or m0 m1 -> Or (l_par m0 g) (l_par m1 g)

// 此并发逻辑优先执行 g
and r_par #acts #a #b (f:tree acts a) (g: tree acts b)
  : tree acts (a & b)
  = match g with
    | Return v -> x <-- f; return (x, v)
    | DoThen a i k ->
      DoThen a i (fun x -> l_par f (k x))
    | Or m0 m1 -> Or (r_par f m0) (r_par f m1)

let par #acts #a #b (f: tree acts a) (g: tree acts b)
  : tree acts (a & b)
  // 随机选择先执行 f 还是 g
  = Or (l_par f g) (r_par f g)
```

直接使用 `par` 构造并发任务：

```fstar
let read : tree rw_actions int = DoThen Read () Return
let write (x:int) : tree rw_actions unit = DoThen Write x Return
let inc
  : tree rw_actions unit
  = x <-- read ;
    write (x + 1)
let par_inc = par inc inc
```

由于 `par` 可以视为构造 **一个** 顺序执行事件，

程序会连续读两次，然后连续写两次，

最后只会自增一次而不是两次。

可以采用这种方式检验：

```fstar
let test_prog = assert_norm (forall x. snd (interpret par_inc x) == x + 1)
```

## 最后的习题

写一个支持原子化自增的计算树解释系统。

```fstar
module Part2.AtomicIncrement
open FStar.Classical.Sugar

noeq
type action_class = {
  t : Type;
  input_of : t -> Type;
  output_of : t -> Type;
}

noeq
type tree (acts:action_class) (a:Type) =
  | Return : x:a -> tree acts a
  | DoThen : act:acts.t ->
             input:acts.input_of act ->
             continue: (acts.output_of act -> tree acts a) ->
             tree acts a
  | Or :  tree acts a -> tree acts a -> tree acts a

let return #acts #a (x:a)
  : tree acts a
  = Return x

let rec bind #acts #a #b (f: tree acts a) (g: a -> tree acts b)
  : tree acts b
  = match f with
    | Return x -> g x
    | DoThen act i k ->
      DoThen act i (fun x -> bind (k x) g)
    | Or m0 m1 -> Or (bind m0 g) (bind m1 g)

let rec l_par #acts #a #b (f:tree acts a) (g:tree acts b)
  : tree acts (a & b)
  = match f with
    | Return v -> x <-- g; return (v, x)
    | DoThen a i k ->
      DoThen a i (fun x -> r_par (k x) g)
    | Or m0 m1 -> Or (l_par m0 g) (l_par m1 g)

and r_par #acts #a #b (f:tree acts a) (g: tree acts b)
  : tree acts (a & b)
  = match g with
    | Return v -> x <-- f; return (x, v)
    | DoThen a i k ->
      DoThen a i (fun x -> l_par f (k x))
    | Or m0 m1 -> Or (r_par f m0) (r_par f m1)

let par #acts #a #b (f: tree acts a) (g: tree acts b)
  : tree acts (a & b)
  = Or (l_par f g) (r_par f g)

type rwi =
  | R
  | W
  | Inc

// R 只输出，W 只输入，Inc 不输入不输出
let input_of_rwi : rwi -> Type
  = fun a ->
      match a with
      | R -> unit
      | W -> int
      | Inc -> unit
let output_of_rwi : rwi -> Type
  = fun a ->
      match a with
      | R -> int
      | W -> unit
      | Inc -> unit

let rwi_actions = { t = rwi; input_of=input_of_rwi ; output_of=output_of_rwi }

// 编译器一直说 x <-- y 的语法 deprecated
// 因此使用推荐的 let in 语法
// 理论上 R W 走一遍也没影响
// 但答案只用了 Inc，更符合直觉一些
let atomic_inc : tree rwi_actions unit = DoThen Inc () Return
let randomness = nat -> bool
let par_st a = randomness -> pos:nat -> s0:int -> (a & int & nat)

let rec interp_rwi #a (f:tree rwi_actions a)
  : par_st a
  = fun rand pos s0 ->
      match f with
      | Return x -> x, s0, pos
      // 对三种操作分类讨论
      | DoThen R _ k -> interp_rwi (k s0) rand pos s0
      | DoThen W s1 k -> interp_rwi (k ()) rand pos s1
      // 自增的时候不需要输入参数，也不需要返回值
      | DoThen Inc _ k -> interp_rwi (k ()) rand pos (s0 + 1)
      | Or l r ->
        if rand pos
        then interp_rwi l rand (pos + 1) s0
        else interp_rwi r rand (pos + 1) s0
let st a = int -> a & int
let interpret_rwi #a (f:tree rwi_actions a)
  : st a
  = fun s0 ->
      let x, s, _ = interp_rwi f (fun n -> n % 2 = 0) 0 s0 in
      x, s
let par_atomic_inc = par atomic_inc atomic_inc

let test_par_atomic_inc =
  assert_norm (forall x. snd (interpret_rwi par_atomic_inc x) == x + 2)
```
