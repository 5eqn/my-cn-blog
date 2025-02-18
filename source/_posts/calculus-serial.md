---
title: 级数学习笔记
date: 2023-06-14 19:55:46
tags:
- 课内
---

想到使用级数的动机，我认为大概就是因为整个微积分基本都基于「极限」这个概念，而对级数也存在「极限」的概念，因此级数可以和前面所学的微积分进行某种意义上的绑定。

## 题目导向型学习

常见的两种标尺级数中，等比级数对应指数函数，p 级数对应幂函数，和瑕积分有相似的审敛规则。掌握这两个标尺，我看高数书上的正常证明题都容易找到合适的放缩来解决。

对于符号交错的情况，需要再看看莱布尼兹审敛法那一块！

对于求和函数的题型，目前只看到通过求导或积分把无限项的式子变成有限项函数的方法，比较典型的是 1/(1+x)，e^x 和 sin x.（没有给博客打拉泰赫！），其中符号一样、阶乘变小的可以变成 e^x，符号交错、阶乘变小的分别变成 sin x 和 cos x，符号交错、不变小的可以变成 1/(1+x)，符号交错、反比例变小的可以变成 ln(1+x) 或 arctan x.

对于估计近似值的题型，我感觉相当玄学，只能尝试寻找一些收敛快的级数。如果是交错的级数，如果收敛快就最好，因为方便估计误差；否则尝试转换成符号相同的级数，这样的级数更有机会收敛快，但需要使用等比级数（可以求和）来估计误差。

对于求微分方程的题型，可以理解为级数理论在给强行把函数看成级数提供了理论基础，这样可以采用更机械化的方法去求微分方程的解，把压力转移到从级数推断出原来的值。

级数理论可以推广到复数，允许其解释欧拉方程。

对于证明一致收敛的题，因为一致收敛要求和 x 无关，考虑采用放缩，本质上也就是 Weierstrass 判别法。同时，和一致收敛相关的证明题通常需要把 s(x) 拆成 s_n(x) 和 r_n(x)，拆出余项之后一致收敛可以说明这个余项不会太大。

傅里叶级数核心在于展开成正交的三角形式的技巧，记忆一下公式之后机械计算积分即可。
