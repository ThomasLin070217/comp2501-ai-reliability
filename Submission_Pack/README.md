# COMP2501 检查与提交资料包

先读[中文讲解](中文讲解.md)，再看演示稿。所有文件基于已有真实日志，原事实主分析未改。

**2026-10-03更新：PPT、PDF及HTML已合入[交互误导与弃答补充分析](补充分析_2026-10-03.md)，署名为LINYUNIAN、PAN ZHENGYU。** 新结果明确标为事后补充，保留原主分析和反例。240组AI核验已完成，无需再补填人工复核表。旧ZIP仍是历史快照，请从此目录获取最新文件。

|文件|用途|
|---|---|
|[proposal.md](proposal.md)|按Moodle proposal三个字段组织；description 202词，低于300词|
|[COMP2501_presentation.pptx](COMP2501_presentation.pptx)|16页可编辑英文演示稿，含最新结果、两人署名、来源与讲稿备注|
|[speaker_notes.md](speaker_notes.md)|双人18分钟讲稿节奏及建议讲解分配，另留2分钟问答|
|[COMP2501_report.pdf](COMP2501_report.pdf)|报告阅读版|
|[report.html](report.html)|可离线打开的HTML报告|
|[report.Rmd](report.Rmd)|R Markdown报告源文件|
|[COURSE_REQUIREMENTS.md](COURSE_REQUIREMENTS.md)|课程PDF原文、对应材料、尚待学生确认事项|
|[evidence/](evidence/)|R导出的图表数值、来源哈希与校验信息|

## 提交前需要本人完成

1. 在Moodle核实课程当前截止和提交状态。本地课程PDF写proposal为10月3日23:59，展示为10月7/8日，但PDF没标年份；本次Moodle读取超时，不能声称查过最新公告。**proposal未提交会影响展示资格**。
2. proposal不是上传整个ZIP：按实际Moodle quiz字段填入对应文字。项目姓名已按用户提供写为LINYUNIAN、PAN ZHENGYU；学号与门户资料仍由本人填写，未自动提交。
3. 组员读报告并核对实际分工；注明AI协助。Claude Code审查使用配置的Kimi后端，不是Anthropic Claude模型。
4. 按用户10月3日最新要求，本次复核由AI完成，不再要求补填人工表格。历史工作簿中的三个“-”及其他空字段原样保留，不伪造人工裁决；报告如实标明AI定向复核的范围和限制。
5. 数学只完成13题的部分描述性补充，未达到原定完整配对要求。不要把报告中的局限删掉，也不要把答案字段错误全部称作推理错误。

## R复现

从解压后的仓库根目录执行，不需要API key：

```sh
Rscript Peer_Misleading_Study/R/test_pipeline.R
Rscript Peer_Misleading_Study/reproduce_main.R --out /tmp/comp2501-fact-repro
Rscript Math_Supplement/R/test.R
Rscript Math_Supplement/R/analyse.R supplementary /tmp/comp2501-math-repro
Rscript Peer_Misleading_Study/R/interaction_posthoc.R
Rscript Peer_Misleading_Study/R/interaction_report.R
```

事实输出目录必须不存在或为空。依赖和处理细节见[事实R指南](../Peer_Misleading_Study/REPRODUCE.md)和[数学说明](../Math_Supplement/README.md)。报告重渲染需要rmarkdown、knitr、jsonlite、Pandoc；PPT/PDF构建器只排版R产物，不参与实验统计。

ZIP是仓库的指定提交快照，包含代码、原始日志、冻结材料、审核记录及本资料包。文件可在GitHub直接查看；密钥、私人配置和构建缓存不包含在内。课程要求不表示必须上传所有这些附件，以Moodle当前页面为准。

## 交付检查与预算

历史事实R检查21项通过；数学冻结代码与原始数据保持不变。最新补充的22项R产物及报告两次复算一致。更新版PDF八页、演示稿十六页逐页检查，未声称在Microsoft PowerPoint应用内检验。旧ZIP解压复现记录仅适用于原快照。

本次付费实验保守估价与CLI审查估价合计约¥15.43，低于新增¥100预算；这不是账单。HKU课程接口178,794 tokens另列，现金单价未核实。历史费用另计，详见[evidence/budget.json](evidence/budget.json)。
