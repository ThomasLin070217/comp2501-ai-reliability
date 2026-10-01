# 复现指南

> 历史 Python 流程归档。用户已要求所有数据处理使用 R；当前入口见 [R 复现指南](REPRODUCE.md)。以下原文保留用于追溯，不是当前课程分析运行步骤。

以下命令从仓库根目录执行。核心采集、审计、判分和 bootstrap 只使用 Python 3.9+ 标准库。绘图另需 Matplotlib；本轮绘图环境为 Python 3.13 和 Matplotlib 3.11.2（最终环境清单以实际导出为准）。

## 一条命令离线复算正式结果

```bash
python3 Peer_Misleading_Study/reproduce_main.py --out /tmp/comp2501-main-reproduction
```

输出目录必须为空。该入口只做装配、审计、判分、主比较、敏感性分析、用量汇总与案例导出，**不调用任何模型**。安装绘图依赖后追加 `--plots` 可生成图表和离线交互页面。下方给出分步骤命令。

## 离线：不调用模型、不需要凭证

```bash
python3 -m unittest discover -s Peer_Misleading_Study -p 'test_*.py' -v

python3 Peer_Misleading_Study/analyze.py \
  --questions Peer_Misleading_Study/data/dev_retained_questions.jsonl \
  --responses Peer_Misleading_Study/runs/dev_receivers/responses.jsonl \
  --adjudications Peer_Misleading_Study/data/dev_adjudications.json \
  --out /tmp/comp2501-dev-recomputed
```

正式轮因发现接口正常结束但正文不可判分的输出，采用单独的 `quality_analyze.py` 包装冻结分析器；规则见 [输出质量修订](protocol/output-quality-amendment.md)。它保存未过滤诊断、质量排除记录和完整配对主分析，并生成下游使用的临时 `analysis_responses.jsonl`。派生响应副本不入 Git，完整原始响应始终位于 `runs/main_receivers/`。

正式轮发生两次已记录的 HTTP 502，补试记录单独保存在 `runs/main_transport_recovery_01/` 与 `runs/main_transport_recovery_02/`。第二次中断后的时间延期见 `protocol/morning-continuation.json`，原清单和日志前缀均保留。先用离线装配器验证并组合成功响应，原失败保留；规则见 [传输补跑记录](protocol/transport-recovery.md)。报告中的主数值与区间应相同；重新生成时间戳不同不影响数值。复算输出放新目录，保留公开结果原件。

```bash
python3 Peer_Misleading_Study/assemble_receivers.py \
  --run Peer_Misleading_Study/runs/main_receivers \
  --recovery Peer_Misleading_Study/runs/main_transport_recovery_01 \
  --recovery Peer_Misleading_Study/runs/main_transport_recovery_02 \
  --continuation-amendment Peer_Misleading_Study/protocol/morning-continuation.json \
  --questions Peer_Misleading_Study/data/main_questions.jsonl \
  --materials Peer_Misleading_Study/data/main_frozen/materials.json \
  --out /tmp/comp2501-main-assembled

python3 Peer_Misleading_Study/quality_analyze.py \
  --questions Peer_Misleading_Study/data/main_questions.jsonl \
  --responses /tmp/comp2501-main-assembled/responses.jsonl \
  --adjudications Peer_Misleading_Study/data/main_adjudications.json \
  --out /tmp/comp2501-main-recomputed

python3 Peer_Misleading_Study/supplement.py \
  --responses /tmp/comp2501-main-recomputed/analysis_responses.jsonl \
  --grades /tmp/comp2501-main-recomputed/grades.json \
  --out /tmp/comp2501-main-recomputed/supplementary.json

python3 Peer_Misleading_Study/sensitivity.py \
  --questions Peer_Misleading_Study/data/main_questions.jsonl \
  --responses /tmp/comp2501-main-assembled/responses.jsonl \
  --adjudications Peer_Misleading_Study/data/main_adjudications.json \
  --caveats Peer_Misleading_Study/data/main_preanalysis_caveats.json \
  --out /tmp/comp2501-main-recomputed/sensitivity.json

python3 Peer_Misleading_Study/usage_ledger.py \
  --out /tmp/comp2501-main-recomputed/usage-ledger.json

python3 Peer_Misleading_Study/report_tables.py \
  --summary /tmp/comp2501-main-recomputed/summary.json \
  --supplement /tmp/comp2501-main-recomputed/supplementary.json \
  --sensitivity /tmp/comp2501-main-recomputed/sensitivity.json \
  --usage /tmp/comp2501-main-recomputed/usage-ledger.json \
  --out /tmp/comp2501-main-recomputed/statistics.md
```

```bash
python3 Peer_Misleading_Study/audit_run.py \
  --questions Peer_Misleading_Study/data/main_questions.jsonl \
  --materials Peer_Misleading_Study/data/main_frozen/materials.json \
  --run /tmp/comp2501-main-assembled
```

绘图需要额外安装依赖，可在独立虚拟环境中运行：

```bash
python3 -m venv /tmp/comp2501-plots
/tmp/comp2501-plots/bin/pip install -r Peer_Misleading_Study/requirements-plots.txt
MPLCONFIGDIR=/tmp/comp2501-matplotlib /tmp/comp2501-plots/bin/python \
  Peer_Misleading_Study/render_results.py \
  --summary /tmp/comp2501-main-recomputed/summary.json \
  --questions Peer_Misleading_Study/data/main_questions.jsonl \
  --responses /tmp/comp2501-main-recomputed/analysis_responses.jsonl \
  --materials Peer_Misleading_Study/data/main_frozen/materials.json \
  --out /tmp/comp2501-main-plots
```

HTML 自带图片和数据，下载后可离线打开。GitHub 默认显示 HTML 源码，不会自动托管交互页面。

## 复建材料选择

`select_main.py` 只读候选、原始材料及既有审阅记录，确定前 120 道合格题。`freeze_materials.py` 可离线重建冻结材料。审核者必须实际阅读材料；不能用脚本产生审阅身份或假装独立人工复核。原始快照筛选脚本 `collect.py` 会重写派生文件，若验证全流程请在副本中运行，并比较内容哈希。

## 重新调用模型

这是有成本的新实验，结果应写到新目录。凭证从环境变量 `DEEPSEEK_API_KEY`、`KIMI_API_KEY`、`MINIMAX_API_KEY` 读取；仓库不提供凭证。MiniMax 配置使用 HKU 课程转发服务，外部复现者未必有访问权限。不能直接用不同供应商模型替代后宣称完全复现。

`study.py` 默认仅输出计划，只有 `--execute` 才调用。默认截止时间是本轮的 2026-10-01 08:00（北京时间），以后调用须显式设定新截止和预算。不要修改既有运行清单后继续原目录。

```bash
python3 Peer_Misleading_Study/study.py receive \
  --questions Peer_Misleading_Study/data/main_questions.jsonl \
  --materials Peer_Misleading_Study/data/main_frozen/materials.json \
  --out Peer_Misleading_Study/runs/new_replication \
  --repeats 2 --max-calls 5040 --budget-cny 100
```

上面没有 `--execute`，不会收费。真正执行时需另行提供有效凭证、未来的 ISO 8601 `--deadline` 和明确执行参数。费用保护汇总当前实验目录下所有已有运行；不覆盖旧响应。HTTP 错误、截断或用量保护触发会停止批次，不能静默丢弃并重试。

## 可重复的是什么

可以逐条复核本轮原始请求，确定每个对照分支，重新判分并重算统计。无法保证未来服务端模型别名、硬件随机性和返回文字完全相同。来源网页也可能变化，因此保留固定题库、来源 URL、抓取哈希和审查决定；不公开新闻全文缓存。

辅助描述由 `supplement.py` 生成，覆盖指定错误采纳、C0 比较及各条件 token/延迟；`usage_ledger.py` 汇总全部阶段的 API 用量。`sensitivity.py` 同时输出原评分、已记录的替代评分和剔除争议题的结果，不用有利变体替换主分析。各脚本可用 `--help` 查看参数。

组员对来源、非标准答案及展示结论进行独立复核时，可按 [REVIEW_GUIDE.md](REVIEW_GUIDE.md) 记录自己的判决。脚本复算不代替语义复核。
