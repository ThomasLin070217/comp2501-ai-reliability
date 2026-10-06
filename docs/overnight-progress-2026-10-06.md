# COMP2501 overnight progress log

Time zone: Asia/Shanghai. Execution plan: [overnight-execution-plan-2026-10-06.md](overnight-execution-plan-2026-10-06.md). Append milestones with their evidence and limitations; do not replace earlier entries.

## 6 October, 23:36 — baseline and active work

- The historical self/cross paired report and post-answer false-human-challenge study are complete as separate supplementary experiments.
- GSM-Plus v3: MiniMax's 500 initial answers are collected; 496 are scoreable, including 17 wrong. DeepSeek's matched v3 initials and all planned v3 follow-ups are not yet present.
- Fact initial collection: the original 930 scoreable answers remain frozen. Another active chat has resumed recovery under a later explicit user instruction; current MiniMax official-endpoint continuation received HTTP 402. Available recovery views and their distinct endpoint provenance must be reconciled before publication.
- A different active chat is constructing a 500-question UGMathBench candidate. It is not the same bank as the GSM-Plus v3 collection and has no scored new-model run.
- The presentation framework is committed, while newer datasets and artifacts are local and not yet all on GitHub. Feishu presentation text has not been updated to the current protocol and results.

Next gate: audit the shared workspace and current collection status; process available fact records in R, while avoiding duplicate requests or edits to another active chat's files.

## 6 October, 23:37 — plan published and monitor started

- The execution plan and this log were committed as `ed6b36b` and pushed to `origin/main`. Only these two files were included in that commit; the other chats' uncommitted datasets and presentation edits remain local.
- The thread heartbeat `COMP2501 夜间推进与早晨报告` is active. It checks the plan every 15 minutes, records material progress, stays quiet on unchanged status, and is instructed to report around 09:00 on 7 October before pausing itself.

## 6 October, 23:52 — fact supplement discrepancy reconciled

- Input: the frozen 1,000 fact cells; original-gateway recovery view; MiniMax official-endpoint supplement; later `direct_minimax_review_decisions_v2.csv`; and the raw resumed final for `fact500:FS_77c95f87fd:minimax:single`. Source file hashes are in `Night_Audit_2026-10-06/derived/fact_direct_supplement_resumed_audit.json`.
- Finding: the prior official-endpoint summary contained six direct-route graded responses; the later review and raw final establish a seventh, an explicit abstention, previously counted as technical incomplete. A prose addendum's statement of four graded direct responses is also stale; the decisions CSV has seven (4 correct, 1 incorrect, 2 abstain).
- New **separate official-endpoint overlay**, reproduced by `Night_Audit_2026-10-06/R/reconcile_fact_direct_resume.R`: DeepSeek 44/500 wrong (8.80%); MiniMax 78/470 wrong (16.60%), with 354 correct, 38 abstain, 29 technical incomplete and 1 unscorable. The old initial and original-gateway summaries are unchanged. These are different scored subsets and the MiniMax supplement used another endpoint, so this is not a matched model comparison.
- Block: MiniMax's resumed collection status is `stopped_quota`, HTTP 402, with 31 tasks unattempted in that invocation. No new model call was made in this audit.
- GitHub: the R script, derived overlay, audit hashes, and explanation were pushed in commit `1c756f2`; the other active chats' files were not included.

## 7 October, 00:00 — agent runbook revised

- The existing overnight plan was rewritten in place as an executable agent runbook so the active heartbeat keeps reading the same path. It now states the four research questions' required evidence, prerequisite gates, exact dataset versions, stop conditions, R-only analysis rule, acceptance criteria, and morning handoff format.
- Current fact collection is frozen at the **available** 1,000 cells: 500 DeepSeek and 470 MiniMax scoreable, with 29 MiniMax technical gaps and one unscorable. The frozen file uses seven separately labelled official-endpoint MiniMax completions. T1 is therefore an offline R verification/export; no new fact calls are scheduled.
- The 500-question UGMathBench/HKU candidate belongs to another active chat and its first version failed key/solvability/difficulty review. It is not substituted for the collected GSM-Plus v3 MiniMax baselines. The other chat is revising the candidate; this runbook does not edit or collect it.
- No new model answer or new effect estimate was produced by this documentation revision.
- The active `comp2501` heartbeat prompt was updated to use the revised runbook as its authority: the fact sample is frozen, v3 and UGMathBench remain separate, and the human misconception comparison starts in the **first** prompt.

## 7 October, 00:07 — T1 R reconstruction of frozen facts

- Inputs: initial 1,000 fact cells and 931 semantic decisions; 70-target recovery decision table; 37-target direct-route review and its later v2 decision; the native `final.json` records for all 40 selected recovery answers; and the frozen snapshot manifest. Hashes are in `Night_Audit_2026-10-06/derived/fact_frozen_rebuilt_R_audit.json`.
- `Night_Audit_2026-10-06/R/rebuild_fact_freeze.R` independently rebuilt the available-response view in R. All 1,000 rows × 11 columns matched the frozen snapshot; the 33 original-gateway and seven official-endpoint selected answers matched native complete finals.
- Rebuilt results: DeepSeek 423 correct, 44 wrong, 33 abstain / 500 scoreable (8.80% wrong); MiniMax 354 correct, 78 wrong, 38 abstain / 470 scoreable (16.60% wrong), plus 29 technical gaps and one unscorable. This does not rank models on a matched subset and does not independently verify all reference keys.
- No new model call was made. The fact freeze remains in force.
- The same R pass kept self-check conditional: among the original 112 initially wrong answers, 27 corrected, 79 stayed wrong and six abstained; one separate recovered DeepSeek wrong answer stayed wrong. The new R table is `Night_Audit_2026-10-06/derived/fact_selfcheck_conditional_R_summary.csv`. It must not be reported as an all-question post-self-check rate.
- GitHub: the R rebuild, row-level export, summaries, hash audit and updated runbook were pushed in commit `91fd8cd`; unrelated active-chat files were not staged.

## 7 October, 00:16 — T2 DeepSeek v3 initial collection started

- Input: the pinned GSM-Plus v3 500-question bank and existing MiniMax v3 initial records. `Math_Crosscheck_500/collection_v3_deepseek/R/prepare.R` froze 500 DeepSeek task IDs, source/key/review/code hashes, model settings and a randomized first-100 checkpoint. An R preflight checked the credential without printing it or sending a request; all 500 DeepSeek IDs and question texts match the v3 MiniMax bank, with no answer-key field in the task manifest.
- A two-task technical pilot returned two HTTP 200 `end_turn` replies, both reporting model `deepseek-v4-pro`; no native search was chosen. The provisional usage guard was ¥0.0138, not an invoice. The full collector then resumed from those two tasks. At the first status check: 12/500 task responses logged, zero unknown deliveries, zero native searches; the run was still active. No math answers have been scored yet.
- Raw attempts, complete provider responses, stop reasons, token/search usage and a live status file are under `Math_Crosscheck_500/collection_v3_deepseek/runs/`. The frozen collector stops on quota/auth errors and does not retry a wrong answer. Incomplete `pause_turn` responses will need a separate same-turn continuation plan before grading.

## 7 October, 00:28 — T2 DeepSeek v3 initials complete and R matched index

- Frozen inputs: `Math_Crosscheck_500/question_review_v3/`, `collection_v3_minimax/derived/final_scores_500.csv`, and `collection_v3_deepseek/protocol/`. DeepSeek run status: 500/500 complete HTTP 200 `end_turn` responses, 500 attempts, zero empty replies and unknown deliveries, one native search call. The conservative usage guard is ¥3.3991, not a provider bill. Raw attempts, native HTTP responses and finals are append-only under `collection_v3_deepseek/runs/`; hashes appear in the R-generated manifests.
- `R/export_scoring_queue.R` flagged 455 last-number/key matches, 43 differences and two previously recognized prompt ambiguities. Because last-number extraction can capture irrelevant trailing numbers, all 43 differences plus both ambiguous items were inspected in full, and a deterministic 60/455 matching-item sample was read. `R/adjudicate_initials.R` records this review method and individual discordance notes. Frozen-key DeepSeek grades: 496 correct, two wrong, two ambiguous, hence 2/498 wrong (0.40%) among scoreable answers. One wrong is clear tree-as-flower counting (order 355); the other (order 12) has a plausible alternative commission reading and receives a post-hoc exclusion sensitivity of 1/497 (0.20%). The 455 positive-screen explanations have not each been independently proven.
- `R/build_matched_baseline.R` verifies all 500 DeepSeek IDs/order/question texts match MiniMax's run exactly. MiniMax's pre-existing grades remain 479 correct, 17 wrong, four unscorable; the common-scoreable subset has 496 questions. These are independent first answers; the comparison does not establish a double-check effect. Raw-aligned grades, matched row set and source hashes are in `collection_v3_deepseek/derived/`.
- Next gate: freeze and preflight the T3 same-MiniMax-conversation self and natural cross branches; do not silently reuse v2 hashes or mix in the separate HKU/UGMathBench candidate. GitHub sync is pending staged-file review in this entry.
