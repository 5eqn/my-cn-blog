---
title: 绷语言 | 设计哲学 Pt.5 和一点元组语法迷思
date: 2023-09-30 15:37:45
tags:
- PL
- 绷语言
- 技术性
---

## CF 846 D. (*1800)

[原题](https://codeforces.com/contest/1780/problem/D)

```cpp
#include <iostream>

int main() {
  int t;
  std::cin >> t;
  while (t--) {
    int cnt, res = 0, last = -1, next_try = 0;
    while (true) {
      std::cin >> cnt;
      if (cnt == 0) {
        break;
      }
      next_try = 1;
      if (last != -1) {
        next_try += (1 << (cnt - last + 1)) - 1;
        last -= 1;
      } else {
        last = cnt;
      }
      if (last == 0) {
        res += next_try - 1;
        break;
      }
      std::cout << "- " << next_try << std::endl;
      res += next_try;
    }
    std::cout << "! " << res << std::endl;
  }
  return 0;
}
```
