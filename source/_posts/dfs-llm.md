---
title: AI | 大语言模型工作原理概述
date: 2023-11-03 15:44:13
tags:
- 草稿
---

本文主要讲解 GLM-130B [^1] 的工作原理，可能并不适用于 GPT-3.5、GPT-4 等闭源模型，但依然能大致反映大语言模型的机制。对于有一定耐心的读者，我强烈推荐阅读原论文。

## 参考论文

- GLM-130B [^1]
  - GLM [^2]
    - Transformer [^3]
      - LayerNorm [^4]
    - Parallelism [^5]
    - GeLU [^6]
    - Shuffling [^7]



[^1]:http://arxiv.org/abs/2210.02414
[^2]:https://arxiv.org/abs/2103.10360
[^3]:https://arxiv.org/abs/1706.03762
[^4]:https://arxiv.org/abs/1607.06450
[^5]:https://arxiv.org/abs/1909.08053
[^6]:https://arxiv.org/abs/1606.08415
[^7]:https://papers.nips.cc/paper/2019/file/dc6a7e655d7e5840e66733e9ee67cc69-Paper.pdf
