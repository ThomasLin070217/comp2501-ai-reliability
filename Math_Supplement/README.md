# 数学补充实验

本目录独立于原120题事实主实验。研究问题和C0–C5分支沿用原设计，不测联网搜索或两个独立agent综合。

**完成的是部分描述性补充，不是原定完整平衡实验。** 16个候选中13个通过全部同伴材料预检；整数控制题缺失，原`viable=false`保留。接收前的修订见[执行补记](protocol/partial-supplement-disposition.json)。546条接收响应中17条不可判分，保留71个完整单元497条响应。

- [结果和局限](reports/supplementary/report.md)
- [答案字段与推理的区别](reports/supplementary/semantic-review.md)
- [题目及参考答案](QUESTIONS.md)
- [计划](PLAN.md)、[执行偏离](protocol/deviations.md)、[材料审核](review/material-decisions-supplementary.csv)
- [完整原文及判分](reports/supplementary/graded_responses.csv)、[分模型/题型表](reports/supplementary/tables.csv)

55个初答正确单元在各组都未改错，因此不能用本补充证明哪种方式更能抵抗误导。C0中性复核已达到68/71，C2为65/71，C3为67/71。16个初答字段错误中13个的解释已到达正确结果，必须区分输出一致性和推理正确性。语义筛查由Codex事后完成，非独立人工复核。

## 离线复现（R，无API费用）

在仓库根目录运行。R依赖：jsonlite、digest、ggplot2；在线采集另需curl。

```sh
Rscript Math_Supplement/R/test.R
Rscript Math_Supplement/R/analyse.R supplementary /tmp/comp2501-math-reproduction
```

`R/review_supplement.R`从既有判分和保存的AI判断映射导出事后语义注释，并非重新进行独立AI/人工审查。原始请求、响应、使用量和材料保留在`runs/`。

**不要为了离线复现运行prepare、freeze或collect脚本**：前两者用于历史生成/冻结，最后一个会调用模型。实时重跑需要自行提供环境变量凭据与新预算，模型版本变化意味着结果未必完全相同。
