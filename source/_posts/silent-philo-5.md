---
title: 绷语言 | 设计哲学 Pt.5 和一点元组语法迷思
date: 2023-09-30 14:29:59
tags:
- 草稿
---

## CF 846 B. (*1100)

[原题](https://codeforces.com/contest/1780/problem/B)

显然本题无法对数组选段情况进行枚举，因此尝试在数学上找到公式。

由于涉及求和，GCD 在加法下亦性质良好，不难注意到应使用前缀和。

### CPP

```cpp
#include <algorithm>
#include <iostream>
#include <numeric>

int main() {
  std::ios::sync_with_stdio(false);
  std::cin.tie(nullptr);
  std::cout.tie(nullptr);
  int t;
  std::cin >> t;
  while (t--) {
    int n;
    std::cin >> n;
    long long a[n + 1];
    a[0] = 0;
    for (int i = 1; i <= n; i++) {
      long long x;
      std::cin >> x;
      a[i] = a[i - 1] + x;
    }
    long long max_g = -1;
    for (int i = 1; i < n; i++) {
      long long g = std::gcd(a[i], a[n]);
      max_g = std::max(max_g, g);
    }
    std::cout << max_g << '\n';
  }
  return 0;
}
```

### 绷语言

```
main : Void
main =
  let t = input
  run for t
    let n = input
    let a = [input for n]
    let (sum, ptr) = ([0 for n + 1], 0) rec
      if ptr == n then nope else
      (sum mut _[ptr + 1] = _[ptr] + a[ptr], ptr + 1)
    let (res, ptr) = (0, 1) rec
      if ptr == n then nope else
      (max res (gcd sum[ptr] sum[n]), ptr + 1)
    print(res)
```

### 逗号结合律哲学

逗号结合律仅弱于各中缀运算符，只要是有字母或 `=`、`=>` 的情况下，逗号结合性都更强。

其实关于逗号结合性的设计，我也一直在纠结。例如假如使用传统元组格式，上面的程序会从：

```
let sum, ptr = [0 for n + 1], 0 rec
  if ptr == n then nope else
  (sum mut _[ptr + 1] = _[ptr] + a[ptr]), ptr + 1
```

变成：

```
let (sum, ptr) = ([0 for n + 1], 0) rec
  if ptr == n then nope else
  (sum mut _[ptr + 1] = _[ptr] + a[ptr], ptr + 1)
```

传统元组相对无括号元组净增两对括号，但往往无括号元组容易引发歧义。例如假如写成：

```
let sum, ptr = [0 for n + 1], 0 rec
  if ptr == n then nope else
  sum mut _[ptr + 1] = _[ptr] + a[ptr], ptr + 1
```

用户可能很难看出问题，但由于 `,` 结合性强于 `=`，该代码应被视为：

```
let sum, ptr = [0 for n + 1], 0 rec
  if ptr == n then nope else
  sum mut _[ptr + 1] = (_[ptr] + a[ptr], ptr + 1)
```

这是不符合程序意思的。要解决这个问题，用户需要更熟悉逗号的结合律，否则容易写出有歧义的程序，从而得到未预料的编译结果，获得更差的体验。

事实上，一门好的编程语言需要尽可能避免这样的设计。例如 Golang 的某框架中的某函数 `AbortWithStatusJSON` 就具有歧义，用户可能会期望其能自动起到 `return` 的效果，但实际上并没有，甚至会连续返回 JSON 文本（事实上 `Abort` 只是阻止接下来的中间件被调用），且这种歧义无法在编译期暴露，这会大大增加用户的编程成本。

但有括号元组也有一个很大的缺点，考虑对函数参数进行模式匹配，若有无括号元组我们只需要：

```
f(x, y) = x * y
```

但没有的话，则需要：

```
f((x, y)) = x * y
```

往往用户只想表达 `f` 接受两个参数 `x` 和 `y`，使用双重括号会带来较差的语义性。

解决这个问题需要使用 Haskell 语法：

```
f (x, y) = x * y
```

但 Haskell 中函数的表达习惯和我们习以为常的大相径庭，对不熟悉 Haskell 的人来说语义性也较差。

我暂时决定规避歧义优先级大于语法语义性，且不希望语法太过冗长，对类 Idris2 的类型标注形式也有一定的执念，故采用 Idris2 式的语法。
