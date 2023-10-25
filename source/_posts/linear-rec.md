---
title: PL | 自动递归，但是尾递归
date: 2023-10-07 17:57:39
tags:
- 草稿
---

## 问题引入

正常而言，`cata` 函数的实现是：

```haskell
data Fix f = Fix {unfix :: f (Fix f)}

cata :: Functor f -> (f a -> a) -> Fix f -> a
cata fn x = fn $ fmap (cata fn) $ unfix x
```

假设我们有：

```haskell
data Tree x next = Tree next x next | Leaf x
```

其 `Functor` 实现为：

```haskell
fmap :: (a -> b) -> Tree x a -> Tree x b
fmap f (Leaf x) = Leaf x
fmap f (Tree l x r) = Tree (f l) x (f r)
```

我们需要对 `fmap` 进行 CPS 变换：

```haskell
fmap :: (a -> (b -> z) -> z) -> Tree x a -> (Tree x b -> y) -> y
fmap f (Leaf x) cont = cont Leaf
fmap f (Tree l x r) cont = f l $ \l' -> f r $ \r' -> cont $ Tree l' x r'
```

以及对 `cata` 进行 CPS 变换。为避免混淆，我把新函数取名为 `kakaa`：

```haskell
kakaa :: Functor f -> (f a -> a) -> Fix f -> (a -> z) -> z
kakaa fn x cont = fmap (kakaa fn) (unfix x) $ \x' -> cont $ fn x'
```

现在我们需要把右边的匿名函数变为闭包。对于 `kakaa`，可以这样处理：

```haskell
kakaa :: Functor f -> (f a -> a) -> Fix f -> Ctx f a -> a
kakaa fn x ctx = fmap (kakaa fn) (unfix x) (Lin fn ctx)
```

`app` 函数似乎比较繁琐，需要处理 `cont` 返回值不同的情况，`fmap` 和 `kakaa` 的 `Ctx` 的类型也不知道要不要统一……考虑到每个 ADT 有自己的 `Ctx`，`kakaa` 作为公用函数也需要保留一个对 `Ctx` 的引用和 `Lin` 构造函数，或许可以通过一个 Sum Type 来解决？对于 `fmap`，可以用编译期代码生成来实现，不过过程也较为阴间。如果找不到更好的方法，我感觉还是直接自动生成对应的递归组合子更好！

## 更直接的方式

考虑对于二叉树，先重温一下 `map` 的例子。对于非不动点的版本，其 `map` 为：

```haskell
map :: Tree x -> (x -> y) -> Tree y
map t f = case t of
  Tree l x r -> Tree (map l f) (f x) (map r f)
  Leaf x -> Leaf (f x)
```

`map` 经过 CPS 变换为：

```haskell
map :: Tree x -> (x -> y) -> (Tree y -> Tree y) -> Tree y
map t f cont = case t of
  Tree l x r -> map l f (\l' ->
    map r f (\r' ->
      cont $ Tree l' (f x) r'))
  Leaf x -> cont $ Leaf (f x)
```

把匿名函数封装成闭包，大概会变成这样的东西：

```haskell
data Tree x = Tree (Tree x) x (Tree x) | Leaf x deriving (Show, Eq)

data Ctx x
  = L (Ctx x) x (Tree x)
  | R (Tree x) x (Ctx x)
  | Top

down :: Tree x -> (x -> x) -> Ctx x -> Tree x
down t f ctx =
  case t of
    Tree l x r -> down l f (L ctx (f x) r)
    Leaf x -> app (Leaf (f x)) f ctx

app :: Tree x -> (x -> x) -> Ctx x -> Tree x
app t f ctx =
  case ctx of
    Top -> t
    R l x up -> app (Tree l x t) f up
    L up x r -> down r f (R t x up)

map :: Tree x -> (x -> x) -> Tree x
map t f =
  down t f Top
```

注意这里 `map` 两端的类型必须相同，否则整 FIP 没有意义。

对于不定点版本的二叉树，其 `cata` 为：

```haskell
cata :: (Tree x a -> a) -> Fix (Tree x) -> a
cata fn tr = case tr of
  Fix (Tree l x r) -> fn (Tree (cata fn l) x (cata fn r))
  Fix (Leaf x) -> fn (Leaf x)
```

进行 CPS 变换并转为闭包后得到：

```haskell
down :: Fix (Tree x) -> (Tree x a -> a) -> Ctx x a -> a
down (Fix (Tree l x r)) f ctx = down l f (L ctx x r)
down (Fix (Leaf x)) f ctx = app (f (Leaf x)) f ctx

app :: a -> (Tree x a -> a) -> Ctx x a -> a
app a f Top = a
app a f (R l x up) = app (f (Tree l x a)) f up
app a f (L up x r) = down r f (R a x up)
```

但这会破坏原有的数据！原先的 `map` 相当于 `cata` 的时候已经在构建一个新的 `Tree`，因此是 FIP 的，但现在这个不是！

对于 `fold` 而不产生栈空间数据结构的情况，或许 Paramorphism / Histomorphism 才是 FIP 的？

## 补充

- `cata` 不可能 FIP，最多通过把产生的值存在栈空间实现 FBIP，内存消耗为 $O(\log n)$
- 考虑尝试把正常的递归写成 Hylomorphism，看看是否 easier to reason about
- indexed DS 和 recursive DS 疑似有某种对应关系，但对于例如树的东西想不到怎么推广

### Indexed DS

如果把 Indexed Array 强行当作链表，我们可以写出：

```
remove ls a =
  ls.cata
    [] => []
    ls :: x if x == a => ls
    ls :: x => ls :: x
```

这对于 Indexed Array 显然是不合法的。

如果把 Indexed Array 视为黑箱，则无法得到 cata。

如果修改 `remove` 函数，保留 cata，只生成黑箱：

```
remove ls a =
  ls.cata
    [] => [0 for ls.length]
    ls :: x if x == a => ls
    ls :: x => ls[i] <- x
```

可以看到两个问题：

- `i` 如何获取？
- 该函数不 FIP

如果再创建一个临时的 0 至 n 的链表，以此 fold over an indexed array，应当是一个可行方案。

### Index encoded in Reuse Token

在和 Anqur 讨论后获得一个灵感：给 Reuse Token 的 Type 添加位置参数，使其能够反映位置信息。

不过这样一个 Vector 可以被 destructively matched into 很多不同的东西，这很坏。

### Indexed DS and Coinductive Types

考虑基础的 Coinductive Type，`Stream`：

```
data Stream
  hd : Stream -> Nat
  tl : Stream -> Stream
```

如果我们纤维化一个构造函数：

```
data Array T n
  get : Fin n -> Array T n -> T
```

就可以构造出一个 Indexed DS。

考虑构造 Stream 的方式：

```
stream : Nat -> Stream
stream n = make s from
  hd s = n
  tl s = stream (S n)
```

推广到数组：

```
array : Array Int 3
array = make a from
  get i a = i.toInt
```

Inductive Type 添加 Token：

```
data Tuple
  Tuple : Tok -> A -> B -> C -> Tuple
```

Coinductive Type 添加 Token：

```
data Stream
  hd : Stream -> Nat
  tl : Stream -> Stream
  tok : Stream -> Tok
```

对于数组：

```
data Array
  get : Fin n -> Array T n -> T
  tok : Array T n -> Tok
```

FIP 的 inductive type 修改：

```
mod : Tuple -> Tuple
mod (Tuple tok a b c) = Tuple tok a 0 c
```

FBIP 的数组元素修改：

```
mod : Array Int n -> Array Int n
mod arr = make a from
  get 0 a = 0
  get i a = get i arr
  tok a = tok arr
```

这种方式的缺点是判断元素是否修改太过 Ad-Hoc。但是！考虑下面的改动方法：

```
data Array
  get : (x : Fin n) -> Array T n -> (T, Tok x)

mod : Array Int n -> Fin n -> Int -> Array Int n
mod arr index value = make a from
  get i a = case i of
    index =>
      let (_, tok) = get index arr in
      (value, tok)
    otherwise => get i arr
```

这样可以轻松地避免 cross-updating，从而实现线程安全！（但实际上起到的效果只是要求必须点对点 `map`）

如果参数反转？

```
data Array
  content : Array T n -> (x : Fin n) -> (T, Tok x)

mod : Array Int n -> Fin n -> Int -> Array Int n
mod arr index value = make a from
  content a = \i => case i of
    index =>
      let (_, tok) = content arr index in
      (value, tok)
    otherwise => content arr i
```

那完全可以不使用 coinductive type！

```
data Array T n = Array ((x : Fin n) -> (T, Tok x))

mod : Array Int n -> Fin n -> Int -> Array Int n
mod (Array arr) index value = Array (
  \i => case i of
    index =>
      let (_, tok) = arr index
      (value, tok)
    otherwise => arr i
)
```
