---
title: 绷语言 | 设计哲学 Pt.8 和状压容斥
date: 2023-10-01 13:10:08
tags:
- 草稿
---

## CF 846 F. (*2300)

[原题](https://codeforces.com/contest/1780/problem/F)

直接枚举选择情况显然 $O(n^3)$，考虑使用一些数学和预处理。

注意到有取最大和最小，因此考虑排序。排序后只需考虑区间，降为 $O(n^2)$。

对数字 `a[i]`，其因数的数量较少，设为 $k$。对每个因数维护 `a[i]` 之前数字中不互质的数字数量，及这些数字编号之和，即可通过容斥计算出和 `a[i]` 不互质的数字数量和编号和，进而计算出答案。

这题我没能独立想出来，第一次见这种容斥的用法！我当时还以为可以用某种具有 min/max 性质的东西来维护，但又确实和线段树不太一样……

### 绷语言

```
factorList : Int -> [[Int]]
factorList n =
  let (ls, vis, ptr) = ([[] for n], [false for n], 2) rec
    if ptr == n then nope else
    if vis ptr then (ls, vis, ptr + 1) else
    let (ls, vis, next) = (ls, vis, ptr) rec
      (ls[next] <- ls[next] :: ptr, vis[next] <- true, next + ptr)
    (ls, vis, ptr + 1)
    
main : Void
main =
  let n = input
  let a = [input for n] mut
    sort a
  let f = factorList (3e5 + 4)
  let maskToNum aID mask =
    let (num, par, maskRest, digit) = (1, 1, mask, 0) rec
      if maskRest == 0 then nope else
      if maskRest % 2 == 1
      then (num * f[a[aID]][digit], -par, maskRest / 2, digit + 1)
      else (num, par, maskRest / 2, digit + 1)
    num
  let (res, cnt, sum, aID) = (0, [0 for n], [0 for n], 0) rec
    if aID == n then nope else
    let maskCnt = 2 ** len f[a[aID]]
    let (cntTot, sumTot, mask) = (0, 0, 0) rec
      if mask == maskCnt then nope else
      let num = maskToNum aID mask
      (cntTot + cnt[num] * par, sumTot + sum[num] * par, mask + 1)
    let (cnt, sum, mask) = (cnt, sum, 0) rec
      if mask == maskCnt then nope else
      let num = maskToNum aID mask
      (cnt[num] <- cnt[num] + 1, sum[num] <- sum[num] + aID + 1, mask + 1)
    (res + cntTot * aID - sumTot, cnt, sum, aID + 1)
  run print res
```

有些缺点暴露出来：

- 整体自更新机制 `rec` 暴露了大量无用变量
- 没有 `for` 循环导致只能使用 `nope` 来跳出循环
- 无法实现 `foreach` 以修改数组

我们来做点语法改进！

### 语法改进

首先注意到 `rec` 和尾递归函数等价，这可以解决暴露无用变量的问题。原先写阶乘函数是：

```
let n = input
let (res, idx) = (1, 1) rec
  if idx == n then nope else
  (res * idx, idx + 1)
```

使用尾递归函数则可以写成：

```
let n = input
let fact = (res, idx) =>
  if idx == n then res else
  fact (res * idx, idx + 1)
let res = fact (1, 1)
```

但这无疑会使得语法变得更冗长，我们暂时不尝试解决这个问题。

注意到这会使得 `fold` 更合群。假设我们需要从一个数组中筛选出所有偶数并除以二，但想采用和 `map` 比较接近的格式。这时候我们需要的是 `fold`：

```
let n = input
let arr = [input for n]
let filt = fold arr [] (res => e =>
  if e % 2 == 0 then res :: e / 2 else res)
```

尝试一下用这种思路重写现有程序：

```
factorList : Int -> [[Int]]
factorList n =
  fold [2 to n] ([[] for n], [false for n]) ((ls, vis) => num =>
    if vis num then (ls, vis) else
    fold [num to n step num] (ls, vis) ((ls, vis) => next =>
      (ls[next] <- ls[next] :: num, vis[next] <- true)
    
main : Void
main =
  let n = input
  let a = sort [input for n]
  let f = factorList (3e5 + 4)
  let foldMask aID init fun =
    let maskCnt = 2 ** len f[a[aID]]
    fold [0 to maskCnt] init (res => mask =>
      let getInfo num par mask digit =
        if mask == 0 then (num, par) else
        if mask % 2 == 1
        then getInfo (num * f[a[aID]][digit]) -par (mask / 2) (digit + 1)
        else getInfo num par (mask / 2) (digit + 1)
      let (num, par) = getInfo 1 1 mask 0
      fun res (num, par)
  let (res, _, _) = fold [0 to n] (0, [0 for n], [0 for n]) (
    (res, cnt, sum) => aID =>
      let (cntTot, sumTot) = foldMask aID (0, 0) ((c, s) => (num, par) =>
        (c + cnt[num] * par, s + sum[num] * par))
      let (cnt, sum) = foldMask aID (cnt, sum) ((cnt, sum) => (num, _) =>
        (cnt[num] <- cnt[num] + 1, sum[num] <- sum[num] + aID + 1))
      getRes (res + cntTot * aID - sumTot) cnt sum (aID + 1))
  run print res
```

变得更理想了！看来还是原始的 `map` `fold` 系列好用！

### C++

```cpp
#include <algorithm>
#include <iostream>
#include <vector>

using i64 = long long;
const i64 N = 3e5 + 4;

i64 a[N], vis[N], cnt[N], sum[N];
std::vector<i64> f[N];

int main() {
  std::ios::sync_with_stdio(false);
  std::cin.tie(nullptr);
  std::cout.tie(nullptr);
  i64 n;
  std::cin >> n;
  for (i64 i = 0; i < n; i++) {
    std::cin >> a[i];
  }
  std::sort(a, a + n);
  for (i64 i = 2; i < N; i++) {
    if (!vis[i]) {
      for (i64 j = i; j < N; j += i) {
        vis[j] = 1;
        f[j].push_back(i);
      }
    }
  }
  i64 res = 0;
  for (i64 i = 0; i < n; i++) {
    i64 maskCnt = 1 << (f[a[i]].size());
    i64 cntTot = 0, sumTot = 0;
    for (i64 mask = 0; mask < maskCnt; mask++) {
      i64 maskRest = mask;
      i64 num = 1, par = 1;
      for (i64 digit = 0; maskRest > 0; digit++, maskRest /= 2) {
        if (maskRest % 2 == 1) {
          num *= f[a[i]][digit];
          par = -par;
        }
      }
      cntTot += cnt[num] * par;
      sumTot += sum[num] * par;
    }
    for (i64 mask = 0; mask < maskCnt; mask++) {
      i64 maskRest = mask;
      i64 num = 1;
      for (i64 digit = 0; maskRest > 0; digit++, maskRest /= 2) {
        if (maskRest % 2 == 1) {
          num *= f[a[i]][digit];
        }
      }
      cnt[num] += 1;
      sum[num] += i + 1;
    }
    res += cntTot * i - sumTot;
  }
  std::cout << res << std::endl;
  return 0;
}
```
