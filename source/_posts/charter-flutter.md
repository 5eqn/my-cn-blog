---
title: 尝试搓一个制谱器
date: 2023-06-26 20:39:39
tags:
- 编程
- 游戏
---

上次用 flutter 搓了一个音乐播放器，现在看看能不能改成一个能用的制谱器。

看群里感觉组织去企业的效率很低，看看接下来几天能给我多长时间看 HoTT.

## 架构

有三个不同功能的窗口：

选歌窗口负责选择已有的谱面，或者直接选择歌曲来新建谱面，这些状态应该被传到制谱窗口。

校准窗口负责调整输入延时，分为输入延时和音乐延时。暂时忽略显示延时。

输入延时表示输入的延迟，作用于输入：如果有个键掉到判定线上，输入延时为正表示用户认为正确的输入令程序认为偏晚，作为补偿程序在后续接受到输入的时候会将其 timestamp 提前，在只显示 grid 的时候就可以测试。

音乐延时表示实际播放出来的音乐相比 `_audioPosition` 的延迟，作用体现在修正 `_audioPosition`，在输入延时配置正确时，音乐延时为正表示用户认为正确的输入令程序认为偏晚（因为用户根据滞后的音乐来认为自己的输入正确，这里输入延迟已经被补偿），作为补偿程序会减小 `_audioPosition` 的值，这将同时令输入和显示的 timestamp 提前，在只播放音乐的时候可以测试。

校准窗口在 Drawer 里面分成两个按钮。

制谱窗口的状态包括一个对歌曲进行节奏分析的结果（用现有的 python script 比较方便，暂时先采用 bpm 和 offset 的形式，后续可以改成只记录可以采音的点），歌曲本身或其 url，以及当前谱面（包含在哪里有多大力度的键以及其他元信息）。

用类似于这种架构写窗口：

```dart
Scaffold(
  appBar: AppBar(
    title: const Text('Drawer Demo'),
  ),
  drawer: Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: const <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text(
            'Drawer Header',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.message),
          title: Text('Messages'),
        ),
        ListTile(
          leading: Icon(Icons.account_circle),
          title: Text('Profile'),
        ),
        ListTile(
          leading: Icon(Icons.settings),
          title: Text('Settings'),
        ),
      ],
    ),
  ),
)
```

注意 ListView 需要存储选了哪个。

## BPM 自动分析

从 gayhub 上面嫖了一个，发现不能读 mp3，就让 chatgpt 帮了点忙，代码一发入魂。主要时间花在装库上，本来想着装 requirements.txt 很麻烦，就想 pip install -r requirements.txt, 但是只能 pacman，试了下 virtual env 也不适配 requirements.txt（应该是 OS 的问题，配不好），最后想手动一个一个装发现前面俩已经有了，最后发现一堆里面只有一个库没有。后面读 mp3 的库也没有，这两个库都只能从 AUR 下载。

对变 bpm 的歌曲分析效果不好，而且有时候数字不整，不知道是否和精度有关。有空可以看下原论文研究如何改进。

numpy.correlate 在 full mode 下是找到两个波形的所有重叠方式，求出每种方式的相关系数，因此相关系数最大的 idx 结合一些信息可以算 offset，还可以用 offset 来纠偏，以及动态调整 window，实现变 bpm 的检测。但现在不想去尝试实现这个了，搞明白就好，调度器又发现 bug，修一下。

## 7:44 PM

我感觉没 bug.

## 7:50 PM

原来是 DeleteOnComplete 功能最初就没实现，实现一个。

## 7:57 PM

实现好了。改下命名。

## 8:03 PM

改好了，spectre 的 toggle case insensitive 是用快捷键 ti，很反直觉。现在最后一个任务编号是 44，等会测试一下是不是可以删除。

## 8:11 PM

改了之后莫名其妙任务无法停止。其实逻辑根本没改。结束之后会不断发送 RUNNING，运行的时候不会，很奇怪。

## 8:29 PM

发现在 node 不齐的时候有概率触发空指针。

```
goroutine 27 [running]:
main.AllocateResource(0xc0004dc9a0, 0xc00048bc50?, 0xc000399cf0, 0x5?, 0xc000093cb8?)
    /home/seqn/go/patient/resourceScheduler.go:58 +0x75e
main.(*ResourceManager).allocateResource(0xc0001ff3e0, 0xc0004dc9a0)
    /home/seqn/go/patient/resourceManager.go:188 +0x325
main.(*TaskManager).tryRunTask(0xc000490000, 0xc0004dc9a0)
    /home/seqn/go/patient/taskManager.go:325 +0x146
created by main.(*TaskManager).processTask
    /home/seqn/go/patient/taskManager.go:310 +0x1a5
```

## 8:35 PM

问题逼多，delete task 之后内存里面的 idx 没删。但 L463 已经删了，很他妈玄学。

## 8:39 PM

先不写了。
