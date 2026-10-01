# 独立复核填写说明

请独立判断，不先阅读项目结果或其他复核者的意见。文件已隐藏模型、实验条件和历史评分；回答正文仍可能透露提示特征。
1. 先打开responses_to_review.csv：提取最终答案，response_kind填answer/abstain/unscorable/ambiguous；答案与解释矛盾、解释事实问题各填yes/no/uncertain。此时proposed_grade留空。
2. 再打开sources_to_review.csv：参考答案也可能错误。核对题目实体、事件、日期精度；优先官方与独立资料。source_verdict填supported/conflicting/ambiguous/unavailable，记录verified_answer、来源URL及简短证据。
3. 回填响应proposed_grade：correct/incorrect/abstain/unscorable/uncertain。原任务只评分最终日期，解释附带问题单列；若答案与弃答措辞冲突，保留冲突并说明。
4. 不修改packet_id、source_id、题目、原始回答和给定来源。填写项目内reviewer_id与日期；不要填写敏感身份信息。每位复核者使用独立副本，不互看结论。
5. 无法确认可填uncertain，不强行猜。完成后交回两张表，协调者另行记录分歧，不覆盖原评分。
此包用于定向关键案例复核，不代表全量随机审核。所有判断栏初始为空；AI准备材料不等于人工审核完成。
