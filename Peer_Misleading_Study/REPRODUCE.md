# 用 R 复现数据处理与分析

新增事后复核入口：`Rscript Peer_Misleading_Study/R/prepare_key_review.R NEW_EMPTY_REVIEW_DIRECTORY`。脚本读取`reports/main_r`，输出关键案例匿名复核空表、协调者映射和单列的事后敏感性分析；拒绝覆盖非空目录。人工来源调查另存`reports/key_review_r/source-findings.md`，不由脚本虚构或自动更新。

课程草稿：在仓库根目录执行 `Rscript -e 'rmarkdown::render("Peer_Misleading_Study/reports/course-report.Rmd")'`，需要rmarkdown、knitr及Pandoc。报告读取现有R产物；完整原始数据重算继续按下方入口执行。HTML已生成，人工复核仍待完成。

用户要求原文：“所有的数据处理我需要用R 语言。”当前研究的数据处理、判分、统计、绘图和报告生成统一使用 R。

## 运行

从仓库根目录执行；也可以先用 RStudio 打开 `comp2501-ai-reliability.Rproj`，在 Terminal 中执行：

```bash
Rscript Peer_Misleading_Study/reproduce_main.R --out /tmp/comp2501-r-reproduction
Rscript Peer_Misleading_Study/R/test_pipeline.R
```

输出目录必须为空。流程读取已有记录，不联网、不调用模型、不需要密钥，也不会通过 R 调用 Python。依赖为 `jsonlite` 和 `digest`，图表使用 R 自带功能，输出 PNG 与 PDF。缺包时先在 R 控制台安装：

```r
install.packages(c("jsonlite", "digest"), repos = "https://cloud.r-project.org")
```

本轮实测环境为 R 4.6.1；完整版本见输出中的 `sessionInfo.txt`。脚本根据自身位置找到数据，不依赖本机绝对路径。

## 数据处理顺序

1. 从原始题库 CSV 重算 1,000 → 207 条机械筛选，保留采集前冻结的随机顺序和错误日期分配。
2. 根据原始材料响应和已有审阅记录，重建正式 120 题及 720 份冻结材料。语义审查决定作为输入，不能称为新的人类复核。
3. 读取原始接收日志，核对两次 HTTP 502 的相同请求补试，得到 5,040 条返回响应；实际 5,042 次请求另计。
4. 逐条重建请求，核对 5,040 个任务的分组、跨模型建议和六条平行分支隔离。
5. 在 R 中解析回答、标准化日期、自动判分；需要语义判断的记录应用已有 `main_adjudications.json`。原解析器对重复 JSON 键取最后一个值，R 明确保留这条规则。
6. 不可判分的一条输出连同其七响应单元整体移出主分析，保留全部原始与诊断判分，得到 719 单元、5,033 条响应。
7. 计算分模型及合并结果、正确改错、错误改对、弃答、覆盖率、已回答准确率、错误目标采纳、C0 对照与用量；按整道题做 5,000 次配对聚类 bootstrap。
8. 重算全部七种敏感性处理；开发轮单独重算。导出完整题目索引、错误库、全部案例索引、图表、Markdown 报告和离线 HTML。
9. 最后才读取历史 Python 输出用于迁移校验；它们不作为 R 主统计或判分的计算输入。

冻结前的随机分配、来源/语义审阅、已发生的 API 采集属于研究记录。迁移语言不重新抽题、不重写历史分配，也不重新收费采集。历史 Python 程序保留用于审计；当前分析入口是 R。旧 pilot 与本轮设计不同，留作历史材料，不并入当前主分析。

## 输出文件

| 文件 | 用途 |
|---|---|
| `report.md` / `results.html` | R 生成的报告及可离线打开的展示页 |
| `analysis_data.csv` | 5,033 行长表，含题目、参考答案、来源、模型原文及判分 |
| `all_response_grades.csv` | 全部 5,040 条返回响应的评分，含不可判分输出 |
| `graded_responses.csv` / `cells.csv` | 纳入评分表 / 719 行配对单元宽表 |
| `tables.csv` / `effects.csv` | 每组分母、比例 / 三项预定配对比较及区间 |
| `sensitivity.json` / `sensitivity_effects.csv` | 全部七种处理规则 |
| `transitions.csv` / `neutral_comparisons.csv` | 状态变化与中性复核对照 |
| `condition_usage.csv` / `usage-ledger.json` | 条件用量 / 全部阶段含失败的记账 |
| `source_audit.json` / `source_eligibility.csv` / `material_selection.csv` | R 重建的来源与材料筛选 |
| `blinded_format_review.json` | 隐藏模型和条件的原文复核队列，不显示已有语义判决 |
| `error_bank/` / `cases/` | 全部题目及实测错误 / 确定规则选出的案例与全部索引 |
| `development/` | 开发轮的独立重算结果 |
| `unfiltered_diagnostic/` / `output_quality.json` | 不过滤的诊断结果 / 质量排除记录 |
| `validation.json` / `bootstrap_comparison.csv` | 逐项迁移校验 / R 与历史区间差异 |
| `provenance.json` / `sessionInfo.txt` | 输入及代码文件哈希 / R 与包版本 |

CSV 是 R 导出的数据，不是 Excel 处理结果。在 RStudio 中可直接读：

```r
dat <- read.csv("Peer_Misleading_Study/reports/main_r/analysis_data.csv",
                stringsAsFactors = FALSE, fileEncoding = "UTF-8")
with(subset(dat, condition == "baseline"), table(provider, grade))
```

不要把普通逐行 bootstrap 用在 `analysis_data.csv` 上：同一题的模型、重复和分支有关联。正式脚本始终以题目为重采样单位。

## R 与历史数值的关系

所有主分析逐条判分、分母、计数和效应点估计应一致。R 的 `set.seed(25011001)` 与 Python 的同数字种子不会生成相同抽样序列，所以区间独立重算、逐项披露，不复制历史端点。R 的主比较区间为：RQ1 [-5.17, 2.31]；RQ2 [-4.46, 0.00]；正确建议纠错差 [-14.38, -5.25] 个百分点。当前结论与历史结果一致。

重复运行 R 时，数据表和分析 JSON 应一致；PDF 的创建时间等元数据可能不同。语言迁移在结果已知之后实施，不是新的预注册或新实验。独立人工复核仍未完成。执行偏离和研究边界继续见 [正式报告](reports/main-report.md)。

本轮 21 项 R 检查通过，两次独立运行的 43 个 CSV、JSON、JSONL 和 Markdown 产物逐字节一致，见 `reports/main_r/reproducibility.json`。可自行验证两次输出：

```bash
Rscript Peer_Misleading_Study/R/verify_reproduction.R FIRST_OUTPUT SECOND_OUTPUT
```

历史 Python 命令仅保留于 [归档说明](REPRODUCE_PYTHON_ARCHIVE.md)，不作为当前数据处理入口。
