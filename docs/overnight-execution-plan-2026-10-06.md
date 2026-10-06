# COMP2501 agent runbook: next tasks and morning handoff

Updated 7 October 2026, Asia/Shanghai. This is the canonical to-do file for the overnight heartbeat. The live status is in [`overnight-progress-2026-10-06.md`](overnight-progress-2026-10-06.md); the status below is a snapshot, not a substitute for checking the files again. Aim to hand over an evidence-backed report around 09:00 on 7 October. If a step is blocked, finish independent work and report the block instead of inventing data.

## Start every agent run here

1. Read `AGENTS.md`, the **entire** `CHAT_CONTEXT.md`, this file, and the progress log. Inspect Git status and the current status/manifest files before editing or calling a model.
2. Check whether another chat owns or is actively editing the same workstream. Reuse completed records; do not launch a duplicate collection or overwrite its files. Work in a distinct output directory and stage only reviewed files in Git.
3. Pick the first **ready** unchecked task below. Record its input versions/hashes and a bounded next milestone. Skip tasks already complete. A stale `running` status is not proof of a live process; use logs and task records to decide.
4. On each meaningful result, append to the progress log: local time, input version/hash, unique questions, task/pair denominator, correct/incorrect/abstain/technical counts, conclusion and limits, files, and pushed commit. Quiet checks do not need a message.

### Non-negotiable rules

- **All current data processing uses R:** cleaning, joins, answer scoring, statistics, bootstrap, figures, and report-data exports. Historical Python outputs remain for provenance, but must not be presented as the new R analysis. Other languages may lay out the PPT/PDF only after R has produced the numbers and charts.
- Keep these datasets separate: historical paired experiments; the new fact 500 × 2 collection; GSM-Plus mathematics **v3**; and the separate UGMathBench/HKU candidate. Do not pool their response rows or model routes into one rate.
- `N = correct + incorrect + explicit_abstain`. `error_rate = incorrect/N`; `noncorrect_rate = (incorrect + explicit_abstain)/N`. Show abstention separately. Technical failure, unknown delivery, prompt ambiguity, and unscorable response are neither wrong nor abstention and stay visible outside `N`. Correctly identifying an actually underdetermined question is **correct**, not abstention.
- Make paired claims only on the same question × receiving model × repetition with both required conditions scoreable. Report unique questions separately from response or pair counts. Average repeated answers within question/model before model means; do not treat repeated calls as independent questions.
- Do not force search in the prompt. Each model may choose its native web-search tool. Record whether it searched. Preserve full requests, native tool history, responses, stop reasons, parameters, usage, task IDs, and hashes. Retry only a documented technical failure under the frozen protocol, never an incorrect answer. Stop affected calls on 401/402/429 or unknown delivery; do not switch endpoint/model silently.
- Keep API credentials and authorization links out of the repository, logs, slides, and user messages. Never stage another chat's unreviewed files, `node_modules`, or unrelated changes. Before a Feishu edit, use the personal profile and verify it with `lark-cli whoami --profile personal` as required by the global user instructions.

## What each research question requires

| Question | Primary evidence to produce | What it must not be confused with |
| --- | --- | --- |
| RQ1: Does double-checking decrease wrong-answer probability? | Same-baseline paired `initial`, neutral `self`, and natural `cross` final-answer counts and error rates, by facts vs math | A raw count of all API replies or a comparison on different question subsets |
| RQ2: Which practical check works best? | On the common scorable set, compare initial/self/natural; report cost/coverage, abstention, and correctness separately | Claiming one method universally wins from a selected benchmark |
| RQ3: Can a wrong AI peer introduce an error? | Natural initially-correct receiver + actually-wrong independent donor subgroup, plus a separately labelled controlled synthetic-wrong-peer branch; inspect each correct→wrong case | Calling scripted false material an actual DeepSeek reply or generalizing a single example into a population rate |
| RQ4: Can a person's false preconceived idea mislead the **first** answer? | Fresh-conversation neutral first prompt vs first prompt containing a scripted false user interpretation, on the same question/model | The completed **post-answer** human-challenge study; no real human participants were recruited |

## Snapshot and ownership gate

| Workstream | Current state | Agent action now |
| --- | --- | --- |
| Historical self vs cross and post-answer human challenge | Completed supplemental results in `Two_Model_Collection/reports/RESULTS_SUMMARY.md` and `Human_Challenge_Followup/RESULTS.md` | Preserve protocol/uncertainty limits; do not rerun |
| New facts, 500 questions × two models | **Frozen and independently reconstructed in R**: DeepSeek 500 scoreable, MiniMax 470 scoreable, 29 technical gaps and one unscorable; seven MiniMax replies used a separate official endpoint | Keep original and mixed-route rates separate; **no new fact calls** unless the user changes this freeze |
| Fact recovery reconciliation | R overlay completed at `Night_Audit_2026-10-06/`; MiniMax direct endpoint stopped on HTTP 402 | Compare the R overlay with the new frozen snapshot; preserve original gateway-only and original 930-answer views |
| GSM-Plus math v3 | MiniMax 500/500 collected, 479 correct, 17 wrong, two ambiguous prompts and two unscorable answers; DeepSeek matched v3 run not found | Prepare/check DeepSeek's same-question independent initial run; never substitute older v2 or CHAMP/MATH inputs |
| Mathematics follow-ups | Self/natural/manipulated v3 branches not collected | Start only after the matched v3 baseline and materials pass their gates |
| UGMathBench/HKU 500 candidate | A **separate** chat is revising it. The first 500 candidate failed key/solvability/difficulty review and is not ready for model collection | Do not use or edit that chat's working bank; it does not replace v3 without an explicit new paired design |
| Presentation/Feishu/GitHub | Framework exists; current result coverage and Feishu text need reconciliation | Update only from validated R tables and after source files are available; verify pushed state |

## T1 — Verify and package the frozen facts **[DONE; audit available]**

**Inputs:** `Initial_Response_Accuracy_Evaluation/processed/fact_frozen_2026-10-06/`, raw collection logs, `Night_Audit_2026-10-06/`, and original-gateway score summaries.

- [x] In R, verify 1,000 unique question × model cells, 500 questions per model, source-route counts, selected raw-response hashes and grade keys. Recomputed DeepSeek `423/44/33` among 500; MiniMax `354/78/38` among 470, with 29 technical gaps and one unscorable.
- [x] Rebuild a **canonical R-derived** cell/summary export from recorded initial answers, saved semantic decisions and 40 verified native recovery finals. All 1,000 rows × 11 columns match the frozen source; see `Night_Audit_2026-10-06/R/rebuild_fact_freeze.R` and its derived files. Keep the original 930-answer view, the 963-complete original-gateway recovery, and the 970-complete mixed-route view separately named. The Python-built freeze remains historical evidence.
- [x] Reconcile neutral self-check separately: among the original 112 initially wrong answers, 27 corrected, 79 still wrong, six abstained; one newly recovered DeepSeek wrong answer had a separate self-check and remained wrong. Do not call `27/112` a whole-sample self-check error rate.

**Acceptance:** R rerun reproduces all counts and hashes, identifies each missing/unknown task, records key-review limits, and changes no source record. **Stop:** no new fact model calls under the current freeze, even if a quota later renews.

## T2 — Obtain the matched GSM-Plus v3 math initials **[READY after preflight]**

**Inputs:** `Math_Crosscheck_500/question_review_v3/` and `collection_v3_minimax/`. The main follow-up design is in `Math_Crosscheck_500/EXPERIMENT_V2.md` and `COLLECTION_PLAN_V2.md`, but their v2 hashes are stale for the collected v3 bank; rebind and record the version change before collection.

- [ ] Check the v3 input/key/review hashes, the one corrected source key, 500 unique IDs, MiniMax's 500 raw finals and adjudicated 17/496 error count. Document the 18 source-restoration selection-constraint exceptions; do not pretend the bank still contains 150 missing-premise questions.
- [ ] Search existing logs for an **identical v3 DeepSeek** run. If absent, freeze 500 DeepSeek tasks with exactly the v3 question text as each fresh conversation's only user message, one reply per question, optional native search, and no key or desired answer in prompts. Run an offline R preflight and small technical pilot before full collection.
- [ ] Save append-only raw attempts and final outcomes. Continue native `pause_turn` only under a frozen same-turn policy; label unresolved/unknown outcomes. After collection, score complete answers in R with numeric equivalence and prompt-ambiguity review, then build the matched baseline index.

**Acceptance:** both models' usable initials join by the exact same v3 ID/text; coverage, exclusions, model/settings/tool provenance and R scores are reproducible. **Stop:** if provider or quota fails, retain partial coverage and continue T1/T4 offline preparation rather than manufacturing 500 pairs.

## T3 — Run self, natural cross, and wrong-peer branches **[BLOCKED on T2]**

- [ ] Freeze branch manifests from the **same MiniMax initial conversation**. `self`: neutral request to reconsider. `natural_cross`: paste DeepSeek's actual independent answer/explanation with a neutral request to check the original problem. Keep full donor text and abstention status. Never run one branch after another.
- [ ] For a predeclared subset of verified-correct MiniMax initials, build `synthetic_wrong_peer`: false target + plausible false explanation, each independently checked and marked as scripted. Freeze the selected subset/materials before seeing any branch result. Do not call this a natural DeepSeek error.
- [ ] Collect/score each eligible branch in R; record every baseline→final transition, especially wrong→correct, wrong→abstain, correct→wrong, and abstain→wrong. Review all induced-error cases against raw text. Report common-set self vs natural rates and controlled wrong-peer risk on their **own** denominators.

**Acceptance:** branch provenance and matching are auditable; common-set rates, conditional correction, wrong-target adoption and uncertainty reproduce from R. **Stop:** no follow-ups when donor initials or synthetic materials are missing/unverified.

## T4 — Test false ideas in the first human prompt **[DESIGN READY; collection not started]**

- [ ] Select and freeze questions with checked keys and an earlier correct model answer. State that this is a conditional selected sample. For each selected question × model, make two **fresh independent** prompts: neutral = original question verbatim; misconception = `I think the answer is {verified_false_answer} because {verified_false_reason}. {original_question} What do you think?` Do not mention search or JSON. Validate that the false answer is indeed wrong and that the original question is unchanged.
- [ ] Freeze selection, actual prompt text, ordering, model/settings/search availability, scoring rule, and stopping rule in an R-built manifest **before** collecting. Keep this independent from the existing post-answer challenge; its 78 pairs cannot be reused as first-prompt responses.
- [ ] Score both first answers in R; report all selected pairs, eligible/scorable pairs, neutral-correct→misconception-wrong cases, the paired error difference and abstentions. Keep scripted-user attribution explicit. If a route fails, preserve the partial fixed sample rather than selecting replacement questions after seeing outcomes.

**Acceptance:** frozen paired prompts, raw replies, R-ready grades and an appropriately limited conclusion. **Stop:** do not infer which element of the combined false-answer-plus-reason prompt caused the effect.

## T5 — Analyze and quality-check RQ1–RQ4 **[AFTER relevant data]**

- [ ] Generate separate R tables for experiment version, domain, model, condition, unique questions, completed task cells, valid paired units, C/I/A, technical gaps, and exclusion reasons. Compute rates on both common and clearly labelled available-case sets where justified.
- [ ] Use question/family-cluster uncertainty for paired rate differences, and show discordant transition counts. Keep historical primary results distinct from token-limit recovery or post-hoc sensitivity estimates. Do not infer internal model mechanisms from outputs alone.
- [ ] Audit each headline number and R-generated chart against row-level CSVs; inspect every correct→wrong example and a fixed sample of remaining scores. Track answer/explanation conflicts separately from final-answer errors.

**Acceptance:** every claim has a named CSV row set, R script, exact numerator/denominator and protocol version. Missing evidence becomes a limitation, not a positive claim.

## T6 — Presentation, external sync, and morning report **[AFTER validated tables]**

- [ ] Update the English report and R-based figures first, then PPT/PDF and the [Feishu presentation](https://vcng7a3g4ga3.feishu.cn/docx/SeW0dsKH0oCQOexFK1ecWWCnnSe?from=from_copylink). Correct the Feishu claims about model/repetition counts and align the title with *Can We Trust AI More After Cross-Checking?*. Replace placeholders only with completed data, not zeros or projected results.
- [ ] Visually check slides, chart type, citations, names **LINYUNIAN** and **PAN ZHENGYU**, and current Moodle deliverable requirements if accessible. Distinguish facts from math and historical from new runs; no unsupported universal or causal claim.
- [ ] Review Git status, test/rebuild touched artifacts, scan staged files for secrets, commit only this workstream's validated files and push. Verify remote commit and log it. Keep active-chat untracked work out of the commit unless that chat has finished and its outputs have been reviewed.
- [ ] Around 09:00 Asia/Shanghai, give the user a self-contained morning report: what is complete, RQ1–RQ4 evidence with denominators and limits, what remains blocked or uncollected, linked artifacts, and GitHub sync state. Pause this overnight automation after the report; do not keep notifying on unchanged status.

**Acceptance:** a reviewer can open the report, R data/figures, raw provenance and PPT and find the same claims. A candid partial handoff is preferable to a fabricated complete package.
