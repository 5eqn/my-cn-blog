---
title: 大学物理不应该需要花时间学（完结）
date: 2023-06-21 05:58:23
tags:
- 课内
---

在思考大学物理有关的题目时，理论上每一步都是符合或容易符合基础人类直觉的，只是将这些直觉以准确的方式「组合」起来有难度，不像数学里面需要专门培养「数学素养」。这意味着理论上不花时间碰大雾是学不会的（这下我标题党了），但只要给一个极小时间段，例如一天，我就可以完整地学会大雾，并且展现出昨天电工一般的表现。即使不能这么好，至少也大概率不会挂科。下面我将记录我的大雾复习感想，以证明这一点。不过为了复习的效率，我将直接去刷真题。

## 粒子

我稍微理了一下整个到粒子涉及一大堆普朗克常数的玄学部分的推理链：最初是相对论的能量和动量定义，然后可以瞬间得到光的动质量、动量和能量之间的比例关系。书里用了很多东西尝试去绕过零除零问题，实际上如果只是从理解层面来看的话没有必要，去掉这些步骤之后就是显然 1 : c : c^2. 

在此之后在光的背景下定义普朗克常数为 h 使得粒子能量为 h 倍的粒子频率，这时候如果要算动量，显然就是上面那坨除以光速，而光速恰好等于频率乘波长，因此最后得到动量为 h 除以波长。

剩下的就是推广到普通物质以及高中物理了，注意在推广到普通物质的时候频率乘波长得到的是相速度，这个速度和其实际的运动速度是不一样的，只是一个概念性的而且可能（一定？）超过光速的概念性玩意，也不能被用于计算动能，因此信息就少了一些，有些题会往这里考。

## 转动惯量

转动惯量描述的是物体转动的动能和角速度平方的关系（这个似乎不是最本质的，起初是描述力矩和角加速度的关系，然后自然地通过对路程和积分的积分分别导出动能定理和动量定理），类比的是高中动力学里面的质量。那么由于速度等于半径乘角速度，转动惯量受半径的影响也自然是平方关系，因此对均匀细杆积分会得到 1/3. 其他比较复杂的建议计算器手算。

## 电生磁

其实就是 dB = k dq v sin(theta) / r^2, 直观感受就是一点点电荷以 v 的速度运动能够在其两侧产生一点点磁场，以 I dl 的形式思考会累很多。

注意要专门记一下常数大小，例如电生磁的常数大小是 mu0 / 4 pi. 如果用到在试卷上会给出。常数一般按照在高斯定理（闭合曲面的电场强度通量只和里面的电荷量有关）下美丽的形式给出，而球的表面积是 4 pi r^2, 因此通常带一个 4 pi 的系数。同时，静电力的常数大小是 1 / 4 pi e0, 也可以用高斯定理理解。

通过高斯定理可以直观地推出一些基础的积分结果，例如无限长直电流产生的磁感应强度带一个 1 / 2 pi r 的系数，想象一下在电流元附近作一个很矮的圆柱体即可，这个圆柱体的底面周长是 2 pi r, 这个压掉高度维度之后就变成了安培环路定理。平行板电容器产生的电场强度不带系数，对一边极板作一个向那个极板两侧延伸的圆柱体，不要碰到另一边极板，就可以很明显地看出一份电荷对一份电通量。

使高斯定理直观的秘诀是，首先认定电荷量产生电场强度的机制，然后选中一个闭合曲面时，把电场强度按照其产生者在曲面外面还是里面编组，然后你就能很自然地感受到在外面的产生的电场强度进去曲面了也要出来，里面产生的就全部出去，而且出去的量和曲面大小和形状无关。这样在思考平行板电容器的策略时，就不会产生「明明两边都有电荷，你怎么只考虑一边」之类的问题，因为只要选定了一个曲面，知道这个曲面有多少电通量，就可以立即知道这个曲面里面有多少电荷，只是这些电通量不一定是原原本本里面的电荷导致的，可能被外面的电荷「变形」，但「数量上」绝对不会有变化。

看到例如「远大于」之类的条件要记住，不会让你积很困难的东西，比如 r^2 dr / (r+x)^2！

## 波速和波向的歧义

指定以 xx 为正方向，波速为多少，并不代表这个正方向就是波的方向！物理里面很看完整读题，如果有「波从左向右传播」，这样后面无论说什么勾巴，都是从左向右！！！

但波的方程非常好列，以顺行波为例，把 cos 或者 sin 函数想成一个随时间变化的规律，这样在波的前面相当于在时间上延后，因此是减。这里逻辑是顺的，但「函数图象右移时方程中自变量减去位移量」里面逻辑相反，是因为对于相同的时间点（自变量），右移相当于是让整件事情延后发生了，这样理解的话就很顺。具体减的量通过单位分析都能知道，x / v 就是延后的时间。

换了一个号买了个 9.9 元的热生椰爱摩卡，带到实验室的时候奶油已经融化了，口感也比较玄学，不过还是很好喝的。

## 波动光学不需要专门学习

我找了一份题目，里面有个波动光学的题，大概是：

在双缝干涉实验中，用波长 λ = 550 nm 的单色平行光垂直入射到缝间距 a = 2×10-4 m 的双缝上，屏到双缝的距离 D = 2 m。求：

(1) 中央明纹两侧的两条第 10 级明纹中心的间距；

(2) 用一厚度为 e = 6.6×10^-6 m 、折射率为 n = 1.58 的玻璃片覆盖一缝后，零级明纹将移到原来的第几级明纹处？

可能你觉得很简单，但我起初看这个题是眩晕的状态，因为我只是前几天看了一遍波动光学的内容，已经忘了双缝干涉的公式了。

但我进行了几分钟的现场推理，这里推理的关键在于发现 D >> a, 然后就可以直接假设角度相同的光射到同一个地方，我就很快找到了相似三角形的关系，做出第一问。对于第二问，起初我在想在玻璃片里面经过的路程和角度是相关的，但由于计算第一问的时候我发现波长远小于孔的直径，角度也应该是近似 90 度的，所以只有一个光程差的影响，简单列出方程 (n-1)e=kλ 即可求出 k=7.

同时，前面的波的题目我也在基本忘了课本结论的情况下近似做出来了（只是波向搞反了，但题目明明有说），电磁学的题目如果看到了 R1>>r 的条件也能做出来，关键积分都已经积出来了。

光强是振幅平方！从最基础的能量定义开始感受就很显然。

记住光在经过折射率分界面的时候的两种基础选择：折射、反射，不会直接穿过去（这不显然吗？），因此如果对于薄膜干涉、劈尖干涉这种有内部反射的东西，把这些尝试都考虑到就不会反直觉了。

## 平行板电容器

C = Q / U 里面 Q 是一个极板带的电荷，U 是电压差，不会随着接地而改变，因为即使接地另外一边有静电感应还是会形成相应的负数电荷。静电感应相对玄学，如果按照「排斥」来理解可能比较晕，可以理解成外面的电荷「吸引」了里面的反向电荷，这样就能理解为什么反向电荷一定聚集在导体外面。其实这也是相对自然的，只要同时想象正反电荷，就能瞬间感受到这一点。

电容器串联在有静电感应作为理论基础的时候就能直观理解为什么和电阻并联法则一样，因为在串联时可加的是电压，如果把中间的极板看成有体积的，那么在静电感应下就会呈现 +Q -Q +Q -Q 的模式，没有良好的可加性。就像电阻定义中的 I 一样，串联电阻且 I 不变时 U 才能呈现良好的可加性，并联电阻且 U 不变时 I 才有良好的可加性，而电阻的定义是 U / I，便可以得到在串联时才表现出可加性，并联时其倒数表现出可加性。同理对于电容定义 C = Q / U，在电容串联时其倒数表现出良好可加性，并联时则本身表现出良好可加性。

## 读题

自己试了做了一下几乎每题都做错了，无一例外都是读题和傻呗错误，或许考试的时候要认真一点。

## 驻波中的定义

波节容易被理解成纵波里面最密集的点，实际上由于纵波里面的密集程度和横波的高度对应，理解波节和波腹定义的关键是在更容易分析的横波下思考（纵波本质上是一样的只是加了个奇怪的上下文）：波节就是一直值不动的地方，波腹是动得最厉害的地方。
