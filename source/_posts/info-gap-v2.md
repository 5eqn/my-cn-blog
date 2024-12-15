---
title: 手工提示工程，让我的 AI 信息收集助理变强 10 倍
date: 2024-05-14 16:06:52
tags:
- 编程
- AI
- 大模型
- Agent
---

在上期博客中，我演示了我的 [info-gap](https://github.com/info-gap/info-gap-server) 信息收集助理，但实际运行性能较差（1 小时才能获得 18 条候选，其中只有 5 篇真正符合要求）。在查看 AI 对话日志后，我发现我所运行的 LLaMA3-8b 模型把握不住 Instructor 库所强制的 JSON 格式的输出，因此我尝试 **手动设计所有的提示**，想看看性能会发生什么变化。没想到……

## 性能展示

题目和上次一样，依然是寻找一篇为大模型设计专用编程语言的文章。**但是，** 这次我要求大模型输出论文中提到的新语言的名字，用户可以根据这个名字快速排除掉一些不合法的推荐。下面展示的结果中，我排除掉了 9 个编程语言名为 None 的，以及 2 个提到已有语言的。

仅运行 **5 分钟** 后，AI 助理收集到了 13 条相关信息：

- CoRE: LLM as Interpreter for Natural Language Programming, Pseudo-Code Programming, and Flow Programming of AI Agents
  - 和新编程语言、大模型同时相关，用于基于大模型的自然语言编程
- Aptly: Making Mobile Apps from Natural Language
  - 没有涉及编程语言，Aptly 是框架
- AI Coders Are Among Us: Rethinking Programming Language Grammar Towards Efficient Code Generation
  - 和新编程语言、大模型同时相关，是对原有编程语言适配大模型的改良
- TypeFly: Flying Drones with Large Language Model
  - 和新编程语言、大模型同时相关，让大模型能控制无人机
- Prompting Is Programming: A Query Language for Large Language Models
  - 和新编程语言、大模型同时相关，用于设计提示词
- Ansible Lightspeed: A Code Generation Service for IT Automation
  - 和新编程语言、大模型同时相关，用于工业自动化
- Semantic Parsing for Complex Data Retrieval: Targeting Query Plans vs. SQL for No-Code Access to Relational Databases
  - 和新编程语言、大模型同时相关，用于有计划的数据库检索
- ReactGenie: A Development Framework for Complex Multimodal Interactions Using Large Language Models
  - 和新编程语言、大模型同时相关，作为多模态用户输入和编程语言的桥梁
- LLMs as Compiler for Arabic Programming Language
  - 和新编程语言、大模型同时相关，让大模型处理阿拉伯语编程语言
- LangGPT: Rethinking Structured Reusable Prompt Design Framework for LLMs from the Programming Language
  - 和新编程语言、大模型同时相关，用于结构化地生成提示词
- SPML: A DSL for Defending Language Models Against Prompt Attacks
  - 和新编程语言、大模型同时相关，用于防卫提示词攻击
- MoTCoder: Elevating Large Language Models with Modular of Thought for Challenging Programming Tasks
  - 没有涉及编程语言，MoTCoder 是个框架
- Efficiently Programming Large Language Models using SGLang
  - 和新编程语言、大模型同时相关，用于编排大模型

这次 13 篇中有 11 篇都符合要求！！

用表格对比一下各搜索方案的性能：

|方案|时间|有关篇数|无关篇数|准确率|
|-|-|-|-|-|
|pplx.ai|30 s|0|1|0%|
|pplx.ai (Pro)|1 min|2|0|100%|
|info-gap v1|60 min|5|13|28%|
|info-gap v2|5 min|11|2|85%|

注意 info-gap 是可以随时间扩展的！跑得越久，找到的信息越多。如果是常规的 AI 搜索引擎，很可能每次询问找到的都是相近的结果。

细心的读者可能会注意到，上次找到的 "What Algorithms can Transformers Learn?" 在这次并没有被找到。我在日志中发现，这篇文章被认为和新编程语言无关，因为文中涉及的编程语言 RASP 并不是被新发明的，所以上次连我自己都误判了？！

## 优化秘诀

本段可以结合 [源码](https://github.com/info-gap/info-gap-server) 理解。

提示词上，我借鉴了论文 "Prompting Is Programming: A Query Language for Large Language Models" 的思想，虽然是篇 2023 的论文，但意外地适合我现在使用的 LLaMA3-8b 模型。这可能是因为 GPT-4 出来后，大家都更倾向于探索 GPT-4 能力的极限，因此会在工作方法中更多地采用复杂的提示词，比如：

````
你的输出要符合以下 JSON 模板：

```json
{\n  "description": "Model of a proof of relevancy.",\n  "examples": [\n    {\n      "language_name": "",\n      "relation": "Although the article is about LLM, \\n                        there is no mention of a programming language."\n    },\n    {\n      "language_name": "PythonPlus",\n      "relation": "PythonPlus helps LLM to generate more accurate results."\n    },\n    {\n      "language_name": "RLHF-Script",\n      "relation": "RLHF-Script is a new programming language that helps \\n                        with the training of LLMs."\n    }\n  ],\n  "properties": {\n    "language_name": {\n      "description": "Name of the proposed programming language. Leave empty if not proposed.",\n      "title": "Language Name",\n      "type": "string"\n    },\n    "relation": {\n      "description": "Relation between the language and LLM.",\n      "title": "Relation",\n      "type": "string"\n    }\n  },\n  "required": [\n    "language_name",\n    "relation"\n  ],\n  "title": "Proof",\n  "type": "object"\n}\n\n
```

请确保返回一个上述 JSON 的实例，而不是模板本身。
````

而我选择了「大道至简」：

```
这篇论文符合用户要求吗？如果符合，请回答：

'符合，涉及的编程语言名字是 `name`，设计这个语言的目的是 `purpose`。'

如果不符合，请回答：

'不符合，因为 `reason`。'
```

事实证明，按照这种风格修改提示词可以大大提高 LLaMA3-8b 模型的响应质量。

同时，我实现了任务池架构，来搜索到更旧的论文（这也使得 SGLang 的论文被搜索到）。形象来说就是，我给了 AI 助理一个浏览器，可以打开一个新的标签页来搜索不同的关键字，也可以在现有的标签页里面翻页。

任务池架构是昨天写的，提示词优化是今天写的。