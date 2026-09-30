# COMP2501 · AI Reliability

**当 AI 误导 AI：错误同伴建议对 Double-check 的影响，以及结构化核验是否有帮助。**

我们先让模型独立回答事实题，再给它另一模型的建议。对比错误日期、错误日期加解释，以及完全相同建议下的结构化核验。正确目标建议作为辅助对照，检查“防御”是否同时阻碍真正的纠错。

## 当前进展 · 2026-10-01

- 已完成网络文献检索、历史错误案例整理、固定题库下载与来源检查。
- 开发轮：15 道合格题，3 模型，315 次接收响应；初始正确 10/45。各组完整结果见开发报告。
- 正式轮：120 题、720 槽建议、提示词和评分代码已冻结；正在采集 **5,040 次接收响应**。
- 独立人工复核尚未完成。来源审查和需要语义判断的评分由 Codex 执行，不能称作人类标注。

本轮的实际执行授权见 [CHAT_CONTEXT.md · U10](CHAT_CONTEXT.md#u10)，取代旧暂停状态。AI 每次回答前须读完整最新上下文；入口规则见 [AGENTS.md](AGENTS.md)。

## 阅读顺序

1. [新实验入口](Peer_Misleading_Study/README.md)：研究问题、条件与数据流。
2. [公开论文中 AI 已出错的题目／情景](Peer_Misleading_Study/research-sources.md)：区分历史实测案例、困难题库与新实验。
3. [执行修订与冻结协议](Peer_Misleading_Study/protocol/execution-amendment.md)：原计划如何落地、质量排除、预算和方法偏离。
4. [开发报告](Peer_Misleading_Study/reports/development-report.md)与[课程 proposal 草稿](Peer_Misleading_Study/reports/course-proposal-draft.md)。
5. [离线复现](Peer_Misleading_Study/REPRODUCE.md)与[数据字典](Peer_Misleading_Study/DATA_DICTIONARY.md)。
6. [减少错误的方法地图](docs/accuracy-methods.md)、[原实验总计划](docs/experiment-plan-v1.md)、[参考文献](references/README.md)、[协作方式](CONTRIBUTING.md)。

## 数据与解释范围

新题来自固定版本的 Google SimpleQA Verified。1,000 题中按预定规则选出 207 道日期事实候选；开发／正式题分离，并在看到正式接收结果前完成来源及建议质量筛选。所有排除、失败生成、原始请求和响应均保留。

**5,040 次响应对应 120 道题，不是 5,040 个独立样本。** 分析按题目聚类，分别报告答错、拒答、正确改错、错误改对和区间。研究者指定错误日期来构造压力测试，因此不能估计另一个模型在日常使用中自然犯错的概率。无外部检索，不能据此判断 RAG 或工具验证的效果。

正确目标控制只保证目标日期经过来源检查；生成解释仍可能含未经证实的背景。本实验不寻找普遍最佳模型或通用防错方法，不把未观察到差异当作等效。

## 旧 pilot 保留

[旧 pilot](Double_Check_Pilot_2026-09-30/试运行报告.md)为 30 题、3 模型、540 次有效响应；初始回答全部正确，存在天花板效应。旧设计测试错误用户观点，与本轮错误 AI 解释设计不同，不能合并响应统计。其题库、原始响应、判分边界和导入哈希保持可追溯。

## 复算与许可

```bash
python3 -m unittest discover -s Peer_Misleading_Study -p 'test_*.py' -v
```

核心实验和统计只需 Python 标准库；绘图另需 Matplotlib。离线复算不需要 API 密钥。HTML 下载后可离线打开，GitHub 不自动托管网页。实时调用仅在显式 `--execute`、有效截止、预算和环境凭证齐备时进行。

第三方题库保留原许可和归属，见 [数据声明](Peer_Misleading_Study/data/NOTICE.md)。不公开私人配置、聊天日志、密钥或新闻全文缓存。参考文献整理使用 citation-management 技能，其软件来源见 [文献说明](references/README.md)；工具使用不是准确率结论的证据。
