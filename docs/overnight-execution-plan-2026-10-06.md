# COMP2501 overnight execution plan

Prepared 6 October 2026, Asia/Shanghai. Work window: tonight through the morning report around 09:00 on 7 October. This is an execution checklist, not a statement that unfinished experiments have produced results.

## Rules for every step

- Read `AGENTS.md` and the full `CHAT_CONTEXT.md` before work. Use R for data cleaning, scoring, statistics, plots, and report exports. Preserve original prompts, responses, keys, failures, and hashes.
- Keep the historical paired study, the new fact 500-question collection, the GSM-Plus mathematics v3 collection, and the UGMathBench candidate as separate datasets. Never pool different interfaces or question banks into one headline rate.
- A response is an error only when its final answer is actually wrong. Report correct, incorrect, and explicit abstention separately. Exclude technical failure, unknown delivery, ambiguity, and unscorable text from the error-rate denominator, with their counts visible.
- Before new model calls, verify the frozen bank, prompts, model identity, native search configuration, task IDs, quota, and recovery state. Stop on authentication, quota, or unknown-delivery errors. Do not retry because an answer is wrong. Do not persist credentials.
- Other chats are editing this shared repository. Read their status and integrate completed outputs, but do not overwrite their working files or duplicate their requests. Commit only a reviewed set of files; never commit credentials, `node_modules`, or unrelated work.
- Record each completed milestone in `docs/overnight-progress-2026-10-06.md`: time, input version/hash, operations, denominators, result, limitations, artifact paths, and Git commit if pushed. Mark an impediment instead of inventing a result.

## Current state at plan freeze

| Workstream | State | Evidence / gate |
| --- | --- | --- |
| Historical paired self vs cross study | Done; supplementary mathematics recovery has a protocol change | `Two_Model_Collection/reports/RESULTS_SUMMARY.md` |
| Human false-challenge follow-up | Done as a *post-answer* challenge, not a first-prompt misconception test | `Human_Challenge_Followup/RESULTS.md` |
| Fact 500-question initial collection | Partial recovery and scoring in another active chat; the user's later instruction there resumed fact completion. MiniMax currently hits HTTP 402 | `Initial_Response_Accuracy_Evaluation/processed/selfcheck_recovery_2026-10-06/` and collection status logs |
| GSM-Plus math v3 MiniMax initials | 500/500 collected; 496 scored, 17 incorrect | `Math_Crosscheck_500/collection_v3_minimax/` |
| GSM-Plus math v3 DeepSeek initials | Not found; paired follow-ups not started | Gate: same v3 IDs and independent answers |
| UGMathBench 500 candidate | Being constructed in another chat; no scored model run. Separate supplement until its source keys and protocol are frozen | `HKU_Undergrad_Math_100/benchmark_only_500/` |
| Presentation and Feishu document | Framework/older results exist; latest experiment coverage not reconciled | `Submission_Pack/`, Feishu COMP2501 Presentation |

## 1. Finish the available fact-data audit

1. Freeze a read-only inventory of the original 1,000 cells and every recovery route. Reconcile the original 930 scoreable answers, the original-gateway recoveries, and the direct-endpoint recoveries by task ID and final response hash. Investigate any count disagreement between README files before publishing an updated total.
2. Use R to grade all newly complete answers against the saved keys. Review ambiguous dates/names and every changed label against the raw response. Keep original-gateway and official-endpoint views separate because their tool execution may differ.
3. Export R-ready per-cell data, coverage and status table, model/source counts, and numerator/denominator for error, accuracy, and abstention. For unresolved MiniMax tasks, report the 402 block and do not run new calls until a functioning quota is independently verified.
4. Separately reconcile the neutral self-checks for newly recovered initially wrong answers. Do not turn a conditional wrong-answer follow-up into an all-question self-check rate.

**Done when:** every available complete answer has a review label, technical/unknown tasks are explicit, both route-specific summaries reproduce from R, and the old frozen result is unchanged.

## 2. Complete the matched mathematics initials

1. Use the already frozen GSM-Plus v3 bank for its existing 500 MiniMax initials. Validate the 500 IDs, key overlay, and 17/496 current error count from raw records.
2. Check whether DeepSeek has already answered the identical v3 bank in another run. If not, prepare one independent fresh-conversation answer per v3 question, with the same user question and native optional search. Freeze task order/configuration and run a small technical preflight before full collection.
3. Save each request, response, native tool history, stop reason, usage, and task ID. Recover only permitted technical failures; do not repeat a wrong answer. Score complete DeepSeek answers in R and generate the matched baseline index.
4. Treat the concurrently developed 500-question UGMathBench bank as a separate candidate. It cannot replace the already collected v3 MiniMax half of a matched experiment without starting a new paired collection for both models.

**Done when:** both model initials are keyed to the same v3 questions and a reproducible R preflight confirms which pairs are usable. If quota or source quality blocks this, report the exact coverage rather than claiming 500 matched pairs.

## 3. Run the double-check branches

1. For every eligible MiniMax initial, branch from the same initial conversation into: (a) neutral self-check and (b) natural cross-check using DeepSeek's independently obtained actual answer. Do not label synthetic text as DeepSeek output.
2. For MiniMax initially correct cases, construct a separate, clearly logged *synthetic* wrong peer answer and rationale. Verify the supplied target is false before calls, freeze all materials, then run the controlled misleading-peer branch.
3. Keep the initial, donor, and final response IDs linked. Score all finals in R with correct/incorrect/abstain/technical states; inspect every correct-to-wrong transition against the raw text.

**Done when:** branch coverage and valid matched denominators are known, and R can reproduce self vs natural cross and wrong-peer transitions. If complete collection is infeasible overnight, analyze only the frozen completed subset and label it interim.

## 4. Test misconceptions in the *first* human prompt

1. This is distinct from the existing post-answer false-challenge study. Define a selected set of questions with verified keys and an earlier correct model answer; record selection before new calls. For each question/model, create two fresh independent first prompts: neutral question and the same question prefaced by one scripted, explicitly false human interpretation/answer with a short rationale.
2. Keep question wording, model settings, search availability, and grading rule matched. Validate every false premise and avoid accidentally supplying the correct answer in either prompt. Freeze prompts and randomized task order before collection.
3. Score the paired finals in R, including abstention and failures. Report neutral-correct to misconception-wrong examples and the paired error difference with question-level uncertainty. Do not describe scripted text as real human participants or infer which phrase caused the effect.

**Done when:** a frozen prompt set, raw paired responses, R grading, and a clearly bounded conclusion exist. If this cannot be completed reliably by morning, leave the research question open rather than substituting the post-answer challenge result.

## 5. Analyze and audit all four research questions

1. Use R to make separate tables for domain, receiving model, condition, unique questions, completed pairs, and correct/incorrect/abstain/technical counts. Average repetitions within question/model before model-level summaries where applicable.
2. For each comparison, calculate wrong-answer probability and paired differences. Show correct-to-wrong and wrong-to-correct counts and their source condition. Use uncertainty intervals for population-level claims; keep descriptive case examples separate.
3. Cross-check each plotted numerator and denominator against the row-level data and recalculate all headline percentages. Audit explanation-quality claims separately from final-answer correctness. Document source-key corrections and sensitivity analyses.

**Done when:** a reviewer can trace every sentence in the conclusions to a named CSV, R script, and experiment protocol.

## 6. Build the morning submission snapshot

1. Update the English report, PPT/PDF, chart captions, and Feishu presentation text from the same R result tables. Replace placeholders only with completed results; mark unfinished work explicitly. Reconcile the title and method language with the actual bank, model, and number of responses.
2. Check slides visually, confirm LINYUNIAN and PAN ZHENGYU, verify source/citation and course deliverable requirements, and distinguish historical results from new runs.
3. Review the Git diff, keep unrelated active-chat edits out of the commit, and push the validated project files to GitHub. Verify the remote revision and include its commit in the progress log.
4. At approximately 09:00 Asia/Shanghai, give the user a concise report: completed work, per-question conclusions with exact denominators, unresolved quota/coverage issues, artifacts and GitHub state, and the next necessary decision. Stop the night monitor after that report.

**Done when:** the morning report is supported by synchronized, inspectable artifacts. A partial result is still a valid report if it clearly states what remains unfinished.
