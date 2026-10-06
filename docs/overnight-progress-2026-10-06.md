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
