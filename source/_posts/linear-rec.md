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
