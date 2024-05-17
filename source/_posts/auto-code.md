---
title: Agent | 自动编程离我们多远？
date: 2024-05-16 12:39:04
tags:
- 大模型
- Agent
---

我使用 [信息差](https://github.com/info-gap/info-gap-server) 搜集到了如下和「使用多智能体架构进行自动编程」相关的论文：

- Semantic API Alignment: Linking High-level User Goals to APIs
  - 用来给软件写 API 规范的
- MARE: Multi-Agents Collaboration Framework for Requirements Engineering
  - 自动撰写需求文档
- From Language Models to Practical Self-Improving Computer Agents
  - 没有涉及多智能体，但可以给自己撰写工具
- AutoCodeRover: Autonomous Program Improvement
  - 基于 AST 分析和光谱式错误定位，自动修复 GitHub Issue
- Self-Organized Agents: A LLM Multi-Agent Framework toward Ultra Large-Scale Code Generation and Optimization
  - 递归实现子函数，为每个子函数分配一个 Agent
- When LLM-based Code Generation Meets the Software Development Process
  - 把现有的软件工程实践流程（例如 Waterfall，TDD，Scrum）套到大模型上
- LLM-based agents for automating the enhancement of user story quality: An early report
  - 提升用户需求质量
- Exploring LLM-based Agents for Root Cause Analysis
  - 自动抢修 Bug，找根本原因
- A Unified Debugging Approach via LLM-Based Multi-Agent Synergy
  - 让大模型使用人类的 Debug 方法，比如 [小黄鸭 Debug 法](https://zhuanlan.zhihu.com/p/20053948)
- CodePori: Large Scale Model for Autonomous Software Development by Using Multi-Agents
  - 比 ChatDev 和 MetaGPT 稍强的自动编码机，但没找到开源
- Can Large Language Models Serve as Data Analysts? A Multi-Agent Assisted Approach for Qualitative Data Analysis
  - 用来数据分析的
- Layout Generation Agents with Large Language Models
  - 用来生成场景的，和编程无关
- Large Language Models as Test Case Generators: Performance Evaluation and Enhancement
  - 用来生成单元测试，给大模型执行代码的能力
- CodeAgent: Enhancing Code Generation with Tool-Integrated Agent Systems for Real-World Repo-level Coding Challenges
  - 似乎没有涉及多智能体，属于相对早期的自动生成代码实践
- Experiential Co-Learning of Software-Developing Agents
  - 允许智能体从过去经验中学习
- Autonomous Agents in Software Development: A Vision Paper
  - 提出大模型自动编程的愿景

加上我先前了解过的开源方案，总共有以下这些可以体验：

- [Aider](https://github.com/paul-gauthier/aider)（2023.5）
  - 单智能体架构，人工输入命令，能对已有工程建立符号关联图
- [MetaGPT](https://github.com/geekan/MetaGPT)（2023.6）
  - 软件公司架构，人工评审可以作为智能体，支持新工程和增量编辑
- [GPT Pilot](https://github.com/Pythagora-io/gpt-pilot)（2023.8）
  - 软件公司架构，每一步强制人工评审，只能创建新工程
- [SWE-Agent](https://github.com/princeton-nlp/SWE-agent)（2024.4）
  - 单智能体架构，无人工干预自动修复 GitHub Issue
- [AutoCodeRover](https://github.com/nus-apr/auto-code-rover)（2024.4）
  - 基于 AST 分析和光谱式错误定位，自动修复 GitHub Issue

可以看到，大模型自动编程大体上处于起步阶段，有非常多的思路（自动扩充工具集、分治、移植现有范式等）以及方面（需求撰写、架构、编码、测试生成等）可以探索，这些探索也一定程度上融入了现有的实践。

### GPT-Pilot

#### 例：待办列表前端

| 指标 | deepseek-chat | deepseek-coder |
|-|-|-|
| 完成度 | 缺持久化 | 完美 |
| 输入词符 | 299839 | 84847 |
| 输出词符 | 10770 | 4467 |
| 耗时 | 20 分钟 | 5 分钟 |
| 消费 / 元 | 0.30 | 0.09 |

GPT-Pilot 有一点让我感到十分震惊和痛心，也很无奈，就是在连续 3 次调试有问题之后就会问我是否「Stuck in a loop」。如果是，GPT-Pilot 就会开始超级调试模式，哗哗跑大模型然后竭尽所能修复问题。它甚至会先头脑风暴出一些可以尝试的解决方案，然后让用户选！

我遇到的问题是待办列表的复选框点了没用。说实话，GPT-Pilot 生成的代码看起来非常的没有问题，我调试了 5 分钟才找到问题所在：React 的 `setState` 如果里面是一个回调，可能会被多次调用，然后如果回调只是切换状态，就会连续切换两次，从而导致没有切换。

经过三轮调试，GPT-Pilot 不出所料地没有找到问题，而是在不断地写出相同的代码。在超级调试模式中，GPT-Pilot 给了我五种可能的解决方案：

- 简化 setState 里面的回调，不再创建新的数组而是直接修改数组
- 保证列表里面每个元素的 key 相同
- 确认初始状态从本地存储中能正确读取
- 在 onChange 里面加入打日志的功能
- 用 useReducer 替换 useState

我感觉只有第五个选择能解决问题，所以选择了第五个。后面再调试一轮就解决问题了。如果没有前端开发经验，来自己寻找问题原因的话，可能试很长时间也无法解决问题。

> 使用 GPT-4 Turbo 可以取得更好的效果，但其价格约为 deepseek 模型价格的 72 倍，对于笔者来说过于昂贵。

在使用 deepseek-coder 模型时，虽然逻辑上一发入魂，但实际上大模型的输入中代码部分前后带了文字介绍，如果不删除的话无法直接运行，因此我手动删除了这些文字介绍部分。初期我使用 deepseek-chat 模型测试时，也遇到过一次本问题，说明这个问题并不只局限于 deepseek-coder 模型。

同时，使用 deepseek-chat 时还出现过调试员智能体无法正常运行的问题，原因未知。

使用本地模型 llama3:8b、deepseek-coder:6.7b-instruct、yi:9b 均无法产生符合格式的输出。

#### 例：用 Rust 写四则运算解释器

GPT-Pilot 似乎部分操作（新建工程、调试工程等）和 Node.js / React 等特定技术栈强耦合，因此即使我再三强调需要用 Rust 写命令行工具，GPT-Pilot 坚持要写一个完整的前后端，并且还计划加入用户登入登出功能。如此看来，GPT-Pilot 的泛用性并不强。

### SWE-Agent

#### 例：Rust 代码修复

我去掉了 [dusk-phantom](https://github.com/5eqn/dusk-phantom) 中 `Sin` 和 `Cos` 函数的类型的实现，提了个 Issue 说明这一点，测试 SWE-Agent 能否找到并修改。

结果发现是不行的！该仓库和 AutoCodeRover 似乎只对 Python 仓库有效，因此泛用型并不强。

