---
title: 挫折就像微积分一样，踩爆了就没事了
date: 2023-06-22 06:33:40
tags:
- 课内
---

猜猜这个标题的灵感取自哪里？

## 微积分 B 的特点

实际上微积分 B 的概念少于大学物理 II，并且仅有的概念本身都很符合人类直觉。例如在所有定义里最逆天的「旋度」，可以用「力矩」来直观理解，在给定旋转轴极微小的情况下，由于可以去掉所有平动量（把目标点的矢量标准化到 0），力矩可以理想化地被认为是力场的顺时针旋转方向的导数导致的，叠加三个旋转轴后自然得到 nabla 叉乘 f 这种规则。难度主要在于定积分和一些巧思，有的题型如果没遇过，想一个小时都想不出来，我选择把锅推给 Matrix 及其评价体系。

## 曲面积分

尝试去掉对称性的部分，看是否能利用起斜率信息，如果不能尝试高斯定理。例如对于某圆锥面的题目，首先发现对 y 轴有对称性去掉 xy + yz + zx，然后斜率可求就直接转化成二重积分。

## 关于公式

由于我学的真的太少了，建议自己暂时不要用回忆起来的随机公式，大概率是错的。

## 鼓励一下自己

2018 春期末第四题曲线积分，我竟然能独立找到一个比标准答案更简单的方法！答案在知道积分和路径无关时，直接选择了比较平凡的折线段路径，需要算一些很抽象的积分，但我选择圆路径之后发现几乎没有计算量！

对了，昨天睡着花的时间不超过 20 分钟，今天 4 点半起，实现了健康的 7 个半小时睡眠，现在一点都不困！但变量太多了，一个是没喝瑞幸，一个是没睡午觉，还有一个是前两天晚上没有和舍友玩「蛋仔派对」但是昨天有，到底哪个才是加速我睡着的原因呢？

做题的时候尽可能以一个直观的视角去看待纯的数学概念！例如对于曲面积分中 f_x dy dz + f_y dx dz + f_z dx dy 的结构，可以把 f 理解成类似于「电场强度」的东西，dy dz 是当前考虑的平面，f_x dy dz 则是在 x 轴方向上的电通量微元。用这种视角的好处是不容易犯非常弱智的错误，例如把非常简单的曲面积分直接当 0！

## 幂级数转变成和函数

先求收敛域，然后尝试变形成两个基本形式之一：e^x, 1 / 1-x，一个分母有指数，一个没有。注意可以带上任意的等比系数，而倍增、交错之类的都可以被拟合。同时，由于可以积分或微分，规律的 p 项式可以被拟合；可以乘法，因此可以做一些凑次数和错位相减之类的事情……

2018 春期末第六题答案先微分再进行可加性分解，我先分解、抽离乘法再微分（其实已经到模板了），计算量也瞬间比答案变小很多。

## 傅里叶级数

读题，有可能只需要求正弦级数或余弦级数！

傅里叶级数里面补偿系数是 1/pi 但积分范围是 2pi 基于三角函数的正交性，但三角函数平方之后平均值是 1/2, 而需要积分范围 * 平均值 * 补偿系数为 1, 因此补偿系数是 1/pi. 理论上是比较好记的。