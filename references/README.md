# 参考文献与检索记录

检索日期：2026-09-30。用途：为课程项目提供方法地图，不是系统综述或最新模型评测。

## 如何取得与检查

1. 用 OpenAlex 搜索自我纠错相关研究，并通过网页检索寻找方法的代表论文。
2. 以 arXiv、ACL Anthology、正式会议论文集、Nature 和 OpenReview 的原始记录核对研究问题与结论；二手博客不作为技术结论的依据。
3. 使用 citation-management 的 `extract_metadata.py` 从 CrossRef/arXiv 自动提取 15 条元数据；正式出版记录可取得时替换预印本记录。
4. 记录已核验的出版信息、元数据缺失和来源，见 `metadata_enrichment.json`；`references.bib` 的 citation key 保留稳定，key 中年份可能是预印本年份，实际引用年份以字段 `year` 为准。
5. 用 `validate_citations.py` 检查 BibTeX 字段。字段检查不能证明论文结论正确或完整，因此方法地图保留适用范围，不照搬跨基准提升数字。

`openalex_discovery.json` 只是广泛发现阶段的原始搜索结果，不是最终入选清单。方法地图引用的 14 篇研究及 1 篇软件说明收录于 BibTeX。少量计划中的背景引用还通过原文链接和数据卡提供，不声称 BibTeX 覆盖仓库全部外部链接。

## 建议阅读顺序

| 主题 | 文献 | 阅读时重点 |
|---|---|---|
| 数据质量 | [FineWeb](https://arxiv.org/abs/2406.17557) | 过滤、去重与数据选择的消融 |
| 指令与偏好训练 | [InstructGPT](https://proceedings.neurips.cc/paper_files/paper/2022/hash/b1efde53be364a73914f58805a001731-Abstract.html) | 人类偏好不只评价事实正确性 |
| 强化学习训练推理 | [DeepSeek-R1，Nature](https://www.nature.com/articles/s41586-025-09422-z) | 训练方法与所测任务；不直接解释我们当前 API 型号 |
| 检索增强 | [RAG](https://arxiv.org/abs/2005.11401) | 引入外部知识的方式 |
| 工具执行 | [PAL，ICML](https://proceedings.mlr.press/v202/gao23f.html) | 语言模型负责建模、解释器负责执行 |
| 推理计算 | [Test-time compute，ICLR](https://openreview.net/forum?id=4FWAwZtd2n) | 题目难度和预算如何影响收益 |
| 采样聚合 | [Self-consistency](https://arxiv.org/abs/2203.11171) | 多候选不等于多个独立知识来源 |
| 验证器 | [Let's Verify Step by Step](https://arxiv.org/abs/2305.20050) | 过程监督与结果监督 |
| 自我纠错的局限 | [Cannot Self-Correct，ICLR](https://openreview.net/forum?id=IkmD3fKBPQ) | 没有外部反馈的特定设置 |
| 结构化事实核验 | [CoVe，ACL Findings](https://aclanthology.org/2024.findings-acl.212/) | 草稿、独立核验问题与修订；我们不是完整复现 |
| 训练自我纠错 | [SCoRe，ICLR](https://openreview.net/forum?id=CjwERcAU7w) | 训练得到的能力与一句提示的区别 |
| 多模型附和 | [CONSENSAGENT，ACL Findings](https://aclanthology.org/2025.findings-acl.1141/) | 讨论成本、附和和提示优化 |
| 区分改答案的原因 | [Not All Flips Are Conformity，2026 预印本](https://arxiv.org/abs/2606.00820) | 自行波动、立场影响与解释说服 |
| 不确定性 | [Teaching Models to Express Their Uncertainty](https://arxiv.org/abs/2205.14334) | 校准是需要验证的能力，不是随口报置信度 |

## 软件方法来源

本次调研的参考文献元数据提取与验证使用 Scientific Agent Skills 的 citation-management 技能。按该工具的引用要求，记录以下软件方法来源；它不作为“提升模型准确率”的证据。

Timothy Kassis, Vinayak Agarwal, Yuhuan He, Darshil Patel, Aubrey M. Brueckner. **Scientific Agent Skills: A Library of Procedural Knowledge for Research Agents** (2026). [当前 arXiv 记录](https://arxiv.org/abs/2609.00065)。检索时记录为 v2；链接指向当前版本，不固定版本后缀。

工具原始说明和脚本未复制进本仓库；BibTeX、来源记录和验证结果可以单独使用。
