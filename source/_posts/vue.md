---
title: 前端受难日记
date: 2023-06-13 15:05:22
tags:
- 编程
- 前端
---

最近尝试写博客前端，但受到 Flutter 的各种折磨，不仅有 Flutter 内部的问题（死亡嵌套，为什么不能用 positional argument...），还有和安卓对接的问题（尝试 build 了一个小时），以及性能问题（为什么 Flutter Web 渲染中文会卡……）。

## React 和 Vue

之前使用 React 的时候我使用了一些封装性质的插件（例如 RTK Query），但是这会增加项目前期的配置难度，在这种要新建一个工程的时候就挺烦的，还有很多分布在各处的玄学配置大幅增加认知压力，我更希望能有一种写一个文件就渲染一个东西的方案。

React 相比 Vue 主要麻烦在要把状态的 getter 和 setter 分开，不能偷懒直接把状态流设的到处都是。其他性质，例如 React 的 useMemo 对 Vue 的 computed （虽然实现思路有细微差异）、React 的 useState 对 Vue 的 ref、React 的 useEffect 对 Vue 的 watchEffect，都是非常相似的。而 Vue 里面因为用了 template，JS 只能用来算非 component 的值，React 里面能用 map 和 case split 的东西，在 Vue 里面要自己用 v-for 之类的玩意手搓，和 JS 是两套不同的体系（其实影响不是太大，反正都图灵完备）。综上，React 和 Vue 在使用体验上基本没有区别，只是实现有所不同。

比较烦的一个东西是路由，不过 React 和 Vue 里面都有相对成熟的方案，总而言之都是用一个 router 封装了一个 switch case 的东西，只是 React 可以用 JS，Vue 这里等效于 v-switch v-case. 有了路由、状态管理和组件库之后，基本普通的前端都可以随便写了。

## Uniapp

最近通过某人了解了一个国产跨平台框架 Uniapp，正好是用 Vue 的，但其内部似乎夹带了一些私货，例如应用顶部默认显示一个 bar，这个 bar 没有出现在任何 Vue script 里面，需要自己手动隐藏，这个 bar 可能是为了和小程序的风格统一（或者本身就是它引领了小程序的风格）。观察其应用场景，除了 build 出手机和网页端的应用，剩下的都是各家的神秘小程序。但由于这是个成熟的国产框架，至少渲染中文字体不会卡顿，而且据官网有不需要对安卓之类的平台额外配置的好处，所以值得一试。（具体怎么样不好说！）

Uniapp 似乎有自带的路由机制，但理论上这种跨平台的框架的理想形态是给一个 Vue 的应用，直接把它变成其他各种平台的，因此我打算先试一下使用正常的 router. 对了，Uniapp 的模板文件的 json 里面一堆 ^M 符号，实在是抽象！

## React Native

理论上 React Native 也是相当不错的，而且基于 JS 估计不容易出现 Flutter 这种渲染中文卡顿的恶性事件，但我现在觉得我在尝试 Uniapp 之前至少应该先尝试一下 Debug 一下 Flutter Code，其实 Flutter 和 React 没有本质区别，有些东西 verbose 一点并不是坏事。说不定中文卡顿真的是我的配置问题！（我或许需要尝试新建一个工程，鬼知道 github 上下载的模板工程有没有什么版本过旧的问题）

## 理想

理论上应该搞个 Dependent Typed 的前端框架，然后抓个 AI 先从图像生成命题类型，然后对着这个类型打 Proof Search 来生成严格的程序。如果能加上推广的 Linear Type，搞一堆 Token 然后像 Entity Component System 一样直接搓 P2P 的函数就更好了。理论上这玩意和 2D 游戏引擎是等价的。

泰裤辣！
