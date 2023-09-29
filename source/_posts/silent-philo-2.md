---
title: 绷语言 | 设计哲学 Pt.2
date: 2023-09-29 00:30:17
tags:
- PL
- 绷语言
- 技术性
---

## CF 737 B. (*1100)

[原题](https://codeforces.com/contest/1557/problem/B)

### C++

```cpp
#include <algorithm>
#include <iostream>

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
    int a[n];
    for (int i = 0; i < n; i++) {
      std::cin >> a[i];
    }

    // make discrete
    int b[n];
    for (int i = 0; i < n; i++) {
      b[i] = i;
    }
    std::sort(b, b + n, [&](int x, int y) {
      if (a[x] == a[y]) {
        return x < y;
      } else {
        return a[x] < a[y];
      }
    });

    // simulate
    int last = b[0];
    int cnt = 1;
    for (int i = 1; i < n; i++) {
      if (b[i] != last + 1) {
        cnt++;
      }
      last = b[i];
    }
    if (cnt <= k) {
      std::cout << "YES\n";
    } else {
      std::cout << "NO\n";
    }
  }
  return 0;
}
```

### 绷语言

```
let t = input
run for t
  
  // read input
  let n, k = input, input
  let a = [input for n]

  // make discrete
  let b = [i for i in n]
    mut b.sort(x => y => a[x] < a[y] || x < y)

  // simulate
  let cnt, left = 0, 0 rec
    if left == n - 1 then nope else
    let new_cnt = if b[left + 1] - b[left] == 1 then cnt else cnt + 1
    new_cnt, left + 1
  let res = if cnt <= k then "YES" else "NO"
  run print(res)
```

### 语言设计解读

- 自由：一切能被引用者皆可被引用，在 Dependent Types 中也有类似的思想。这里在创建数组时允许用类似于 Python 的语法 `f(i) for i in n` 来引用当前索引，在 C++ 中则需要手动创建 `for` 循环，忽略了获取索引本身是更本质的需求
- 直观：`rec` 语法促使用户选择更符合直觉的表述方式，而在 C++ 中我们往往习惯使用 `last` 之类的容易引发边界问题的概念
- 稳定：`rec` 语法强制用户思考每个值的下一个状态，编译期提醒用户对各变量进行修改，C++ 则难以做到这一点
- 简洁：`if ... then ... else ...` 语法更紧凑
