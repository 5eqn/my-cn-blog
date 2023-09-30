---
title: 绷语言 | 设计哲学 Pt.7 和多变量谜题
date: 2023-09-30 18:33:49
tags:
---

## CF 846 E. (*2400)

考虑每个除数即可，仅考虑结果不同（左右端点被分成的段数不一样）的情况。

[原题](https://codeforces.com/contest/1780/problem/E)

尝试直接使用绷语言写代码。

### 绷语言

循环变量名注释：

- `acc`：当前累积结果
- `len`：当前考虑的除数大小
- `cntL`：当前左端点前被分成的段数
- `cntR`：当前右端点前被分成的段数

循环体内变量名注释：

- `lenR`：第一个使新 `cntR` 减至少一的端点
- `lenL`：第一个使新 `cntL` 减至少一的端点

特殊语法：

- `/-`：向下取整的相除
- `/+`：向上取整的相除

```
main : Void
main =
  let t = input
  run for t
    let (l, r) = (input, input)
    if l == r then run print 0 else
    if l + 1 == r then run print 1 else
      let d = (r - l) /- 2
      let (acc, len, cntL, cntR) = (0, d, l /+ d, cntL + 1) rec
        if len == r then nope else
        let lenR = r /- cntR + 1
        let lenL = if cntL == 1 then r else l /+ (cntL - 1)
        (if cntL < cntR then acc + lenR - len else acc, lenL, l /+ lenL, r /- lenL)
      run print (d - 1 + acc)
```

其实如果使 `cntL` 和 `cntR` 每次同步减少一，可以获得更简洁的解法，因为不需要讨论 `cntL` 和 `cntR` 的大小关系，也不用从 `(r - l) /- 2` 开始枚举和强行令 `cntR` 初始值为 `cntL + 1`，以避免 `cntR - cntL >= 2` 的情况。

不论如何，使用绷语言有利于用户形成更清晰的思路，避免 C++ 中容易出现的因变量过多、修改关系过于复杂而导致程序难以被理解的问题。

### C++

其实可以很短，但从绷语言直接翻译过来是这样：

```cpp
#include <algorithm>
#include <iostream>

#define long long long

int main() {
  std::ios::sync_with_stdio(false);
  std::cin.tie(nullptr);
  std::cout.tie(nullptr);
  int t;
  std::cin >> t;
  while (t--) {
    long l, r;
    std::cin >> l >> r;
    long d = (r - l) / 2;
    if (r - l == 0) {
      std::cout << 0 << std::endl;
      continue;
    }
    if (r - l == 1) {
      std::cout << 1 << std::endl;
      continue;
    }
    long acc = 0;
    long len = d;
    long cnt_l = (l - 1) / d + 1;
    long cnt_r = cnt_l + 1;
    while (true) {
      if (len == r) {
        break;
      }
      long len_r = r / cnt_r + 1;
      long len_l;
      if (cnt_l == 1) {
        len_l = r;
      } else {
        len_l = (l - 1) / (cnt_l - 1) + 1;
      }
      if (cnt_l < cnt_r) {
        acc = acc + len_r - len;
      }
      len = len_l;
      cnt_l = (l - 1) / len_l + 1;
      cnt_r = r / len_l;
    }
    std::cout << d - 1 + acc << std::endl;
  }
  return 0;
}
```
