---
title: 绷语言 | 设计哲学 Pt.6 和不可变策略的好处
date: 2023-09-30 15:37:45
tags:
- 草稿
---

## CF 846 D. (*1800)

[原题](https://codeforces.com/contest/1780/problem/D)

由于选择减的东西的时候只能在 `1` 至 `2 ** cnt - 1` 之间选择，而选择非 `1` 数字带来的后果太多，优先考虑减 `1`。

减 `1` 发现多出的 `1` 的数目直接由数字二进制表示中最小位 `1` 的位置决定，故解决。

### C++

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

### 绷语言

- `cnt` 表示上次请求得到的二进制表示中 `1` 的数量
- `acc` 表示目前已累积的结果大小
- `ptr` 表示可以减掉第几位（从 `0` 开始，如果 `ptr == cnt` 说明会减到 `-1`，故停止）

```
main : Void
main =
  let t = input
  run for t
    let (cnt, acc, ptr) = (input, 0, 0) rec
      if ptr == cnt then nope else
      let value = pow 2 ptr
      run print `- {value}`
      let new_cnt = input
      (new_cnt, acc + value, ptr + new_cnt - cnt + 1)
    print `! {acc + pow 2 ptr - 1}`
```

### 使用绷语言思路重写 C++ 程序

C++ 中没有绷语言对变量可变性的限制，变量在一个循环内是错开修改的，而绷语言强制同步修改，这会降低认知压力。然而，在算法竞赛中，我们往往难以使用绷语言。若能使用绷语言思路写 C++ 程序，会产生怎样的效果呢？

```cpp
#include <iostream>

int main() {
  int t;
  std::cin >> t;
  while (t--) {
    int cnt, acc = 0, ptr = 0;
    std::cin >> cnt;
    while (true) {
      if (ptr == cnt) {
        break;
      }
      int value = 1 << ptr;
      std::cout << "- " << value << std::endl;
      int new_cnt;
      std::cin >> new_cnt;
      acc += value;
      ptr += new_cnt - cnt + 1;
      cnt = new_cnt;
    }
    std::cout << "! " << acc + (1 << ptr) - 1 << std::endl;
  }
  return 0;
}
```

变量的意义变得更清晰了！代码中的选择分支也少了。
