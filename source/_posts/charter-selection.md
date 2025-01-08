---
title: 实现制谱器音频选择
date: 2023-07-03 10:55:49
tags:
- 编程
- 游戏
---

本次的任务是写音频上传、音频选择以及 BPM 的操作，其中包含读取、自动测试、直接上传数字以及根据已有谱面调整，下一步是写制谱器本体。

## 后端更新

需要给后端加入设置和同步 BPM 的功能，让 ChatGPT 写后端还是非常快的，反而是自己写的一个部分忘记 Preload 导致没有一发入魂。

HTTPie 有个神奇的语法，就是如果要指定 Raw JSON 的话，需要使用 := 表示赋值。

老是写一大堆才 git commit，这个习惯不好。

## 傻呗除零错误

尝试让音频测试可以更换音频，发现输入无效，看后台有除零错误，后来才发现是因为歌曲的 BPM 数据还没有同步！草！

## 神秘组件选择

活用 IntrinsicHeight！可以解决诸如「我希望这个组件能够保持其自然高度，不要填满整个屏幕」之类的需求。

## 格式

Flutter 在尾部逗号没加满的情况下会给出很丑的格式化方式！

## 逆天 Audioplayers

Flutter 的音频播放竟然不能直接获取歌曲长度？

好像是因为 URL 有 redirect 导致的，得直接请求到 assets 的地址。Web 端因为没有 File, 没法先下载到本地再 Play. 得改服务器咯！最后还是在 audioplayers 的 FAQ 里面找到的问题，网上都找不到有人因为 redirect 被坑的例子。

Nginx 的作用在这种时候就体现出来了！

补：Web 如果 ByteSource 能用的话就可以下载到本地然后 Play，但这样就要为不同平台写不同的代码了，很逆天。为什么不能用内存和 cache manager 模拟一个 Filesystem 呢？这样在不同系统可以写统一的代码。

## 神秘发现

Flutter Web 体验比 Linux Desktop 强多了！帧率更高，音频处理也更好。但是 CORS 也更多。

## 逆天 nginx

```nginx
add_header Header0 $value;
if (condA) {
  add_header Header1 $value;
  return 204;
}
```

如果 condA 符合，nginx 直接不加 Header0！这让我想到某个内容包含买西瓜的程序员笑话，或许 nginx 是在提醒我们程序员要返璞归真，用正常人类的逻辑思考。

Nginx 还自带文件大小限制！这很不 KISS.
