---
title: AI | 阅读论文介绍还是原论文？
date: 2023-11-03 20:19:39
tags:
---

这涉及到「工业思维」和「学术思维」的问题，一般而言 Paper 的学术思维更强，国内网站介绍的工业思维更强。如果要概括两者的区别，则是：工业思维侧重于「怎么应用」，学术思维侧重于「可以怎么应用」。因此如果你需要快速把模型用起来，更适合看工业思维的介绍；如果需要真的理解模型的学术贡献，更适合看原论文。

例如对于 Transformer 论文，[一篇介绍](https://zhuanlan.zhihu.com/p/338817680)中提到：

> 公式中计算矩阵 $Q$ 和 $K$ 每一行向量的内积，为了防止内积过大，因此除以 $d_k$ 的平方根。

但原论文写的是：

> We suspect that for large values of $d_k$, the dot products grow large in magnitude, pushing the softmax function into regions where it has extremely small gradients. To counteract this effect, we scale the dot products by $\frac{1}{\sqrt{d_k}}$.

显然原论文的理由给的很到位，「尽可能让梯度明显」也是 AI Research 中的一个很重要的直觉，但介绍就没有提到这一点。这便是学术思维和工业思维的差距的一个例子。

还有对于 GELU 论文，[一篇介绍](https://zhuanlan.zhihu.com/p/394465965)中提到：

> 研究者表明，收到 dropout、ReLU 等机制的影响，它们都希望将不重要的激活信息规整为 0，我们可以理解为，对于输入的值，我们根据它的情况乘上 1 或者 0。

介绍并没有解释「它的情况」是什么，略显唐氏，但原论文写的是：

> First note that a ReLU and dropout both yield a neuron’s output with the ReLU deterministically multiplying the input by zero or one and dropout stochastically multiplying by zero.

显然原论文解释的更清晰。

对于需要进行学术研究的读者，通过合适的阅读和筛选策略，可以使得阅读原论文的速度约等于阅读介绍的速度。目前我只在阅读 Recursion Schemes 论文的时候遇到过读介绍快于读原论文的情况，因为那篇论文写得比较抽象，同时我也缺乏范畴论知识……
