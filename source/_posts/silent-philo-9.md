---
title: 绷语言 | 设计哲学 Pt.9 和 SAM
date: 2023-10-02 13:51:18
tags:
- 草稿
---

## SAM 本体

核心思想是额外维护 `endPos` 的等价类和继承关系，包括：

- `link`：等价类之父，也就是比它大一点点的等价类。比如对于 `aab` 加上 `a` 得到 `aaba`，`aaba` 的 `endPos` 是 `{4}`；`link` 则是 `a`，其 `endPos` 为 `{1, 4}`
- `len`：加新节点时需要计算其「等价类之父」，计算过程需要用 `len` 来判断，在下面讲解

### 存储 len 的动机

例如对于 `aba` 加上 `b`：

- `abab` 的 `endPos` 是 `{4}`
- `aba` 的 `link` 是 `a`
- 对 `a` 转移 `b` 得 `ab`
- `ab` 的 `endPos` 是 `{2, 4}`，没有发生缩减
- `ab` 是 `abab` 的 `link`

但对于 `aaba` 加上 `b`：

- `aabab` 的 `endPos` 是 `{5}`
- `aaba` 的 `link` 是 `a`
- 对 `a` 转移 `b` 得 `aab`
- `aab` 的 `endPos` 是 `{3}`，相对 `ab` 的 `endPos = {3, 5}` 发生了缩减
- `aab` 不是 `aabab` 的 `link`。

判定是否发生缩减可以比较节点对应最长字符串的长度，例如 `len aab = 3 > 2 = len a + 1`，可知 `a` 转移到 `aab` 时 `endPos` 发生了缩减，这时候必须复制 `aab` 节点以维持继承关系。

### 绷语言实现

```
SAMNode : Type
samNode = (link : Int) -> (len : Int) -> (next : Map Char Int) -> SAMNode

SAM : Type
sam = (nodes : [SAMNode]) -> (last: Int) -> SAM

init : SAM
init = sam [samNode -1 0 empty] 0

.extend : SAM -> Char -> SAM
.extend (sam nodes last) ch =
  curr = len nodes

  // add node and connections
  nodes ::= samNode 0 (nodes[last].len + 1) empty
  conn nodes state =
    if state == -1 then (nodes, state) else
    case nodes[state].next[ch] of
      some x => (nodes, state)
      none => conn (nodes[state].next[ch] <- curr) nodes[state].link
  (nodes, state) = conn nodes last

  // case 1, no duplicate
  if state == -1 then sam nodes curr else

  // case 2, duplicate but contains
  next = nodes[state].next[ch]
  if nodes[state].len + 1 == nodes[next].len
    then sam (nodes[curr].link <- q) curr else

  // case 3, duplicate and shrink
  clone = len nodes
  nodes ::= samNode nodes[next].link (nodes[state].len + 1) nodes[next].next
  move nodes state =
    if state == -1 then nodes else
    case nodes[state].next[ch] of
      some x if x == next => move (nodes[state].next[ch] <- clone) nodes[state].link
      none => nodes
  nodes = move nodes state
  sam (nodes[next].link <- clone and [curr].link <- clone) curr
```

### CPP 实现

```cpp
struct sam {
  struct sam_node {
    i64 link;
    i64 len;
    std::map<char, i64> next;
  };
  sam_node nodes[N * 2];
  i64 sz;
  i64 last;
  void init() {
    nodes[0].link = -1;
    nodes[0].len = 0;
    sz++;
    last = 0;
  }
  void extend(char ch) {
    i64 curr = sz++;

    // add nodes and connections
    nodes[curr].link = 0;
    nodes[curr].len = nodes[last].len + 1;
    i64 state = last;
    while (state != -1 && !nodes[state].next.count(ch)) {
      nodes[state].next[ch] = curr;
      state = nodes[state].link;
    }
    if (state != -1) {
      i64 next = nodes[state].next[ch];

      // duplicate but contains
      if (nodes[state].len + 1 == nodes[next].len) {
        nodes[curr].link = next;
      } else {

        // duplicate and shrink
        i64 clone = sz++;
        nodes[clone].link = nodes[next].link;
        nodes[clone].len = nodes[state].len + 1;
        nodes[clone].next = nodes[next].next;
        while (state != -1 && nodes[state].next[ch] == next) {
          nodes[state].next[ch] = clone;
          state = nodes[state].link;
        }
        nodes[next].link = clone;
        nodes[curr].link = clone;
      }
    }
    last = curr;
  }
} s;
```

## 子串计数

已知有两种方法可以统计某一状态 `v` 对应的子串数目：

- 标记每个非 `clone` 节点的 `cnt` 为 `1`，根据 `len` 降序遍历所有状态，令 `cnt[link[v]] += cnt[v]`
- 标记每个结束结点（从 `last` 循环调用 `link`）的 `cnt` 为 `1`，使用 DFS 求出 `v` 到结束结点的不同路径条数即为 `cnt[v]`

我们采用第二种方法，因为第二种方法不需要修改 `extend` 逻辑。

### 绷语言实现

```
.cnt : SAM -> [Int]
.cnt (sam nodes last) =

  // make cnt of terminating nodes 1
  init cnt state =
    if state == -1 then cnt else
    init (cnt[state] <- 1) nodes[state].link
  cnt = init [0 for len nodes] last

  // dfs path count
  dfs cnt vis x =
    vis = vis[x] <- true
    fold nodes[x].next (cnt, vis) ((cnt, vis) => (ch, next) =>
      (cnt, vis) = if vis[next] then (cnt, vis) else dfs cnt vis next
      (cnt[x] <- cnt[x] + cnt[next], vis))
  (dfs cnt [false for len nodes] 0)[0]
```

### C++ 实现

```
i64 cnt[N * 2], vis[N * 2];

void dfs(i64 x) {
  vis[x] = 1;
  for (auto i : s.nodes[x].next) {
    if (!vis[i.second]) {
      dfs(i.second);
    }
    cnt[x] += cnt[i.second];
  }
}

void count() {
  i64 state = s.last;
  while (state != -1) {
    cnt[state] = 1;
    state = s.nodes[state].link;
  }
  dfs(0);
}
```

## CF 846 G. (*2400)

[原题](https://codeforces.com/contest/1780/problem/G)

计算出 `cnt` 和 `len` 后，只需要找 `[nodes[x.link].len + 1, x.len]` 中有几个长度是 `cnt` 的因数即可。

### 绷语言实现

```
firstFactor : Int -> [Int]
firstFactor n =
  fold [2 to n] [0 for n] (arr => i =>
    if arr[i] > 0 then arr else
    fold [i to n step i] arr (arr => j =>
      arr[j] <- i))

factor : Int -> [(Int, Int)]
factor n =
  ff = firstFactor (1e6 + 4)
  genFactor arr rem =
    if rem == 1 then arr else
    fac = ff rem
    if len arr == 0 || arr[-1][0] != fac
    then genFactor (arr :: (fac, 1)) (rem / fac)
    else genFactor (arr[-1][1] +<- 1) (rem / fac)
  genFactor [] n

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

main : Void
main =
  n, str = input, input
  s = fold str init (s => (id, ch) => s.extend ch)
  cnt = s.cnt
  res = fold s.nodes 0 (res => (id, node) =>
    if node.len == 0 then res else
    l = s.nodes[node.link].len + 1
    r = node.len
    mul = foldFactor cnt[id] 0 (fac <= r) (res => fac =>
      if fac >= l && fac <= r then res + 1 else res))
    res + mul * cnt[id]
  print res
```

其中 `firstFactor` 需要被记忆。暂未确定是否可以自动推断是否记忆化一个变量，而且我怀疑记忆化和数组之间可以提取共性。

同时，`foldFactor` 理论上可以用 Monad 改写成得更美丽一些。

使用函数式编程的一大好处是能强制让用户明白一个函数操作什么数据，这样数据的更新链条不会混在一起。这也方便后续制作算法可视化工具，如果对 C++ 代码做可视化可能只是乱七八糟的修改时序，但用函数式编程则能看到树状、清晰的数据流。

### C++ 实现

```cpp
i64 ff[N];
std::vector<std::pair<i64, i64>> factor;

void get_ff() {
  for (i64 i = 2; i < N; i++) {
    if (ff[i] == 0) {
      for (i64 j = i; j < N; j += i) {
        ff[j] = i;
      }
    }
  }
}

void get_factor(i64 n) {
  factor.clear();
  while (n > 1) {
    i64 fac = ff[n];
    if (factor.empty() || factor.back().first != fac) {
      factor.push_back({fac, 1});
    } else {
      factor.back().second += 1;
    }
    n /= fac;
  }
}

i64 res, l, r;
void fold_factor(i64 base, i64 facID) {
  if (facID == factor.size()) {
    if (l <= base) {
      res++;
    }
  } else {
    auto pair = factor[facID];
    for (int i = 0; i <= pair.second; i++) {
      if (base > r) {
        break;
      }
      fold_factor(base, facID + 1);
      base *= pair.first;
    }
  }
}

int main() {
  std::ios::sync_with_stdio(false);
  std::cin.tie(nullptr);
  std::cout.tie(nullptr);
  s.init();
  i64 n;
  std::cin >> n;
  std::string str;
  std::cin >> str;
  for (auto ch : str) {
    s.extend(ch);
  }
  count();
  get_ff();
  i64 ans = 0;
  for (i64 i = 1; i < s.sz; i++) {
    l = s.nodes[s.nodes[i].link].len + 1;
    r = s.nodes[i].len;
    get_factor(cnt[i]);
    res = 0;
    fold_factor(1, 0);
    ans += res * cnt[i];
  }
  std::cout << ans << std::endl;
  return 0;
}
```
