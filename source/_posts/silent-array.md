---
title: 绷语言 | 数组设计
date: 2023-09-15 22:54:44
tags:
- PL
- 绷语言
- 技术性
- 精选
---


我希望[绷语言](https://github.com/5eqn/silent-lang)中的数组尽可能符合直觉，这是我的设计发生的变化。

## 数组创建

```
let n = input
let initedArray = [0 rep n]
let uninitedArray = [rep n]
let fixedArray = [2, 3, 4]
```

未初始化的数组的值是随机的，但应该被视为不可访问。

使用 `rep` 关键字（代表 repeat）而不是 `*` 或 `x`，是为了避免和值的直接相乘混淆，且让语义尽可能清晰。

## 数组标序

和 C 一样，直接：

```
let arr = [2, 3, 4]
let _ = print(arr[0])
```

`0` 代表第一个元素。

## 数组修改

```
let n = input
let arr, x, y = [input rep n], input, input
  upd arr[x <- arr[y], y <- arr[x]], x, y
```

请注意数组是仿射的，也就是说：

- 在被整体引用（不包括取一个数的情况）时，不再能被引用
- 不一定要被引用

这和 Rust 的内存管理系统实质上是一样的。例如，以下代码是不合法的：

```
let n = input
let arr, x, y = [input rep n], input, input
  upd arr[x <- arr[y]][y <- arr[x]], x, y
```

不合法是因为在计算 `arr[x <- arr[y]]` 之后，`arr` 不再能被引用。

一个好的直觉是把 `let` 看成是在关联一个名字和一个内存地址的东西，而不是直接操作内存。只有作为整体引用（例如数组修改）才会操作内存，虽然看起来是在产生一个新的值。

## 数组长度

我可能会使用一个结构体来代表一个数组：

```c
struct array {
  int length;
  int *ptr;
}
```

有了这样的结构体，你可以这样获取一个数组的长度（容量）：

```
let arr = [1, 2, 3]
let _ = print(len(arr)) // 3
```

就像 Go 语言一样。

## 数组类型

我后面想加入依值类型，但现在我只想写简单的版本：

```
let f = (1 arr: int[]) => arr[0 <- 5]
let _ = print(f([2, 3, 4])[0]) // 5
```

就像 C 语言一样。

## 不支持的特性

### 数组合并

数组合并是一个构造方式，但在绷语言的设计哲学中，我们希望任何对数组发生的变化只是从上一状态而来。

### 不定长数组

不定长数组可以通过定长数组直接实现，没必要作为核心语言特性。
