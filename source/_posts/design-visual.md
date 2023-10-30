---
title: 前端 | 用「立方设计」实现一个计数器
date: 2023-10-30 14:42:38
tags:
- 草稿
---

## 正片

你希望实现这样一个计数器：

![](counter.png)

### 四次点击，一个组件

首先从组件库里点击文本组件拾取，双击屏幕中央以放置在屏幕中间：

![](drag.png)

移动鼠标，组件的大小会随着鼠标位置改变。支持预先定义「网格」，来避免取到类似于 `16.3724px` 的大小。大小合适时单击，表示确认：

![](resize.png)

从组件库里点击圆形组件拾取，单击屏幕中央，向左移动一段距离，组件的位置会随鼠标位置改变。同样支持预先定义网格，防止取到不规范的位移大小。位置合适时单击，表示确认：

![](drag-circle.png)

移动鼠标，调整组件大小，满意后确认：

![](resize-circle.png)

支持设置组件各项属性数值。可设置的数值从组件库 API 爬取，实时渲染真实效果。

![](info.png)

### 一个问题，一项状态

写好了组件排列，你将目光从 UI 视图移动到状态视图：

![](double.png)

你问自己「页面的状态」是否有可以变动的部分，得到的答案是「中间的数字会变」，因此在 `State` 中加入 `count` 字段表示中间的数字：

![](state.png)

你问自己 `count` 固定的情况下，页面的状态是否还有可以变动的部分，得到的答案是没有，这说明你已经写好了状态！

### 四次点击，一次状态绑定

为了将 `count` 状态同步到 UI 视图，你首先在状态视图点击 `count` 的「输出端子」：

![](fn-output.png)

然后切换到「纵切视图」，选择 UI 视图：

![](fn-relation.png)

最后在 UI 视图选择目标组件的目标变量的「输入端子」：

![](fn-dest.png)

### TODO

## 花絮

我本来想把软件叫 CuCl2（氯化铜），因为软件的特色是立方（Cube），人要用两只手（2 Claws）做设计，但似乎太过谜语人，故作为花絮放在这里。