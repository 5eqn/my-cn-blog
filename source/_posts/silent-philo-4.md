---
title: 绷语言 | 设计哲学 Pt.4 和线段树
date: 2023-09-29 23:36:31
tags:
- 草稿
---

这一次对绷语言的特性进行了大改，会在下面详细阐述。

## CF 737 D. (*2200)

[原题](https://codeforces.com/contest/1557/problem/D)

### C++

```cpp
#include <algorithm>
#include <iostream>
#include <utility>
#include <vector>

namespace seg {
const int N = 6e5 + 4;
int n;
std::pair<int, int> a[N << 2];
std::pair<int, int> t[N << 2];
inline int mid(int l, int r) { return l + (r - l) / 2; }
inline void pull(int p) { a[p] = std::max(a[p << 1], a[p << 1 | 1]); }
inline void build() {
  std::fill(a, a + (n << 2), std::pair<int, int>(0, -1));
  std::fill(t, t + (n << 2), std::pair<int, int>(0, -1));
}
inline void push(int l, int r, int p) {
  if (r - l != 1) {
    int m = mid(l, r);
    a[p << 1] = std::max(a[p << 1], t[p]);
    a[p << 1 | 1] = std::max(a[p << 1 | 1], t[p]);
    t[p << 1] = std::max(t[p << 1], t[p]);
    t[p << 1 | 1] = std::max(t[p << 1 | 1], t[p]);
  }
  t[p] = {0, -1};
}
inline void add(int lq, int rq, std::pair<int, int> b, int l = 0, int r = n,
                int p = 1) {
  if (r <= l)
    return;
  push(l, r, p);
  if (lq <= l && rq >= r) {
    a[p] = std::max(a[p], b);
    t[p] = std::max(t[p], b);
  } else {
    int m = mid(l, r);
    if (lq < m)
      add(lq, rq, b, l, m, p << 1);
    if (rq > m)
      add(lq, rq, b, m, r, p << 1 | 1);
    pull(p);
  }
}
inline std::pair<int, int> query(int lq, int rq, int l = 0, int r = n,
                                 int p = 1) {
  if (r <= l)
    return {0, -1};
  std::pair<int, int> f = {0, -1};
  push(l, r, p);
  if (lq <= l && rq >= r) {
    f = a[p];
  } else {
    int m = mid(l, r);
    if (lq < m)
      f = std::max(f, query(lq, rq, l, m, p << 1));
    if (rq > m)
      f = std::max(f, query(lq, rq, m, r, p << 1 | 1));
  }
  return f;
}
} // namespace seg

const int N = 3e5 + 4;
std::vector<std::pair<int, int>> region[N];
std::vector<int> bounds;
std::vector<int> prev;
int vis[N];

int disc(int x) {
  return std::upper_bound(bounds.begin(), bounds.end(), x) - bounds.begin();
}

int main() {
  std::ios::sync_with_stdio(false);
  std::cin.tie(nullptr);
  std::cout.tie(nullptr);

  // read input
  int n, m;
  std::cin >> n >> m;
  for (int i = 0; i < m; i++) {
    int j, l, r;
    std::cin >> j >> l >> r;
    region[j - 1].push_back({l, r});
    bounds.push_back(l);
    bounds.push_back(r);
  }

  // make discrete
  std::sort(bounds.begin(), bounds.end());
  bounds.erase(std::unique(bounds.begin(), bounds.end()), bounds.end());
  for (int i = 0; i < n; i++) {
    for (auto &it : region[i]) {
      it.first = disc(it.first);
      it.second = disc(it.second);
    }
  }

  // build seg tree
  seg::n = bounds.size() + 2;
  seg::build();

  // dp on seg tree
  for (int i = 0; i < n; i++) {
    std::pair<int, int> last = {0, -1};
    for (auto it : region[i]) {
      auto res = seg::query(it.first, it.second + 1);
      if (i == 0 && res.second != -1) {
        std::cout << it.first << ' ' << it.second << '\n';
        std::cout << std::max(last, last).second << '\n';
        return 0;
      }
      last = std::max(last, res);
    }
    for (auto it : region[i]) {
      seg::add(it.first, it.second + 1, {last.first + 1, i});
    }
    prev.push_back(last.second);
  }

  // output result
  auto res = seg::query(0, seg::n);
  int ptr = res.second;
  while (ptr >= 0) {
    vis[ptr] = 1;
    ptr = prev[ptr];
  }
  std::cout << n - res.first << '\n';
  for (int i = 0; i < n; i++) {
    if (!vis[i]) {
      std::cout << i + 1 << ' ';
    }
  }
  std::cout << '\n';
  return 0;
}
```

### 绷语言

```
Reg: Type
reg: (l: Int) -> (r: Int) -> Reg

sep: Reg -> Reg -> Bool
sep(a, b) = a.r <= a.l || b.r <= b.l || a.r <= b.l || b.r <= a.l

has: Reg -> Reg -> Bool
has(large, small) = large.l <= small.l && small.r <= large.r

mid: Reg -> Int
mid(reg(l, r)) = l + (r - l) / 2

left: Reg -> Reg
left(x@reg(l, r)) = reg(l, x.mid)

right: Reg -> Reg
right(x@reg(l, r)) = reg(x.mid, r)

BinaryOp: Type
BinaryOp(T) = T -> T -> T

Seg: Type
seg: (~: BinaryOp(Int, Int)) -> 
     (n: Int) -> (tree: [Int, Int]) -> Seg

build: BinaryOp (Int, Int), Int, (Int, Int) -> Seg
build(~, n, base) = seg ~ n [base for 4n]

push: Seg -> Int -> Seg
push(s@seg(~, n, tree))(p) = s
  mut _.tree[2p] ~= tree[p]
  mut _.tree[2p + 1] ~= tree[p]

pull: Seg -> Int -> Seg
pull(s@seg(~, n, tree))(p) = s
  mut _.tree[p] = tree[2p] ~ tree[2p + 1]

setF: Seg -> (Int, Int), Reg, Reg, Int -> Seg
setF(s@seg(~, n, tree))(x, query, focus, p) =
  if query.sep(focus) then s else
  if query.has(focus) then s mut _.tree[p] ~= value else
  s.push(p).setF(x, query, focus.left).setF(x, query, focus.right).pull(p)

set: Seg -> (Int, Int), Reg -> Seg
set(s@seg(_, n, _))(x, query) = setF(s)(x, query, reg(0, n), 1)
  
getF: Seg -> Reg, Reg, Int -> Int, Int
getF(s@seg(~, n, tree))(query, focus, p) =
  if query.sep(focus) then 0, -1 else
  if query.has(focus) then tree[p] else
  let sp = s.push(p) in sp.getF(query, focus.left) ~ sp.getF(query, focus.right)

get: Seg -> Reg -> (Int, Int)
get(s@seg(_, n, _))(query) = getF(s)(query, reg(0, n), 1)

main: Int
main = 
  // make discrete
  let n, m = input, input
  let regs, ids, rem = [[] for n], [], m rec
    if rem == 0 then nope else
    let i, l, r = input, input, input + 1
    (regs mut _[i - 1] ::= l, r), ids :: l :: r, rem - 1
    mut regs, ids.sort(<).unique, 0
    mut regs.map(pair => pair.map(ids.find)), ids, 0
  // dp on seg tree
  let prev, seg, curr = [], build(max, ids.length, (0, -1)), 0 rec
    if curr == n then nope else
    let res = regs[curr].fold((0, -1), (reg => res => max(res, seg.get(reg))))
    let new_res = reg(res[0] + 1, curr)
    let new_seg = regs[curr].fold(seg, (reg => seg => seg.set(new_res, reg)))
    prev :: res[1], new_seg, curr + 1
  // output result
  let res = seg.get(reg(0, seg.n))
  let vis, curr = [0 for n], res[1] rec
    if curr == -1 then nope else
    vis mut _[curr] = 1, prev[curr]
  run print(n - res[0])
  run for i in n
    if vis[i] then null else print(i + 1)
  0
```

### 特性说明

本次进行了一些大改动，例如：

- 为区分类型变量和值变量，提倡类型变量名采用 PascalCase，值变量采用 camelCase
- 为遵循编程语言建模人类认知的原则，鼓励用户把所有「自然的认知过程」提取成一个单独的函数
- 为方便用户想象函数的基本结构，强制要求对单独的函数进行独立类型标注
- 为消除柯里化的函数给朴素直觉带来的不良影响，鼓励用户以模式匹配形式定义函数
- 为统一「编辑」意图相关的语法，将 Lens 内置到 `mut`

目前来看，绷语言的设计哲学很清晰：让用户直接把思维中的「函数」描述出来。只是为实现这点，绷语言相比传统函数式编程语言做出了以下一点修改：

- 允许函数形成自环（自己更新自己，使用 `mut` 表示单次更新，使用 `rec` 表示循环更新）
