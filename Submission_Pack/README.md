# COMP2501 最终整合资料包

**4 October 2026：已合入全部完成的实验与最新补测。** 总标题为 *Can We Trust AI More After Cross-Checking?*，署名 **LINYUNIAN、PAN ZHENGYU**。先读[中文讲解](中文讲解.md)，再按讲稿浏览PPT。

|文件|用途|
|---|---|
|[COMP2501_presentation.pptx](COMP2501_presentation.pptx)|20页可编辑英文PPT：18页主讲、2页统计备份|
|[COMP2501_report.pdf](COMP2501_report.pdf)|12页英文报告，含最新结果、方法与敏感性附录|
|[report.html](report.html)|可离线浏览的完整报告|
|[report.md](report.md) / [report.Rmd](report.Rmd)|GitHub阅读版与R Markdown源文件|
|[speaker_notes.md](speaker_notes.md)|18分钟双人展示安排，另留2分钟问答|
|[中文讲解](中文讲解.md)|实验机制、最新结论和案例的中文解释|
|[图表阅读指南](图表阅读指南.md)|各图分母、区间、数学纵轴与旧实验区别|
|[COURSE_REQUIREMENTS.md](COURSE_REQUIREMENTS.md)|本地课程PDF原文映射；Moodle当前状态尚未验证|
|[proposal.md](proposal.md)|此前proposal草稿，未以本次改稿覆盖用户正在编辑的Word文件|

## 最新证据

自然检查补测为100道此前研究过的事实题、41道本项目未用过的CHAMP数学题。三模型各两次，3932次HTTP尝试、3893完整输出、3829可判分回答。事实主要差异+0.69个百分点，数学−2.01个百分点，两项调整后区间均含零。不能继续用此前小样本的−4.90个百分点作为最新扩样结论。

原受控错误建议的+18.78/+6.40个百分点结果保持为单独的事后分析。新提示对照显示，无额外弃答提醒的核验没有明确收益；加回提醒少错10.95个百分点，同时正确减少、弃答增加。报告区分少错、多答对、保留不确定性，没有为了预期结论改分或筛题。

数学硬题缺失、来源争议、AI评审分歧与原先未支持的假设都保留。旧小样本和早期数学字段问题移至附录，没有合并为独立重复证据。原始数据与冻结评分不变。

## 离线复现

从仓库根目录运行，无需API key，不新增模型调用：

```sh
Rscript Submission_Pack/prepare_integrated.R
Rscript Submission_Pack/integrated_notes.R
Rscript -e 'rmarkdown::render("Submission_Pack/report.Rmd", quiet=TRUE)'
```

排版入口为 `build_slides.mjs` 和 `build_pdf.py`。前者使用 `@oai/artifact-tool`，后者使用 ReportLab；两者只排版R产物，不做实验统计。PPT构建需要按本地运行时设置 `NODE_PATH`、`RUNTIME_NODE_MODULES`、`SKILL_DIR`、`RUNTIME_PYTHON`；输出先存私有构建目录，通过检查再复制到当前文件。详细数据复算见[补测复现入口](../Followup_Validation/REPRODUCE.md)与[原事实R指南](../Peer_Misleading_Study/REPRODUCE.md)。

七张报告图与原生PPT图表读取R准备的数据，来源哈希及精确软件版本在 `evidence/integrated_*`。旧构建器和旧成品可由Git历史恢复。旧的 `prepare_natural_presentation.R` 属于此前49题版本，不应用来生成当前整合报告。

## 使用范围与课程提交

按本地课程PDF，双人展示18分钟、问答2分钟；没有固定页数要求。当前PPT的前18页按此排练，19–20页仅供追问。课程当前截止时间、Moodle状态及提交记录未验证，本次没有代为提交。作者姓名已填写，学号与门户字段仍需本人核对。

AI协助及复核范围已披露，不称为完整独立人工验证。个人Word proposal及其锁文件不修改、不加入此次提交。已知付费保守估价累计¥56.92，非账单，HKU现金价格未知、令牌另列。本次材料整合没有新增模型调用。

最新ZIP快照名为 `COMP2501_submission_2026-10-04_integrated.zip`，位于仓库上一级Project目录。它用于保存完整版本，不意味着Moodle要求上传整个ZIP。旧日期ZIP是历史快照。
