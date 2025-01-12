---
title: 制谱器校准模块
date: 2023-07-02 11:12:19
tags:
- 编程
- 游戏
---

尝试在之前写的 Flutter 音频播放器的基础上改出一个校准模块。

## 架构

需要一个 App bar, 有输入校正和音频校正两个模块，输入校正里面会根据当前时间有下落的线，收到任意点击事件后检查和程序时间的差异，然后以此调整全局输入延迟；音频校正则和音频时间对比。

## 吐槽一下 ChatGPT

感觉 GPT 对含渲染的东西准确率不是很行，还是自己找可靠的 snippet 然后改比较快速。对一些状态管理之类的效果很好。

不过自己写太缓慢了，没有 snippet 的时候还是用 ChatGPT 搞一个 prototype 更快。

## 神秘地不刷新！

设置了一个在变的时间变量，但不知道为什么页面没有动。原来是要 setState！这下傻呗了。

## 缓存

flutter_cache_manager 不是用来做本地存储的，而是用来避免重复 fetch 资源的！本地存储应该用 shared_preferences.

## 镜像

使用阿里云镜像 build 不出来，用默认镜像就可以。这就是为什么国内镜像不能抹除使用魔法的必要性。

## 进度

一个下午只写了输入校准模块！悲。实验室这边还要抽空把后端的 API 整理出来，以及改 Cloud IDE 前端。

使用 ChatGPT 20min 光速写完 400 行的 swagger.

## 性能优化

不能让 text 每帧刷新，尝试改一下架构。

把 ticker 扔 note 里面就好，让 ChatGPT 重构出更多的 StatefulWidget 还是很方便的。

变量能私有就私有，dart 里面用前缀下划线表示私有变量，比较神奇。

## 音频回收

不仅要回收 audioPlayer, 还要回收 subscription! 这点还是 ChatGPT 告诉我的，虽然开头有 bug 的码也是 ChatGPT 写的。今天进度被这些细节拖了好久，约等于只写了个 AppBar 和输入校正，明天继续！

## 进度

花一上午（不过实际上 10 点才到实验室，最终写了一个小时码）才搞好音频校正，前面架构写太糊了，稍微小修了一下。

感觉工业上的软件开发还是不可避免地有个随着时间重构的过程，从一开头就对架构过度优化不理智，但最后一直堆也不好，把握平衡点也是一种艺术。这个和人的认知发展也是同构的，只是现在的框架一般逻辑和框架的耦合度太高，导致如果要重构（例如 StatelessWidget 变 StatefulWidget，但当然不止这一个方面，还有提取出一些共同逻辑之类的），成本显著多于逻辑，目前而言使用尽管有错误率的 ChatGPT 来代替是一个好方法。理论上如果有一个靠同伦类型论实现高度解耦的语言，重构前和重构后之间的成本只等效于其之间的简单逻辑变换，这样就没有「重构」的说法了。

下一步需要写音频上传、音频选择以及 BPM 的操作，其中包含读取、自动测试、直接上传数字以及根据已有谱面调整。

## android:usesCleartextTraffic

Android 平台似乎阻止对媒体文件的 HTTP 协议请求，必须要搞成 HTTPS. 同时部署到手机上还要考虑响应式设计的问题，很坏，由于我比较急着出成品就先不搞了。