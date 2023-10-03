---
title: 绷语言 | 设计哲学 Pt.A 和因数 DP
date: 2023-10-03 14:37:16
tags:
- 草稿
---

本次题目：[CF Edu. 142 E. (* 2400)](https://codeforces.com/contest/1792/problem/E)

注意到可以对所有因数讨论，但要找到能出现的行的最小行号，则显然需要 DP。

注意到对任意一个因数，可以记忆对所有更小因数的选择，并通过质因数转移。

## C++ 实现

```cpp
#include <algorithm>
#include <iostream>
#include <queue>
#include <vector>

#define dbg(x) std::cout << #x << " = " << x << std::endl

using i64 = long long;

std::vector<std::pair<i64, i64>> factor;

void get_factor(i64 m1, i64 m2) {
  factor.clear();
  for (i64 fac = 2; fac * fac <= m1 || fac * fac <= m2; fac++) {
    while (m1 % fac == 0) {
      if (factor.empty() || factor.back().first != fac) {
        factor.push_back({fac, 1});
      } else {
        factor.back().second += 1;
      }
      m1 /= fac;
    }
    while (m2 % fac == 0) {
      if (factor.empty() || factor.back().first != fac) {
        factor.push_back({fac, 1});
      } else {
        factor.back().second += 1;
      }
      m2 /= fac;
    }
  }
  if (m1 > 1) {
    factor.push_back({m1, 1});
  }
  if (m2 > 1) {
    if (m1 == m2) {
      factor.back().second += 1;
    } else {
      factor.push_back({m2, 1});
    }
  }
}

std::vector<i64> divs;
void dfs_factor(i64 base, i64 facID) {
  if (facID == factor.size()) {
    divs.push_back(base);
  } else {
    auto [fac, cnt] = factor[facID];
    for (int i = 0; i <= cnt; i++) {
      dfs_factor(base, facID + 1);
      base *= fac;
    }
  }
}

int main() {
  std::ios::sync_with_stdio(false);
  std::cin.tie(nullptr);
  std::cout.tie(nullptr);
  i64 t;
  std::cin >> t;
  while (t--) {
    i64 n, m1, m2;
    std::cin >> n >> m1 >> m2;
    divs.clear();
    get_factor(m1, m2);
    dfs_factor(1, 0);
    std::sort(divs.begin(), divs.end());
    std::vector<i64> dp(divs.size(), 0);
    i64 cnt = 0, ans = 0;
    for (int i = 0; i < divs.size(); i++) {
      // dp
      if (divs[i] <= n) {
        dp[i] = divs[i];
      } else {
        for (auto [fac, cnt] : factor) {
          if (divs[i] % fac == 0) {
            auto lb = std::lower_bound(divs.begin(), divs.end(), divs[i] / fac);
            dp[i] = std::max(dp[i], dp[lb - divs.begin()]);
          }
        }
      }
      // transfer result
      i64 row = divs[i] / dp[i];
      if (row <= n) {
        cnt++;
        ans ^= row;
      }
    }
    std::cout << cnt << ' ' << ans << std::endl;
  }
  return 0;
}
```

## 绷语言实现

这题内 C++ 的实现中充斥着大量语义较差的内容。

例如在 `get_factor` 函数中，多次对是否向 `factor` 数组添加元素本质上只是希望所添加的因数能够重叠在一起。如果能把这一性质封装起来，将会更符合语义性。

同时，在对 `m1` 和 `m2` 分别处理时，代码也有重复逻辑。

### 用 Monad 简化程序

注意到上篇博客中我提到：

> 同时，`foldFactor` 理论上可以用 Monad 改写成得更美丽一些。

`foldFactor` 原本是这样，有两层 `fold`：

```
foldFactor : Int -> T -> (Int -> Bool) -> (T -> Int -> Int) -> T
foldFactor num init pred f =
  facList = factor num
  foldRest res base facID =
    if facID == len facList then f res base else
    (fac, cnt) = facList[facID]
    foldSingle res base usingCnt =
      if usingCnt > cnt || pred base then res else
      newRes = foldRest res base (facID + 1)
      foldSingle newRes (base * fac) (usingCnt + 1)
    foldSingle res base 0
  foldRest init 1 0
```

如果只想获得所有除数，可以写成：

```
divs : Int -> [Int]
divs num =
  factor num
    .map ((fac, cnt) => fac ** [0 to cnt])
    .fold [1] (res => next => res * next)
```

其中 `res * next` 可以被语法糖成 `res.bind (i => i * next)`，而 `i * next` 被进一步语法糖成 `next.map (j => i * j)`。

要正确编译这玩意特别考验编译器，暂时我还没想到怎么实现。

### 杂记

这题我先不用绷语言写了，感觉比较累。

最近关于绷语言有几个需要考虑的：

- 是否要引入有语义的类型？例如引入一个 `Ans` 类型表示答案，规定该类型被构造后是线性的，通过写一个 `1 Ans -> T` 的函数并自动织入来模拟仿射。
  - 这样的好处是可以减少程序出错的可能性。当你想要构造出一个「答案」的时候，你不再是令一个名字是 `ans` 的变量为答案（这对编译器来说没有语义，因此它也不可能为你检查答案是否被正确输出），而是构造一个 `Ans` 类型的实例（这对编译器来说有语义，因为 `Ans` 类型的实例是线性的，且用户可以通过修改一个 `1 Ans -> T` 的函数来丰富 `Ans` 类型的语义。
  - 然而，要获取一个线性实例，一定会需要 `bind`，这将涉及 Effects。
- 是否要引入 Effects？Effects 能否用于简化变量修改？能否配合线性资源建模？能否和自动记忆化结合？能否和编译期代码织入结合？目前使用 Effects 的最佳实践（语法，编译器实现）是什么样的？
- 有没有希望结合 Recursion Schemes 实现一种新的递归语法？
- 如何避免申请 $O(n)$ 的内存来模拟依照函数生成的数组？如何支持各种复杂的 `map`、`bind` 操作？这样做是否有必要？是否有更好的替代方法？

我计划考虑一段时间这些问题，搜集一些相关资料，再尝试修改绷语言的特性。
