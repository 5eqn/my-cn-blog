---
title: PL | 递归数据结构
date: 2023-10-06 13:34:58
tags:
- 草稿
---

## 算法与结构的递归同构

在上期博客里，我提到一个问题：

> 对于尾递归的链表排序，似乎需要创造一个很逆天的 Zipper！有没有能利用上 ADT 的更好的思路？

该论文[^1] 中的 Hylomorphisms 表达的差不多正是这种东西！同时，论文揭示了 Hylomorphisms 为 Catamorphisms 和 Anamorphisms 的复合。然而，原论文充斥着猫话，我选择选择看原论文比较简明的部分，再加上一些论文解读[^2]，一系列对 Recursion Schemes 的介绍博客[^3]，以及一篇 Medium 文章[^4]。

目的论地，我们可以直接整一个更适合用于排序的 ADT，这里是二叉树，也是我们整个递归函数的递归结构。这时用 Anamorphism 从数组生成二叉树，用 Catamorphism 从二叉树生成数组即可。

```haskell
mergeSort :: Ord a => [a] -> [a]
mergeSort = hylo alg coalg where
  alg EmptyF      = []
  alg (LeafF c)   = [c]
  alg (NodeF l r) = merge l r  coalg []  = EmptyF
  coalg [x] = LeafF x
  coalg xs  = NodeF l r where
    (l, r) = splitAt (length xs `div` 2) xs
```

事实上，Anamorphism 是满射（这会导致部分不同的值被映射到相同的「递归结构实例」，这也是为什么记忆化[^5] 只能对 Anamorphism 做），Catamorphism 是单射，观察一些自然数递归容易感受到这一规律。

### 一些小改进

介绍系列大部分讲的是关于 Catamorphisms 和 Anamorphisms 的小改进：

- Paramorphism: 保留原参数的可引用性
  - 如果在想实现就地修改的时候，只需要使用 Ana- + Catamorphism 就够了
- Apomorphism: 允许 break
  - 但本来不就能 break 吗？有什么区别？
- Histomorphism: 记录结果历史
  - 或许可以实现自动记忆化？
- Futumorphism: 允许树状 break
  - 依然不太明白
- Chrono- / Hypomorphism: 先前东西的神秘组合

## `bind` 可以自动生成

上面生成的是 `map`、`cata`、`ana`、`fold` 之类的函数，但其实 `bind` 也是可以生成的。

在参数化 ADT，例如 `Interaction next`，使之成为 Functor 后，Free Monad[^6] 可以自动为 `Free Interaction r = Free (Interaction (Free Interaction)) | Pure r` 生成 `bind` 函数。其和 Futumorphism 的联系尚不明确。

## 下一步

- 尝试更多例子
  - 找到 free monad 和 futumorphism 的关联
  - 探索记忆化的更多可能
  - 尝试改成 fully in-place 的版本
- 恶补猫论知识，了解对偶到底是什么含义

[^1]:https://link.springer.com/chapter/10.1007/3540543961_7
[^2]:https://reasonablypolymorphic.com/blog/recursion-schemes/index.html
[^3]:https://blog.sumtypeofway.com/posts/introduction-to-recursion-schemes.html
[^4]:https://medium.com/@jaredtobin/practical-recursion-schemes-c10648ec1c29
[^5]:http://blog.sigfpe.com/2014/05/cofree-meets-free.html
[^6]:https://www.haskellforall.com/2012/06/you-could-have-invented-free-monads.html
