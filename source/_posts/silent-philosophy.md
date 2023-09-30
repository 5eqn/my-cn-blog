---
title: 绷语言 | 设计哲学 Pt.1 和签到级模拟
date: 2023-09-28 18:22:03
tags:
- PL
- 绷语言
- 技术性
---

喜报，我还是懒得搞英文博客了！感觉完全没有动机喵。

## CF 737 A. (*800)

[原题](https://codeforces.com/contest/1557/problem/A)

### C++ 解答

```cpp
#include <algorithm>
#include <cstdio>
#include <iostream>

const int N = 1e5 + 4;
int a[N];

int main() {
  std::ios::sync_with_stdio(false);
  std::cin.tie(nullptr);
  std::cout.tie(nullptr);
  int t;
  std::cin >> t;
  while (t--) {

    // read input
    int n;
    std::cin >> n;
    for (int i = 0; i < n; i++) {
      std::cin >> a[i];
    }
    std::sort(a, a + n, [](int a, int b) { return a > b; });

    // result = x / u + y / v
    long long x = a[0];
    long long y = 0;
    for (int i = 1; i < n; i++) {
      y += a[i];
    }
    long long u = 1;
    long long v = n - 1;

    // transfer until value declines
    double result = (double)x / u + (double)y / v;
    for (int i = 1; i < n - 1; i++) {
      x = x + a[i];
      y = y - a[i];
      u = u + 1;
      v = v - 1;
      double next = (double)x / u + (double)y / v;
      if (next <= result) {
        break;
      }
      result = next;
    }

    // print result
    printf("%.12lf\n", result);
  }
  return 0;
}
```

### 绷语言解答

```
let t = input
run for t

  // read input
  let n = input
  let a = [input for n]
    mut a.sort(>)

  // result = x / u + y / v
  let y_init, next_i = 0, 1 rec
    if next_i == n then nope else
    y_init + a[next_i], next_i + 1

  // transfer until value declines
  let x, y, u, v, res = 1, y_init, 1, n - 1, -inf rec
    if v == 0 then nope else
    x + 1, y - 1, u + a[x], v - a[x], res.max(x / u + y / v)
  run print(res)
```

### 语言设计解读

- 简洁：出于语义性考虑，`sort` 需要接受一个 `int -> int -> bool`，而 `>` 可以被直接看成 `int -> int -> bool`，因此 `sort` 可以直接接受 `>` 作为参数。在 C++ 中则需要接受整个匿名函数，且匿名函数需要手动标注类型。
- 自然：为贴近人直觉上考虑问题的思路，`for n` 既可以前置也可以后置，表示重复 `n` 次。在 C++ 中则需要手写 while 或 for 循环来表达相同的语义。
- 自由：可以直接使用 `input` 来读入一个任意类型的东西，类型可以通过类型推导得出。在 C++ 中也可以自动推导类型，但需要手写 `std::cin`。
- 智能：直接支持创建变量长度的数组。在 C++ 中需要预先设置一个大常量。
- 专一：用 `mut`（来自 Rust）和 `rec`（来自 OCaml）封装一切就地修改，在块内享受 C 的便捷，在块外享受函数式的严谨。在 C++ 中难以保证一个值未来不会被错误地修改，从而无法进行较为激进的编译器优化，程序逻辑也容易产生不可预料的问题。
- 丝滑：基于无括号元组的丝滑编辑体验。在 C++ 中需要使用 `pair`。
- 严谨：利用 `nope` 关键字在显然不合理时跳出循环，若忘记添加 `nope` 会无法编译通过。在 C++ 中则需要自己手动模拟程序运行并判断边界情况，更容易产生错误。
