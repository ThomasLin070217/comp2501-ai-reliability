# 数据字典与审计链

## 当前 R 输出

当前分析由 `reproduce_main.R` 及 `R/` 下的脚本完成，保存于 `reports/main_r/`。下文对历史 Python 文件的描述为审计记录。R 从原始日志重新处理，不读取旧评分表来产生新评分。

- `analysis_data.csv`：主分析的 5,033 行长表，含原始回答、题目、参考答案、来源、判分、条件及配对单元 ID。
- `all_response_grades.csv` 保留全部 5,040 条判分；`graded_responses.csv` 只保留主分析完整单元。
- R 表中的 `repeat_id` 对应原始日志中的 `repeat`（后者是 R 保留字），取值仍为 0/1；`cell_id` 为题目、接收模型和重复号的组合。
- `automatic_grade` 保存自动解析结果；`grade` 为应用既有语义审阅后的结果；`unscorable` 标记已审阅的不可恢复输出。
- `cells.csv` 每行一个完整七分支单元；`tables.csv` 每行一个模型×条件；`effects.csv` 每行一个模型×预定比较。
- `ci_low_pp`、`ci_high_pp` 为 R 重算的区间端点；空值表示无分母或退化 bootstrap，查看 `bootstrap_status`，不能当作零区间。
- `summary.json` 的 `tables` 和 `effects` 在 R 输出中为行数组，与历史嵌套 JSON 结构不同；内容意义及分母不变。
- `blinded_format_review.json` 在 R 中重建，仍隐藏模型、条件和任务 ID；`target_adopted` 的缺失值不等同于 FALSE。
- 文件完整清单见 [R 复现指南](REPRODUCE.md)。

## 题目

`data/source_snapshot.csv` 是固定上游版本的 1,000 题快照。`source_manifest.json` 保存下载地址、SHA256、筛选原因和固定种子。许可及归属见 `data/NOTICE.md`。

`candidates.jsonl` 保存全部 207 条机械筛选候选；`main_questions.jsonl` 是最终 120 条正式题，`dev_retained_questions.jsonl` 是 15 条开发题。每行一个 JSON 对象。

| 字段 | 含义 |
|---|---|
| question_id / source_id | 本项目 ID / 上游 ID |
| question / original_question | 发给模型的问题 / 原始问题 |
| gold / gold_parts | 参考日期字符串 / 标准日期数组，顺序为年、月、日 |
| granularity | year、month 或 day；决定评分精度 |
| false_target / false_parts | 预先生成的相邻错误日期及其标准数组 |
| topic | 上游主题分类 |
| source_urls / verified_source_url | 上游来源 / 本轮审核采用的来源 |
| candidate_order | 固定随机候选顺序 |
| split / original_split | 当前阶段 / 原候选分区 |
| pairing_direction | 非自身生成者的两个循环方向之一，0 或 1 |
| original_pairing_direction | 正式平衡重排前的方向，保留审计 |
| difficulty_evidence | 只有基准层面的困难证据，不伪造逐题历史错误 |
| source_review | Codex 来源检查，非独立人工审核 |

`dev_source_reviews.jsonl`、`main_source_reviews.jsonl` 保存来源判定。`evidence_fetch_audit.json` 只保存抓取状态、哈希等，不把字符串命中当作语义证明。

## 同伴材料

`data/*_frozen/materials.json` 的键为 `question_id:provider:correct|wrong`；值含 `answer`、`explanation`。每题六槽。`freeze.json` 保存题目与材料哈希、冻结时刻、审阅性质。

`main_material_rejections.json` 将生成任务 ID 映射到明确排除理由。`main_content_reviews.json` 将材料键映射到所审核任务、材料哈希、时间与检查范围。`main_selection_audit.json` 记录全部 165 个候选的去向；内容检查不是每条背景断言的完整事实核查。

## 调用与响应

`runs/<阶段>/manifest.json` 固定模型、参数、提示、代码哈希、输入哈希、重复数、保护预算及停止时刻。

接收顺序的实际随机数种子由冻结代码 `receive()` 指定：DeepSeek 2501、Kimi 2502、MiniMax 2503。配置中的 `order_seed: 2501` 字段未被代码读取，不能据此声称三个模型使用完全相同的任务顺序。这些种子只控制本地请求顺序，不是供应商生成采样种子。

`attempts.jsonl` 在实际请求发出前落盘；`responses.jsonl` 在返回后落盘。未完成请求不自动重发，失败不删除。

| 字段 | 含义 |
|---|---|
| task_id | 唯一任务 ID；材料为题目:模型:真值:a候选号，接收为题目:模型:r重复号:条件 |
| kind / provider | material 或 receiver / 调用供应商 |
| question_id / repeat / condition | 题目、重复号、实验条件 |
| generator | 提供建议的另一个模型；不是接收者 |
| request / request_sha256 | 实际请求体及其规范化哈希；不含认证头 |
| raw_response / text | 原始供应商返回体 / 抽取出的回答正文 |
| status / finish_reason | ok、error、incomplete；接口错误与知识错误分开 |
| timestamp / latency_seconds | UTC 请求开始时间 / 调用耗时 |
| usage_raw / input_tokens / output_tokens | 供应商原用量及标准化 token 数 |
| cost_upper_cny | 保守付费预算保护估计；不是账单，HKU 为 0 表示未定价而非免费 |
| model_returned | 接口实际返回的模型标识 |
| baseline_id / suggestion_id / suggestion_sha256 | 初始回答与冻结建议的追溯链接 |

哈希有两类：文件 SHA256 对原字节计算；`digest()` 对按键排序的 UTF-8 JSON 计算。两者不能直接互换。`audit_run.py` 会逐条重建实际请求并检查分支隔离、配对、材料、任务完整性与时间顺序。

## 评分与分析

`reports/<阶段>/grades.json` 每个 task 一条：`grade` 为 correct、incorrect、abstain、pending 或 api_error；`target_adopted` 表示是否恰好采用预设错误日期。`review_id` 对题目 ID 和回答文本做哈希。

`blinded_format_review.json` 去掉模型、条件、生成者及任务 ID，供处理非标准输出；这是隐藏元数据的队列，不等于已有独立盲审。审阅结果须另存 `data/*_adjudications.json`，记录理由和审阅者。

`summary.json` 包含各模型及 pooled 结果、完整配对单元数、分母、两项主比较与正确建议控制。正确转错误只以初始正确单元为分母；错误转正确只以初始错误单元为分母；拒答单列。置信区间按题目聚类重采样，固定 5,000 次、固定种子；零观察差异的退化情形不报告虚假的 [0,0] 精确区间。

`supplementary.json` 保存指定错误采纳、覆盖率、已回答准确率、与 C0 的描述性比较及每组用量。`sensitivity.json` 同时保存主评分、已记录的替代评分、排除争议来源题的版本；不选择有利版本替换主结果。所有比例必须显示分母。

## 不可判分输出与完整配对分析

`quality_analyze.py` 是有记录的采集后质量修订，未改动冻结 `analyze.py`。`output_quality.json` 列出原始响应数、不可判分输出、移出分析的全部七条 task ID、原始及分析内容哈希。原始响应不删除、不重试。`unfiltered_diagnostic/` 保留原冻结分析器的含 pending 输出，仅用于审计，不能当作有效完整分析。

`data/main_adjudications.json` 中 `output_quality=unscorable_output` 表示正文确实不能恢复完整答案且未明确拒答；`status=pending` 刻意保留，不改成事实错误。其他 `disputed` 和 `alternative_status` 字段记录合理的替代判法。`sensitivity.json` 额外报告不可用输出作为运行失败或非回答计入的变体，这些不是对缺失事实答案的猜测。

`incorrect` 是日期任务未答对：包含明确错误日期，也包含未明确拒答却未达到题目所需精度的答案。它不是逐句事实性标签。精度不足与“非空答案但明确拒答”的争议均保存替代判法，不能只报告有利口径。

## 传输补跑与分析装配

`runs/main_transport_recovery_01/` 保存 HTTP 502 后的一次显式补试，原失败在 `main_receivers/` 保留。`assemble_receivers.py` 只允许用完全相同请求的成功补试对应替换“没有返回答案的传输失败”，不允许替换答错、拒答或不可用的已返回正文。它把可用响应组合成离线派生文件，并逐条调用冻结请求审计。

`reports/main/collection/assembly.json` 区分全部实际 API 尝试、原始失败、选用响应和补跑对应关系。派生 `responses.jsonl` / `attempts.jsonl` 不入 Git，可用复现命令重建；原始日志始终入库。`usage-ledger.json` 从各原始运行目录记账，不重复计算装配副本。发生网关错误时没有返回 token 用量，汇总只计已报告的 token，不能把缺失用量解释为确定零消耗。


## 早间续跑与实测错误库

`protocol/morning-continuation.json` 记录用户续跑原话、旧/新截止、原日志前缀哈希、剩余调用上限及原清单哈希。`continue_receivers.py` 不改原清单、提示或既有响应，只给新追加记录增加 `continuation_amendment_sha256`。`runs/main_transport_recovery_02` 保存第二条 HTTP 502 的单次恢复，原失败保留。

`protocol/morning-analysis-note.json` 在正式聚合前记录额外时间敏感性规则：排除请求跨越原截止的配对单元；不把前后不同题目的表现差异说成模型漂移的因果证据。

`reports/main/error_bank/all_questions_observed.jsonl` 汇总所有正式题在完整配对主分析中的实际初答。`observed_initial_error_bank.jsonl` 是其中 `observed_initial_error=true` 的便利视图，不是独立抽样题库。`initial_answers` 保留模型、重复、原文、判分理由、时间和请求哈希；`initial_observations` 是该题实际纳入的初答数；`all_six_initial_answers_incorrect` 仅在六次初答齐全且均为 incorrect 时为真。错误率分母不能从筛选后的错误库反推。

`review_queue.py` 只导出未审阅非标准响应，隐藏条件/模型/任务标签，不自动产生人工复核身份。`reproduce_main.py` 是整个离线分析的命令入口，不调用 API。
