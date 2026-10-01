# 独立复核包：先读说明

这是事后定向抽取的关键案例，不是随机质检样本。不能由本包估计全部题目的评分错误率。
范围：51 道题、68 个模型–题目–重复单元；216 条重点回答。所有七分支的476条记录另存协调者目录。
三次初答正确而C2错误的单元全部保留；正确建议下48次失去纠错、17次新增纠错全部保留，不只展示一个方向。

## 给复核者
1. 协调者只发送 reviewer/ 文件夹（内含独立说明），不发送本页、coordinator/、统计结果或AI复核笔记。不得假称彻底盲法：回答正文可能泄露提示特征。
2. 先独立填写 responses_to_review.csv 的答案提取、response_kind（answer/abstain/unscorable/ambiguous）及两个解释问题字段（yes/no/uncertain）。第一遍不看来源表，proposed_grade暂留空。
3. 再打开 sources_to_review.csv。参考答案只是待核实基准，不是真值保证。检查原始来源并查官方或独立来源；source_verdict填写supported/conflicting/ambiguous/unavailable，附来源及简短证据。
4. 回填 proposed_grade：correct/incorrect/abstain/unscorable/uncertain。精度按题目年/月/日要求。若答案字段与解释冲突，保留提取值并标冲突，不自行消除歧义。
5. reviewer_id使用可识别的项目内代号，不填敏感身份信息；填写日期与理由。不确定可保留uncertain。两名复核者用各自副本，不互看结论；若只有一名也如实记录。

## 给协调者
所有人工判断初始为空。AI准备此包、AI核对来源均不等于人工完成。收齐后按packet_id/source_id联结，保留每人的原始副本；分歧另表裁决，不能覆盖冻结主评分。
coordinator/response_mapping.csv提供原始task_id、条件、历史等级和参考答案；case_index.csv列选择原因。
本轮尚无人工返回，尚未改变正式分数。source-findings.md和posthoc_effects.csv是AI事后调查，不属于预注册或原七种敏感性分析。

## R复现
从任意工作目录运行 Rscript /绝对路径/Peer_Misleading_Study/R/prepare_key_review.R /新的空输出目录。默认输出reports/key_review_r；已存在非空目录时停止，避免覆盖人工填写。
来源调查是人工可读的独立文件，不由脚本虚构或联网重建。报告中的准确率仍采用冻结日期评分；解释质量没有预设的量化评分。
