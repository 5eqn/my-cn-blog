---
title: Agent | 自动编程离我们多远？
date: 2024-05-16 12:39:04
tags:
- 大模型
- Agent
---

本次博客内容包括：

- 大语言模型介绍
- 各自动编程方案评测
- 离自动编程各阶段的距离

题设中，「我们」指有意于从事计算机相关行业的大学生，因此我会更多地考虑经费，同时考虑自动编程方案在大学生实际课业中的应用场景。

为了让评分更有艺术感，我给 4 个等级取了中文名，分别是：观者、战士、猎人、鸡煲。希望若读者在下文中看到，不会感到唐突。

## 翻译对照表

|概念|翻译|简称|
|-|-|-|
|Large Language Model|大语言模型|模型|
|Token|词符|
|Repository|仓库|

## 关于大语言模型

大语言模型本身，其实只能解决如下形式的问题：

> “用户：大语言模型是什么？助理：” 后面最可能是什么字？

- 给大语言模型输入：“用户：大语言模型是什么？助理：”，大模型就可以回答：“大”。
- 输入：“用户：大语言模型是什么？助理：大”，回答：“语”。
- 输入：“用户：大语言模型是什么？助理：大语”，回答：“言”。
- ……

最终，看起来就像是大模型回答了用户的问题。

上面的介绍是有所简略的。事实上大语言模型是预测一串「词符」后面最可能的下一个词符。这种词符可以被理解为大模型特有语言的单字，需要被翻译成人类能看懂的语言。

大模型的计费也是根据词符判断，其中输入词符指问题部分，输出词符指大模型回答的部分。通常输出词符的价格是输入词符的 2-3 倍，因为不论有多少输入词符，大模型每运行一次推理只能得到一个输出词符。

部分新的大模型可以一次推理出多个词符，据说在编程任务上表现更好，推理速度也更快。

## 背景

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

加上我先前了解过的开源方案，总共有以下这些完成度较高的可以体验：

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


## GPT-Pilot

GPT-Pilot 安装很方便，有现成的 VS Code 插件。其对 deepseek 模型的支持也很顺滑，直接当作 OpenAI 的模型导入基地址和密钥即可。

### 简单前端：写一个待办列表网页

| 指标 | deepseek-chat | deepseek-coder |
|-|-|-|
| 完成度 | 待办刷新就没 | 完美 |
| 输入词符 | 299839 | 84847 |
| 输出词符 | 10770 | 4467 |
| 耗时 | 20 分钟 | 5 分钟 |
| 消费 / 元 | 0.30 | 0.09 |

GPT-Pilot 有一点让我感到意外，就是在连续 3 次调试有问题之后就会问我是否「Stuck in a loop」。如果是，GPT-Pilot 就会开始超级调试模式，哗哗跑大模型然后竭尽所能修复问题。GPT-Pilot 甚至会先头脑风暴出一些可以尝试的解决方案，然后让用户选！

在使用 deepseek-chat 模型时，我遇到了复选框点了没用的问题。说实话，GPT-Pilot 生成的代码看起来非常的没有问题，我调试了 5 分钟才找到问题所在：React 的 `setState` 如果里面是一个回调，可能会被多次调用，然后如果回调只是切换状态，就会连续切换两次，从而导致没有切换。

经过三轮调试，GPT-Pilot 不出所料地没有找到问题，而是在不断地写出相同的代码。在超级调试模式中，GPT-Pilot 给了我五种可能的解决方案：

- 简化 setState 里面的回调，不再创建新的数组而是直接修改数组
- 保证列表里面每个元素的 key 相同
- 确认初始状态从本地存储中能正确读取
- 在 onChange 里面加入打日志的功能
- 用 useReducer 替换 useState

我感觉只有第五个选择能解决问题，所以选择了第五个。后面再调试一轮就解决问题了。如果没有前端开发经验，来自己寻找问题原因的话，可能试很长时间也无法解决问题。

> 使用 GPT-4o 可以取得更好的效果，但其价格约为 deepseek 模型价格的 36 倍，对于笔者来说过于昂贵。

在使用 deepseek-coder 模型时，虽然逻辑上一发入魂，但实际上大模型的输入中代码部分前后带了文字介绍，如果不删除的话无法直接运行，因此我手动删除了这些文字介绍部分。初期我使用 deepseek-chat 模型测试时，也遇到过一次本问题，说明这个问题并不只局限于 deepseek-coder 模型。同时，使用 deepseek-chat 时还出现过调试员智能体无法正常运行的问题。

本地模型 llama3:8b、deepseek-coder:6.7b-instruct、yi:9b 均无法产生符合格式的输出。

### 中等全栈：简化版文章平台

| 指标 | deepseek-chat | deepseek-coder |
|-|-|-|
| 完成度 | - | 完美 |
| 输入词符 | 563567 | 84847 |
| 输出词符 | 16035 | 4467 |
| 耗时 | 60 分钟 | 5 分钟 |
| 消费 / 元 | 0.60 | 0.09 |

需求是整一个支持文章删除、发布、浏览、评论的平台。我给 GPT-Pilot 的要求如下：

```
Article platform in node/express using MongoDB. For the UI, use Bootstrap and vanilla JS.

Users must register (username + password, no email verification, no password recovery). Use session-based auth (no JWT). The first registered account is the administrator.

When user logs in, the home page shows a list of all article titles and publish date.

If the user is administrator, the home page should also show the entrance to admin panel.

The admin panel shows a list of all article titles and publish date. Admin should be able to delete existing article.

The admin panel should also show the entrance to article-creating panel.

The article-creating panel shows a form, containing a title input, a file selector (it selects HTML as the content of the article), and a button to confirm creation of article. If title or content is empty, it should show warning. Otherwise, create an article with given title, content and current date. There should be a feedback (success or failure) for the API call.

In home page or admin panel, when the user clicks an article, the user should be redirected to the article page.

The article page shows the content of the article in an HTML wrapper.

The article page should also show a comment section below the content.

The comment section should begin with a input section, followed by existing comments of the article. 

The input section should contain an input field and a submit button. There should be a paper plane icon in the submit button. When clicking the submit button, the contents of the input field should be submitted as a comment to the article. Feedback should be shown according to the API response (success of failure).

Each comment tile should contain the name of its user, its content should be displayed, and a reply button. When clicking the reply button, `@{username}` should be inserted at the front of input field mentioned earlier. The `{username}` should be replaced with the actual username of the commenting user.

Use the following project structure:

- main file should be called server.js
- all database models should be in models/ directory
- all routes that respond with HTML should be in routes/ directory
- all API endpoints (routes that take and/or respond with JSON and are used by frontend JS) should be in routes/api/ directory.
- all templates should be in views/ directory - use EJS as a template language.
- all configuration parameters (port, session secret, database url) should be defined in env file and loaded via dotenv.

The UI must be simple, responsive, have header (with text logo, and navbar for page navigation and logout). Use Boostrap for styling.
```

GPT-Pilot 会在整理出任务之后给用户审查，如果任务有问题的话可以修改，不过无法直接中途插入一个新的任务。如果阶段性测试发现存在问题，可以请求增加新的调试环节。

对于数据库的有状态操作，GPT-Pilot 并没有给出方便的调试接口。例如，这里我设定第一个注册的账号是管理员，但要测试管理员的表现，必须手动在数据库先删除已有的用户。

同时，GPT-Pilot 先写了看文章列表的代码，但此时还没有生成文章的接口，因此需要手动在数据库创建文章。

### 简单原神：用 Rust 写四则运算解释器

| 指标 | deepseek-coder |
|-|-|
| 完成度 | 寄 |

GPT-Pilot 似乎部分操作（新建工程、调试工程等）和 Node.js / Bootstrap 等特定技术栈强耦合，因此即使我再三强调需要用 Rust 写命令行工具，GPT-Pilot 坚持要写一个完整的前后端，并且还计划加入用户登入登出功能。如此看来，GPT-Pilot 的泛用性并不强。

### 适用性：观者

GPT-Pilot 可以正常生成小型项目，也有强大的调试流程，不愧为「第一个真实的 AI 开发者」。但是，GPT-Pilot 也有一些小的问题，比如对大模型的输出格式控制得不太好。

同时，GPT-Pilot 的技术栈较为局限，前端只支持原生 JavaScript（虽然测试使用 React 的效果也不错），后端只支持 Node.js 或 Python，数据库也只支持 MongoDB，因此对部分课堂作业（例如飞机大战）以及部分编程竞赛（例如操作系统竞赛、编译器竞赛）并不适用。

GPT-Pilot 也没有上网的能力，无法像人一样搜寻、应用现有模板，这使得其作品看起来整体上比较复古。这和 GPT-Pilot 无法视觉地体验网站也有关系。

不过考虑到上述技术栈适用于大部分的快速原型场景，GPT-Pilot 值得「观者」的评价。

## SWE-Agent

这玩意每次调试都会跑 1 GB 流量来下载仓库和 Python 依赖（不能缓存），并且改镜像源也困难，遂放弃测试。

### 中等修复：TODO 跑个官方案例

### 简单修复：TODO 自己的 Python 案例

### 简单原神：实现获取 [dusk-phantom](https://github.com/5eqn/dusk-phantom) 中三角函数的类型

| 指标 | deepseek-coder |
|-|-|
| 完成度 | 寄 |

[dusk-phantom](https://github.com/5eqn/dusk-phantom) 是我先前用 Rust 写的一个音频处理插件。我把 [相关部分](https://github.com/5eqn/dusk-phantom/blob/fc930fa5f5a956ec66b9fdc0c200e55156e81642/src/lang/library.rs#L285) 替换成了 `unimplemented!()`，然后令 SWE-Agent 修复这部分。然而，该仓库似乎只对 Python 仓库有效：若令其修改本地 Rust 代码，无法产生任何修改。

### 适用性：

该工具的适用范围相比 GPT-Pilot 更为狭窄（只支持 Python），同时其实质上几乎只支持 OpenAI 的昂贵模型，且缺乏缓存机制和配置镜像的能力，对于我们而言实在难以使用。

## MetaGPT

MetaGPT 接入 deepseek 模型并不方便，以开发模式部署也并不方便。我遇到了以下的问题：

- 无法在 Python 3.12 安装，解决方法是 [使用 Python 3.9](https://github.com/aio-libs/aiohttp/issues/6898)
- 计费代码报错，解决方法是 [删了计费代码](https://github.com/geekan/MetaGPT/issues/1250)
- 运行时各种模块找不到，解决方法是一个个装（`clap`, `opencv`, `groundingdino-py`, `modelscope`）

### 简单前端：TODO 找个官方案例

### 简单全栈：待办列表 TODO 使用更好的提示

| 指标 | deepseek-coder |
|-|-|
| 完成度 | 问题多多 |
| 输入词符 |  91002 |
| 输出词符 | 13221 |
| 耗时 | 5 分钟 |
| 消费 / 元 | 0.12 |

MetaGPT 直接生成的代码会包含各种各样 **无法通过类型检查** 的抽象片段，令我感到十分震惊和痛心，也很无奈。同时，虽然需求里面是「Web 应用」，但 MetaGPT 只生成了一个 Python 语言的 Flask 后端。对于不明确的地方，MetaGPT 并没有反问我，而是直接开始编码。

第一次生成的版本有一个构造器参数不满，因此令其调试一次，能够修复问题。但 MetaGPT 把所有文件都重新生成了一遍！非常地浪费词元……

调试之后尝试创建用户会遇到数据库连接不存在的情况，我在没有手工调试的时候直接把错误消息给 MetaGPT，并没能成功修复这个问题。我手工调试代码，发现 MetaGPT 生成的数据库对象不是单例，但只让其中一个连上了数据库，其他的自然不存在连接。

### 简单原神：实现获取 dusk-phantom 中三角函数的类型

| 指标 | deepseek-coder |
|-|-|
| 完成度 | 寄 |

MetaGPT 似乎并没有先理解整个项目结构，而是先入为主地认为要实现一个新的正弦和余弦函数。最后以 `ValueError: Call with_srcs first.` 遗憾离场。

这可能是因为，MetaGPT 的增量编辑依赖于先前所生成的文档，因此事实上并无法对原先非 MetaGPT 接管的工程进行编辑。

同时，MetaGPT 似乎设计出来专为编写 Python 代码服务，硬编码了依赖列表处在 `requirements.txt`。在日志里智能体可以识别出语言是 Rust，但也无法正常修改。

### 适用性：B

MetaGPT 和 GPT-Pilot 类似，可以快速生成项目原型，并且消耗的词元比 GPT-Pilot 更少。同时，相比 GPT-Pilot 主打 JavaScript，MetaGPT 则更擅长 Python，实现了差异化。

然而，MetaGPT 的调试能力更弱，并且不会像 GPT-Pilot 一样对需求中不明确的地方询问用户（虽然这个功能可以被打开，只是需要用户自己编码才能启动这一功能）。这使得 MetaGPT 的实际使用体验差于 GPT-Pilot。

虽然如此，MetaGPT 本身还是个优秀的多智能体开发框架，GPT-Pilot 则更缺乏可扩展性。

## Aider

在该工具的大模型排行榜中，deepseek-chat 比 deepseek-coder 表现更好，但我将同时测试两者的表现。

### 简单原神：实现获取 dusk-phantom 中三角函数的类型

| 指标 | deepseek-chat | deepseek-coder |
|-|-|-|
| 完成度 | 完美 | 误删文件 |
| 输入词符 | 7282 | 5501 |
| 输出词符 | 115 | 1636 |
| 耗时 | 1 分钟 | 1 分钟 |
| 消费 / 元 | 0.008 | 0.009 |

这里为 Aider 指定了需要修改的文件，否则 Aider 可能不知道该修改什么。

试用 deepseek-coder 后我发现，Aider 似乎并不对该模型支持「预览仓库语法树」和「增量更新」的功能，可能是因为 deepseek-coder 难以输出预期的格式？对于 deepseek-chat，有了这些功能的加持，也能很好地输出代码。

### 中等原神：在 dusk-phantom 中加入正切函数

| 指标 | deepseek-chat |
|-|-|
| 完成度 | 寄 |
| 输入词符 | 36819 |
| 输出词符 | 7743 |
| 耗时 | 10 分钟 |
| 消费 / 元 | 0.05 |

Aider 似乎无法辅助大模型形成计划，而是只擅长修改单个地方。即使是强如 claude-3-opus 的大模型，在 [单文件代码重构](https://github.com/paul-gauthier/refactor-benchmark) 方面也只有 72.3% 的正确率，而我给出的场景需要修改 2 个文件。

在 10 分钟的激情尝试中，我遇到的问题主要分为以下两类：

- 格式有误：Aider 的修改基于搜索替换，被搜索的文字有时候抄不对，就无法修改
- 改的地方不够：Aider 无法引导大模型产生全局观，于是只修改少量地方

### 适用性：战士

Aider 比代码补全更远一步：可以自动指定要编辑的代码范围，并且填充编辑后的代码。由于 Aider 会事先分析仓库的语法树，从而让大模型理解仓库的大致结构，这种编辑通常能取得较好的效果。

然而，Aider 的自动化程度相比 GPT-Pilot 和 MetaGPT 仍有一定距离。由于 Aider 无法辅助大模型设定计划，Aider 往往只能修改代码中的一个地方。现实中的代码重构任务往往涉及多文件的修改，如果使用 Aider 的话必须一处一处修改，消耗的时间依然不少。

考虑到 Aider 是目前修改代码的最强选择，实用性并不低，因此 Aider 值得「战士」的评价。