# COMP2501 检查与提交资料包

先读[中文讲解](中文讲解.md)，再看演示稿。所有文件基于已有真实日志，原事实主分析未改。

**2026-10-03新增：[交互误导与弃答补充分析](补充分析_2026-10-03.md)。** 已用R完成719单元配对分析，并由Codex完成240组、451条不同回答的定向语义核验。按用户最新要求，无需再补填人工复核表。原PDF/HTML/演示稿是10月2日检查版，未包含本次事后补充；展示新增结论时请配合本补充，不能把它称为原预注册结果。旧ZIP也是历史快照，不包含本次新增文件。

|文件|用途|
|---|---|
|[proposal.md](proposal.md)|按Moodle proposal三个字段组织；description 202词，低于300词|
|[COMP2501_presentation.pptx](COMP2501_presentation.pptx)|12页可编辑英文演示稿，表格/图表可编辑，含来源与讲稿备注|
|[speaker_notes.md](speaker_notes.md)|9分钟核心讲稿节奏；另列双人18分钟扩展安排|
|[COMP2501_report.pdf](COMP2501_report.pdf)|报告阅读版|
|[report.html](report.html)|可离线打开的HTML报告|
|[report.Rmd](report.Rmd)|R Markdown报告源文件|
|[COURSE_REQUIREMENTS.md](COURSE_REQUIREMENTS.md)|课程PDF原文、对应材料、尚待学生确认事项|
|[evidence/](evidence/)|R导出的图表数值、来源哈希与校验信息|

## 提交前需要本人完成

1. 在Moodle核实课程当前截止和提交状态。本地课程PDF写proposal为10月3日23:59，展示为10月7/8日，但PDF没标年份；本次Moodle读取超时，不能声称查过最新公告。**proposal未提交会影响展示资格**。
2. proposal不是上传整个ZIP：按实际Moodle quiz字段填入对应文字，并填写真实姓名、学号、组员资料。我们没有代填身份或提交。
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

原事实R检查21项通过；数学冻结采集/评分代码哈希未变，分支请求重建核对通过；ZIP解压后的事实/数学R复算与主仓库关键结果相同。PDF六页、演示稿十二页已渲染逐页检查，未声称在Microsoft PowerPoint应用内检验。

本次付费实验保守估价与CLI审查估价合计约¥15.43，低于新增¥100预算；这不是账单。HKU课程接口178,794 tokens另列，现金单价未核实。历史费用另计，详见[evidence/budget.json](evidence/budget.json)。
