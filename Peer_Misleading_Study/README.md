# AI 同伴误导与结构化核验实验

本实验按原总计划的两个问题执行：错误答案附带解释，是否更容易把正确答案带偏？面对同一份建议，结构化核验能否减少这种损害，同时保留接受正确建议的能力？

**2026-10-01 状态：**正式轮完成 5,040 条返回响应（实际请求 5,042 次）。一条正文不可判分，按透明修订移出其七响应单元，主分析为 719 个配对单元、5,033 条响应。开发轮 315 条另列。

主要发现：结构化核验减少了错误建议采纳，但增加拒答；正确建议的真正纠错率由 23.60% 降到 13.98%。对原本正确回答的带偏事件很少，不能声称已证明普遍防错效果。

## 阅读入口

- **当前 R 分析入口：**[R 报告](reports/main_r/report.md)、[结果页](reports/main_r/results.html)、[运行说明](REPRODUCE.md)、[迁移校验](reports/main_r/validation.json)。从原始日志重新计算；下列早期 Python 产物保留为历史审计记录。

- [正式报告](reports/main-report.md)、[完整统计](reports/main/statistics.md)、[交互结果页](reports/main/results.html)
- [108 道实测出错题及全部 120 题索引](reports/main/error_bank/README.md)、[逐条原文案例](reports/main/cases/cases.md)
- [离线复算验证](reports/main/verification.json)与[请求审计](reports/main/collection/audit.json)

- [公开论文中的错误案例与题库来源](research-sources.md)
- [执行方案及所有偏离](protocol/execution-amendment.md)
- [开发报告](reports/development-report.md)与[执行偏离复核](protocol/deviation-audit.md)
- [本轮真实的错误论据案例](reports/material-quality-cases.md)
- [课程 proposal 草稿](reports/course-proposal-draft.md)
- [复现说明](REPRODUCE.md)、[数据字典](DATA_DICTIONARY.md)
- [正式冻结记录](protocol/formal-receiver-freeze.json)、[最终题目](data/main_questions.jsonl)、[样本筛选审计](data/main_selection_audit.json)

## 对照条件

每个模型先独立回答同一道题。六个分支都从这条相同初始回答出发，互不看见其他分支。

| 条件 | 新增信息 | 复核方式 |
|---|---|---|
| baseline | 无 | 首次独立回答 |
| C0 | 无 | 中性复核 |
| C1 | 另一 AI 的错误日期 | 中性复核 |
| C2 | 同一错误日期及其解释 | 中性复核 |
| C3 | 与 C2 完全相同的材料 | 结构化核验 |
| C4 | 正确日期及其解释 | 中性复核 |
| C5 | 与 C4 完全相同的材料 | 结构化核验 |

研究者指定相邻日期作为错误目标，再让模型生成支持它的解释。生成者与接收者不同；生成者身份不展示给接收者。本实验没有联网检索，也没有多轮自由辩论。正确目标控制的日期经过来源检查，但不能保证生成解释的每一句背景断言都真实。

## 数据流

1,000 条 SimpleQA Verified 原始题 → 207 条日期候选 → 开发 24 条与其余 183 条分离。

开发材料检查保留 15 题。正式候选来源检查保留 165 题；按预定顺序，前 154 题中 34 题因材料质量排除，保留 120 题，剩余 11 题备用。没有依据正式接收模型是否上当挑题。

120 题 × 3 模型 × 2 重复 = 720 个配对实验单元；每单元 7 响应，共 5,040 次。**独立抽样单位仍是题目，不能把响应数写成样本量。**

## 复现边界

完整保存原始请求、原始响应、失败、token、来源审查、内容排除和评分决定。离线复算不需要密钥。未来重新调用相同模型别名不保证逐字相同：供应商可能更新模型，温度为 0.6，接口没有设置种子。

本项目的来源审核和语义复核由 Codex 完成，尚无独立人工审核。题库是有选择的困难日期事实子集，不能代表所有实际任务，也不能选出普遍最佳模型或核验方法。
