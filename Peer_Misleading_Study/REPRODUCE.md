# 复现指南

以下命令从仓库根目录执行。核心采集、审计、判分和 bootstrap 只使用 Python 3.9+ 标准库。绘图另需 Matplotlib；本轮绘图环境为 Python 3.13 和 Matplotlib 3.11.2（最终环境清单以实际导出为准）。

## 离线：不调用模型、不需要凭证

```bash
python3 -m unittest discover -s Peer_Misleading_Study -p 'test_*.py' -v

python3 Peer_Misleading_Study/analyze.py \
  --questions Peer_Misleading_Study/data/dev_retained_questions.jsonl \
  --responses Peer_Misleading_Study/runs/dev_receivers/responses.jsonl \
  --adjudications Peer_Misleading_Study/data/dev_adjudications.json \
  --out /tmp/comp2501-dev-recomputed
```

正式轮完成后的对应输入为 `data/main_questions.jsonl`、`runs/main_receivers/responses.jsonl` 和 `data/main_adjudications.json`。报告中的主数值与区间应相同；重新生成时间戳不同不影响数值。复算输出放新目录，保留公开结果原件。

```bash
python3 Peer_Misleading_Study/audit_run.py \
  --questions Peer_Misleading_Study/data/main_questions.jsonl \
  --materials Peer_Misleading_Study/data/main_frozen/materials.json \
  --run Peer_Misleading_Study/runs/main_receivers
```

绘图需要额外安装依赖，可在独立虚拟环境中运行：

```bash
python3 -m venv /tmp/comp2501-plots
/tmp/comp2501-plots/bin/pip install -r Peer_Misleading_Study/requirements-plots.txt
MPLCONFIGDIR=/tmp/comp2501-matplotlib /tmp/comp2501-plots/bin/python \
  Peer_Misleading_Study/render_results.py \
  --summary Peer_Misleading_Study/reports/main/summary.json \
  --questions Peer_Misleading_Study/data/main_questions.jsonl \
  --responses Peer_Misleading_Study/runs/main_receivers/responses.jsonl \
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
