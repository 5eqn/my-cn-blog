---
title: 学习 Git
date: 2023-06-27 16:59:51
tags:
- 编程
---

一直感觉 Git 里面有一些很反直觉的东西，找到一个互动平台 https://learngitbranching.js.org/ , 尝试跟着这个学。

## Merge 和 Rebase

在 main 上 merge bugFix 会把 bugFix 分支的东西移过来再开一个 commit，在 bugFix 上 rebase main 会把 bugFix 上分支的东西复制到 main 后面。

git rebase another main 会把 main 移动到 another 的状态。

## 移动

git branch -f main HEAD~3 把 main 移动到 HEAD 上面三层，git checkout 只移动 HEAD.

git branch bugWork C6 会在 C6 创建一个叫 bugWork 的 branch.

## 修改历史

git reset C1 会把当前分支回退到 C1 已经发生的状态，git revert C2 会撤销掉 C2 的内容。

git cherry-pick C1 C3 C5 会把 C1, C3, C5 分别复制到当前分支下面当作 commit.

git rebase -i C1 会回到 C1 状态，然后有窗口让你选择对后面分支的处理。

git commit --amend 相当于 git reset HEAD^, git commit.

## 应用

尝试对调度器进行 debug，之前的某个版本 shared-resource 任务会自动 finish，改了命名之后就不会。

12:24 PM, 使用 git reset lastWorking --hard 回退到上一次工作的状态，部署，发现会自动结束。

12:27 PM, 使用 git reset latest 看 diff，没发现哪里可能有问题，直接 --hard 重新部署，发现不会自动结束。

12:34 PM, 重新写一次 deleteOnComplete, 看看会不会出问题。竟然出问题了！

12:41 PM, 回退到上一次工作的状态，还是有问题！不过似乎没有 push 记录。

后面开始玩 MC 了。

4:00 PM, 继续。

4:02 PM, 这玩意换了一种 bug 方式，直接 unauthorized. 尝试回退到原来的状态。需要 git log --reflog 才能显示出丢失的 commit.

4:13 PM, unauthorized 是因为重启了 apisix 但没有重启浏览器。不过现在重启也没用了。

4:18 PM, 感觉大概率不是我的问题。真的很玄学！再试一下吧。

4:29 PM, 修不动咯！

4:58 PM, 用 git rebase -i 把之前的阴间记录理干净了，最终大杀器还是 rebase -i，能够相当智能地给出需要 resolve conflict 的地方，但有时候也会要调空行。
