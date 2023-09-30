---
title: 绷语言 | 设计哲学 Pt.3 和组合数学
date: 2023-09-29 14:08:10
tags:
- PL
- 绷语言
- 技术性
---

本题本来想用绷语言重写标程，结果发现我思路比标程简洁一些，就还是重写自己的程序了。

## CF 737 C. (*1700)

[原题](https://codeforces.com/contest/1557/problem/C)

### C++

```cpp
#include <iostream>

const long long M = 1e9 + 7;

long long qpow(long long x, int p) {
  long long res = 1;
  while (p) {
    if (p % 2) {
      res *= x;
      res %= M;
    }
    x *= x;
    x %= M;
    p /= 2;
  }
  return res;
}

int main() {
  std::ios::sync_with_stdio(false);
  std::cin.tie(nullptr);
  std::cout.tie(nullptr);
  int t;
  std::cin >> t;
  while (t--) {

    // read input
    int n, k;
    std::cin >> n >> k;

    // count
    long long eq_case = 1;
    long long dom_case = 0;
    for (int i = 0; i < k; i++) {
      if (n % 2 == 0) {
        dom_case *= qpow(2, n);
        dom_case %= M;
        dom_case += eq_case;
        dom_case %= M;
        eq_case *= qpow(2, n - 1) - 1;
        eq_case %= M;
      } else {
        eq_case *= qpow(2, n - 1) + 1;
        eq_case %= M;
      }
    }
    std::cout << (eq_case + dom_case) % M << '\n';
  }
  return 0;
}
```

### 绷语言

```
let ++ = x => y => (x + y) % M
let * = x => y => (x * y) % M
let ** = x => y =>
  let a, p, res = x, y, 1 rec
    if p == 0 then nope else
    a * a, p / 2, (if p % 2 == 0 then res else res * a)

let run = ++ => * => ** =>
  let t = input
  run for t
    let n, k = input, input
    let n_eq, n_dom, ptr = 1, 0, 0 rec
      if ptr == n then nope else
      if n % 2 == 0
      then n_eq * (2 ** (n - 1) - 1), n_dom * 2 ** n ++ n_eq, ptr + 1
      else n_eq * (2 ** (n - 1) + 1), 0, ptr + 1
    println(n_eq ++ n_dom)

run(++)(*)(**)
```

我还是计划使用 `println` 表示带换行的 `print`。

### 语言设计解读

- 专用：`int` 类型默认 64 位，对内存要求高时可自由切换位数。在 C++ 中则需要自己手动启用 `long long` 或 `#define int long long`。
- 明确：利用高阶函数将需要改变定义的函数参数化，避免一切重载的同时不失便捷性。如果不想列出操作符，也可以选择将类型参数化。在 C++ 中则需要重载运算符。
