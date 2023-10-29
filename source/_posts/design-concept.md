---
title: 杂谈 | 原来你也会前端
date: 2023-10-25 13:16:20
tags:
- 草稿
---

作为一种动物，人很自然地拥有「反射」：

火代表危险。

用火烤肉，肉就会变熟。

你的舍友在打游戏，Ta 跟你说 Ta 血残了，你知道他手机上显示的血条一定是个窄而红的矩形。

如果你认为第三条很自然，那么恭喜你：原来你也会前端！

## 规范化表述上述内容

所有以「学术上」开头的句子如果看不懂请忽略，但你需要知道这样的句子实际上表达的意思跟前面大白话表述一模一样。

「x 代表的东西」中，「x」的类型是「自然元素」，「x 代表的东西」的类型是「信号」。学术上，我们称「代表」的类型是从自然元素到信号的「函数」，「x」是「代表」这个函数的「形式参数」。翻译成编程语言就是：

```
represent : Element -> Signal
```

火代表的东西是危险。学术上，我们称「火」是「代表」这个函数的「实际参数」，以火为实际参数「调用」「代表」这个函数得到的「值」是危险信号。翻译成编程语言就是：

```
represent Fire = Danger
```

「烤 x 得到的东西」中，「x」的类型是「食物」，「烤 x 得到的东西」的类型也是「食物」。

注意：烤一个食物，被烤的旧食物将被烤好的新食物「取代」。学术上，我们称被烤的食物是一个「一重参数」，或者「线性参数」。

```
bake : 1 Food -> Food
```

烤肉得到的东西是熟肉。翻译成编程语言就是：

```
bake Meat = CookedMeat
```

「渲染 x 得到的东西」中，「x」的类型是「血量」，「渲染 x 得到的东西」的类型是「组件」。翻译成编程语言就是：

```
render : HP -> Widget
```

渲染低血量得到的东西是窄而红的矩形。翻译成编程语言就是：

```
render LowHP = ThinAndRedBox
```

## 但是前端不止这些……

有趣的部分要来了！

请你先访问[这个网站](https://dccxi.com/trust/)玩一会，对决完 5 名 NPC 对手就行（这大概需要花费 5 分钟时间），这对理解后面的内容有帮助。

![游戏截图](game.png)

### 你的总分

假设你知道你的总分是 x，你应当能立刻反应过来「总分文本框」会显示什么。

正是「你的总分：x」这些文本。翻译成编程语言就是：

```
render : Score -> Widget
render x =
  Text
    text = "你的总分：" + x
```

### 欺骗？合作？

你现在的总分是 x，且你知道对面会合作。现在你点了合作，你应当能立刻反应过来你现在的总分被什么「取代」。

正是「x + 2」。翻译成编程语言就是：

```
cooperate : 1 Score -> Score
cooperate x = x + 2
```

还记得这个 1 是用来干什么的吗？如果不记得，请往回翻到烤肉的例子。

### 组合

我们希望页面是通过一个按钮来触发合作，所以可以改写渲染函数，使其渲染一个「列」，列里面有「文本框」和「按钮」，指定按钮的文本是「合作」，被按下之后执行 `cooperate` 函数。翻译成编程语言就是：

```
cooperate : 1 Score -> Score
cooperate x = x + 2

render : Score -> Widget
render x = 
  Column
    Text
      text = "你的总分：" + x
    Button
      text = "合作"
      onTap = cooperate
```

为简便起见，可以写成：

```
render : Score -> Widget
render x = 
  Column
    Text
      text = "你的总分：" + x
    Button
      text = "合作"
      onTap = 1 score => score + 2
```

那么我们也可以很简单地加上「欺骗」按钮：

```
render : Score -> Widget
render x =
  Column
    Text
      text = "你的总分：" + x
    Button
      text = "合作"
      onTap = 1 score => score + 2
    Button
      text = "欺骗"
      onTap = 1 score => score + 3
```

至此，你已经理解了基础的前端写法。后面是我自由发挥的内容，虽然已经尽可能通俗化表述，但不保证没有编程经验的人能看懂。

## 更丰富的状态

目前我们的状态只有一个「总分」，但显然在上面的游戏中，状态不止一个总分。假设现在有一个「退出」按钮，可以切换「是否显示页面」。

我们的状态将有三个字段，一个是「一重凭证」（线性类型系统要求加入这玩意，我暂时难以通俗化解释，但你可以尝试感受其必要性）；一个是「总分」，类型是整数；一个是「是否显示」，类型是布尔（真或假）。翻译成编程语言就是：

```
data State
  tok : 1 Tok
  score : Int
  visible : Bool
```

那么合作可以写成：

```
cooperate : 1 State -> State
cooperate { tok, score, visible } =
  { tok, score + 2, visible }
```

但假设我们有另外一种 `State`：

```
data State'
  tok : 1 Tok
  score : Int
  scoreLeft : Int
  scoreRight : Int
  intent : List Intent
```

为了这样的 `State'`，难道要重写 `cooperate` 函数？哪里出了问题？

问题在于，我们错误地指定了 `cooperate` 的类型是 `1 State -> State`，因此硬编码了 `cooperate` 依赖于 `State` 中的所有字段。我们需要放宽这个类型限制，把 `State` 替换成「有 `score` 字段的类型」，就能更通用了：

```
cooperate { score .. } = { score + 2 .. }
```

学术上，这被称为 Row Polymorphism。遗憾的是，目前绝大多数语言 / 引擎，例如 Flutter，不支持这一特性。

### 页面实现

状态模型：

```
data State
  tok : 1 Tok
  score : Int
  visible : Bool
```

初值：

```
initState : 1 Tok -> State
initState t =
  State
    tok = t
    score = 0
    visible = True
```

渲染函数：

```
render : 1 State -> State
render st =
  case st.visible of
    False => Nothing
    True =>
      Column
        Text
          text = "你的总分：" + st.score
        Button
          text = "合作"
          onTap = 1 { score .. } => { score + 2 .. }
        Button
          text = "欺骗"
          onTap = 1 { score .. } => { score + 3 .. }
        Button
          text = "退出"
          onTap = 1 { visible .. } => { False .. }
```

## 异步

现在你希望能维护对方的意图。对方意图是一个布尔值，为真表示合作，为假表示欺骗：

```
data State
  tok : 1 Tok
  score : Int
  visible : Bool
  coop : Bool
```

但你需要从其他服务器拉取这个意图。考虑到网速有限，你希望在点击「合作」或「欺骗」后，发生的事情是：

- 从服务器拉取对方意图
- 等待，直到收到结果
- 根据结果计算自己的总分，记录对方意图

因此你可能会想实现成：

```
cooperate { score, coop .. } =
  coop' = fetch "server_url"
  case coop' of 
    False => { score - 1, False .. }
    True => { score + 2, True .. }
```

但这里有一个严重的问题：`cooperate` 的 `State` 参数是会被取代的，但取代过程需要很长的时间，在这段时间中 `State` 参数会直接被锁住，不能被使用。

如果把 `cooperate` 看成两次变化呢？一次是 `hitCooperate`，点击之后先发送请求，发完之后不等回复，只告诉对方「如果得到结果 `coop'`，在下一帧用 `doCooperate coop'` 改变状态」；一次是 `doCooperate`，根据已经获得的对方意图结算总分：

```
hitCooperate st =
  fetch "server_url" (coop' =>
    runNextFrame (1 st => doCooperate coop' st)
  )
  st

doCooperate coop' { score, coop .. } =
  case coop' of 
    False => { score - 1, False .. }
    True => { score + 2, True .. }
```

这样，在等请求回复的时候 `State` 可以发生变化。

### 写法简化

`fetch` 和 `runNextFrame` 后面都是回调函数，即「得到结果后回来调用」。考虑合并这两个函数为 `fetchAndRun`：

```
hitCooperate st =
  fetchAndRun "server_url" ((coop', 1 st) =>
    doCooperate coop' st
  )
  st
```

上面的写法还可以简化。使用 `<-` 代表经过一层回调：

```
cooperate st =
  (coop', 1 { score, coop .. }) <- fetchAndRun "server_url"; st
  case coop' of 
    False => { score - 1, False .. }
    True => { score + 2, True .. }
```

### 页面实现

状态模型：

```
data State
  tok : 1 Tok
  score : Int
  visible : Bool
  coop : Bool
```

初值：

```
initState : 1 Tok -> State
initState t =
  State
    tok = t
    score = 0
    visible = True
    coop = True
```

分数计算，第一个参数是你是否合作，第二个参数是对面是否合作：

```
delta : Bool -> Bool -> Int
delta True True = 2
delta True False = -1
delta False True = 3
delta False False = 0
```

渲染函数：

```
render : 1 State -> State
render st =
  case st.visible of
    False => Nothing
    True =>
      Column
        Text
          text = "你的总分：" + st.score
        Button
          text = "合作"
          onTap = 1 st =>
            (coop', { score, coop .. }) <- fetchAndRun "server_url"
            { score + delta True coop', coop' .. }
        Button
          text = "欺骗"
          onTap = 1 st =>
            (coop', { score, coop .. }) <- fetchAndRun "server_url"
            { score + delta False coop', coop' .. }
        StickFigure
          -- 显示火柴人上次是否合作
          coop = st.coop
        Button
          text = "退出"
          onTap = 1 { visible .. } => { False .. }
```

## 动画

TODO

## 补充内容

### 例子：计数器

状态模型：

```
data State
  tok : 1 Tok
  count : Int
```

初值：

```
initState : 1 Tok -> State
initState t =
  State
    tok = t
    count = 0
```

渲染函数：

```
render : State -> Widget
render st =
  Row
    Button
      text = "+"
      onTap = 1 { count .. } =>
        { count + 1 .. }
    Text
      text = st.count
    Button
      text = "-"
      onTap = 1 { count .. } =>
        { count - 1 .. }
```