# COMP2501 · AI Reliability

**当 AI 误导 AI：错误同伴建议对 Double-check 的影响，以及结构化核验是否有帮助。**

我们先让模型独立回答事实题，再给它另一模型的建议。对比错误日期、错误日期加解释，以及完全相同建议下的结构化核验。正确目标建议作为辅助对照，检查“防御”是否同时阻碍真正的纠错。

## 当前进展 · 2026-10-03

**最新补充：[配对变化与240组AI核验](Submission_Pack/补充分析_2026-10-03.md)。** 同样的错误材料下，结构化核验的错误回答为258/719，普通接收为377/719，差−16.55个百分点；主要是撤回答案，而非找到正确日期。错误答案／错误答案加解释相对中性复核的错误率分别增加18.78／6.40个百分点。均为事后补充，保留原主指标、反例、模型差异与来源敏感性。按用户最新授权，AI核验已满足本次复核要求，不再以追加人工表格作为交付前提。实验是人机交互中错误前提的受控模拟，实际材料仍标为另一AI建议。

**检查资料包：[入口与提交说明](Submission_Pack/README.md) · [Proposal](Submission_Pack/proposal.md) · [英文报告PDF](Submission_Pack/COMP2501_report.pdf) · [演示稿](Submission_Pack/COMP2501_presentation.pptx) · [中文讲解](Submission_Pack/中文讲解.md)。**

新版演示稿16页、PDF报告9页，已合入最新补充结果并署名 **LINYUNIAN、PAN ZHENGYU**；[讲稿](Submission_Pack/speaker_notes.md)按双人18分钟展示安排。图表改用森林图、组成图与配对热力图等，见[图表阅读指南](Submission_Pack/图表阅读指南.md)。

新增[数学部分补充](Math_Supplement/README.md)：13道合格题、546条接收响应、71完整单元；原16题完整配对要求未达到，执行修订在接收前记录。16个初答字段错误中13个的解释已到达正确结果，不能把全部改善解释为逻辑能力提高。原事实主分析保持不变。

**人工复核：[中文Excel（第一批6题45条）](outputs/01a0e6a9-review/COMP2501_人工复核.xlsx) · [填写说明](Peer_Misleading_Study/reports/readable_review/README.md)。** 用户已填写第一批6题来源判断和45条回答判定；审阅者/日期、冲突标记及部分编码仍待整理，尚未完成分歧裁决或合并主评分。其余171条仍为后续队列。

**最新讨论与下一步：[答案正确、不确定性与核实声明](docs/review-discussion-2026-10-02.md)。** 答案字段正确不代表整段解释正确，表达不确定不等于答错，声称核实不等于有可验证证据。现已另存事后词语筛查与首批编码映射，原主评分未改；数学补充另行完成。

[补充评测规则 v1与独立验证轮建议](docs/evaluation-rubric-v1.md)：先对齐现有回答的判定，再按证据缺口决定新题复测。该建议是历史草案；随后执行情况以数学目录的冻结与修订记录为准。

新增：[课程R Markdown草稿](Peer_Misleading_Study/reports/course-report.Rmd) · [已渲染HTML](Peer_Misleading_Study/reports/course-report.html) · [51题独立复核包](Peer_Misleading_Study/reports/key_review_r/README.md) · [事后来源调查](Peer_Misleading_Study/reports/key_review_r/source-findings.md)。原复核模板保留空白，用户填写保存在上述Excel中；冻结主评分保留，争议另列敏感性分析。

**当前数据处理统一使用 R。** 从原始日志完成清洗、判分、统计、敏感性分析、绘图和报告生成；入口为 [reproduce_main.R](Peer_Misleading_Study/reproduce_main.R)，操作见 [R 复现指南](Peer_Misleading_Study/REPRODUCE.md)。查看 [R 报告](Peer_Misleading_Study/reports/main_r/report.md) 和 [R 结果页](Peer_Misleading_Study/reports/main_r/results.html)。历史 Python 输出保留供审计。

- 已完成网络文献检索、历史错误案例整理、固定题库下载与来源检查。
- 开发轮：15 道合格题，3 模型，315 次接收响应；初始正确 10/45。各组完整结果见开发报告。
- 正式轮已完成：120 题、**5,040 条返回响应**（含一条不可判分正文），实际 5,042 次请求；主分析纳入 719 个完整配对单元、5,033 条响应。
- 实测错题库：108 题至少一次初答错误，7 题六次初答全部判错；全部题与原文均保留。
- 离线两次复算的 30 项产物一致（忽略生成时间），18 项测试通过。延期与方法偏离已披露。
- 第一批已有用户填写的人工判定；完整独立复核、其他组员审核及分歧裁决尚未完成。原主评分中的来源审查和语义判断由 Codex 执行，不能称作人类标注。

本轮的实际执行授权见 [CHAT_CONTEXT.md · U10](CHAT_CONTEXT.md#u10)，取代旧暂停状态。AI 每次回答前须读完整最新上下文；入口规则见 [AGENTS.md](AGENTS.md)。

## 主要结果

错误日期附加解释未显示更高的带偏率（5/154 → 3/154；差 −1.30 个百分点，95% 区间 [-5.17, +2.31]）。同材料下结构化核验观察到 3/154 → 0/154，但事件少、区间触及零；拒答明显增多。面对正确建议，真正纠错由 76/322 降到 45/322（差 −9.63 个百分点，95% 区间 [-14.38, -5.25]）。不能把更少采纳错误直接解释成准确率提高。

先看[R正式报告](Peer_Misleading_Study/reports/main_r/report.md)、[R统计表](Peer_Misleading_Study/reports/main_r/effects.csv)、[实测错题库](Peer_Misleading_Study/reports/main/error_bank/README.md)和[交互结果页](Peer_Misleading_Study/reports/main/results.html)。本轮结论限于所选困难日期题、模型与参数；完整独立人工复核尚未完成。正确回答减少和弃答增加不能单独证明对用户更差；本实验尚未测量用户实际使用收益或误导损失。

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
Rscript Peer_Misleading_Study/reproduce_main.R --out /tmp/comp2501-r-reproduction
Rscript Peer_Misleading_Study/R/test_pipeline.R
```

当前离线数据处理只需 R、jsonlite 和 digest；绘图使用 R 自带功能。也可用 RStudio 打开根目录的 `.Rproj` 文件。离线复算不需要 API 密钥。HTML 下载后可离线打开，GitHub 不自动托管网页。历史采集代码、冻结记录和 Python 结果保留，不以迁移语言为由重新调用模型。上文历史区间的 R 重算差异见 [迁移校验](Peer_Misleading_Study/reports/main_r/validation.json)。

第三方题库保留原许可和归属，见 [数据声明](Peer_Misleading_Study/data/NOTICE.md)。不公开私人配置、聊天日志、密钥或新闻全文缓存。参考文献整理使用 citation-management 技能，其软件来源见 [文献说明](references/README.md)；工具使用不是准确率结论的证据。
