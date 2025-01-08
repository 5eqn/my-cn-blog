---
title: FStar 官方习题 Constructive & Classical Connectives
date: 2023-01-22 16:20:20
tags:
- 编程
- PL
---

## 链接

[官网](http://fstar-lang.org/tutorial/book/part2/part2_logical_connectives.html#constructive-classical-connectives)

## 内容

讲述了各种数理逻辑符号在 `F*` 里的原始实现，以及接近数学形式的 `squashed form`。

提供了 [语法糖](https://github.com/FStarLang/FStar/blob/master/tests/micro-benchmarks/ClassicalSugar.fst) 来书写用于操作 `squashed form` 的命题。

~~个人感觉 `F*` 提供的语法糖相比 `Lean` 更冗长，使用体验也比较差，有种 `Brainf**k` 的感觉~~

## 习题一

### 大意

使用语法糖实现 `~p` 的 `Introduction` 和 `Elimination`。

### AC 代码

```
let neg_intro #p (f:squash p -> squash False)
  : squash (~p)
  = introduce p ==> False
    with proof_p. f proof_p

let neg_elim #p #q (f:squash (~p)) (lem:unit -> Lemma p)
  : squash q
  = eliminate p ==> False
    with lem()
```

## 补充

后面有个依赖于前面哈希树章节的习题，但我前面没做，因此这个也做不了。
