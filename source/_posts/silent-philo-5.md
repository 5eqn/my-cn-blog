---
title: 绷语言 | 设计哲学 Pt.5
date: 2023-09-30 14:29:59
tags:
- PL
- 绷语言
- 技术性
---

## CF 846 B. (*1100)

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
main: Int
```
