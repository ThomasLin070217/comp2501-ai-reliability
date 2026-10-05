# Facts technical recovery appendix

**Technical recovery is complete.** The original run is immutable. This appendix adds 30 HTTP attempts and selects 29 complete responses: 14 replace technical gaps in a separate derived view, and 15 fill previously skipped dependent tasks. Nine original dependency skips remain because their upstream outputs violate the frozen schema; those outputs were not retried or rewritten.

## What was recovered

- Nine transport failures were replayed with the exact original request payload.
- Five original `incomplete` records were also replayed with their exact original payload. Their original stop reason was **`tool_use`, not `max_tokens`**: three exhausted the native search tool's allowed uses and two emitted an undeclared `json` tool call. No undeclared tool was executed.
- The model-facing payload, tools, temperature and **768-token limit remained unchanged for every direct recovery**. Only the network timeout increased to 600 seconds.
- Each target allowed at most two recovery attempts, and only technical failure justified a second attempt. One target required a second attempt. The first normal `end_turn` was accepted even if the answer was wrong, an abstention or malformed.
- All 14 direct targets eventually returned `end_turn`. Fifteen dependent branches then became available and used their actual recovered baseline/donor outputs, with native history preserved.

The added conservative cost is **CNY 7.49703**. Original plus recovery guard is **CNY 323.86807**, including the original CNY 90 uncertainty reserve for transport failures. These figures are estimates, not invoices; the old reserves were not silently released. The user had removed the previous budget ceiling before this recovery.

## Original and derived data stay separate

| Measure | Original run | Recovery-completed secondary view |
|---|---:|---:|
| Recorded target responses | 1,576 | 1,591 |
| Normal `end_turn` responses | 1,562 | 1,591 |
| Technical/incomplete selected responses | 14 | 0 |
| Dependency skips | 24 | 9 |
| Strictly correct | 1,250 | 1,271 |
| Strictly wrong | 203 | 208 |
| Strict explicit abstentions | 91 | 93 |
| Strictly unscorable | 32 | 19 |

The derived view selects recovered records by technical completion, never by correctness. It does not overwrite, regrade or delete the original dataset. A successful HTTP/model completion is not necessarily a scorable or correct answer.

## Natural cross-checking result

The error indicator remains wrong / (correct + wrong + explicit abstention). Valid repeats are averaged within question/model, then questions are averaged, then models receive equal weight. All intervals below use 5,000 question-cluster resamples and 97.5% confidence.

| Analysis | Self-check error | Cross-check error | Difference | Interval | Paired units |
|---|---:|---:|---:|---|---:|
| Original frozen primary analysis | 22.93% | 4.12% | −18.81 pp | [−23.18, −14.54] | 374 across 98 questions |
| Recovery-completed, strict secondary analysis | 22.97% | 4.79% | −18.18 pp | [−22.25, −14.00] | 385 across 100 questions |
| Recovery-completed, semantic sensitivity | 23.25% | 5.00% | −18.25 pp | [−22.00, −14.25] | 394 across 100 questions |

In the strict derived comparison, DeepSeek's error rate is 2.00% in both conditions (197 pairs, 100 questions). MiniMax changes from 43.94% to 7.58% (188 pairs, 99 questions). The benefit remains concentrated in MiniMax receiving DeepSeek advice; this does not establish equal benefits for every receiving model or every model pair.

The exploratory misconception/source findings remain limited. The upstream misconception effect is +3.00 pp with a 95% interval of [−6.00, +12.00]. The user's full propagation chain still has six eligible opportunities and zero final wrong answers under either source header. The same opportunities appear under both headers; they are not 12 independent cases. A low event count does not prove resistance to all misleading advice.

## Review and source-risk sensitivity

All **30 new HTTP requests** were audited against their frozen replay payloads or reconstructed dependency messages. Original frozen hashes remained unchanged, retry limits were respected, and actual receiver search history and donor text were preserved. The audit is in `integrity.json`.

Codex read **all 29 selected recovery outputs**, including their brief explanations. Only one new strict-format exception appeared: `SV4261`, MiniMax self-check repeat 2, explicitly says it cannot verify the year but places that statement in the nonempty answer field while setting `abstain=true`. It is unscorable in the strict endpoint and an abstention only in the labelled semantic sensitivity. The derived exception table contains the original 18 cases plus this new case, for 19 reviewed exceptions. Semantic totals are 1,274 correct, 215 wrong, 101 abstentions and one remaining precision-insufficient answer.

The recovered Notepad++ item (`SV0097`) illustrates a factual reasoning error: some outputs equate a build/file modification date with the release date. A fresh check of the [project's own GitHub changelog](https://github.com/notepad-plus-plus/notepad-plus-plus/wiki/Changes-v7#788) supports **28 June 2020**, the inherited reference. No reference or frozen label was changed. Direct download/news-page fetches returned 403 and are not claimed as inspected. This targeted check does not imply all 100 references were freshly web-verified.

The combined original/recovery source screen finds 109 benchmark-risk source entries across 57 task IDs and **25 questions**. It conservatively includes search results from all original and recovery attempts. Excluding all 25 flagged questions from every model and branch leaves 75 questions and 289 strict valid pairs: self-check 24.31%, cross-check 6.40%, difference **−17.91 pp [−22.67, −13.00]**. The semantic version gives −17.67 pp [−22.33, −13.00] over 296 pairs. These are post-hoc exposure sensitivities, not certification that remaining questions are free of benchmark contamination.

## Remaining gaps

Nine branches remain blocked by three original MiniMax initial answers: `SV1228` repeat 2, `SV1857` repeat 2 and `SV2035` repeat 1. Each violates the exact donor/baseline schema through contradictory abstention fields or a string in place of a boolean. Retrying these would select on output format after a normal completed answer, outside the technical-only recovery rule. Their original outputs and all dependent IDs are preserved in `runs/blocked.jsonl`.

No outstanding transport or unfinished-tool response remains in the selected derived view. The nine dependency gaps and 19 strict-format/precision exceptions are still disclosed; “recovery complete” does not mean every target became valid data.

## Machine-readable outputs

- `derived/runs/completed.jsonl`: recovery-completed response view, 1,591 records.
- `derived/runs/skipped.jsonl`: nine remaining skipped branches.
- `derived/provenance.json`: explicit overlay-selection policy.
- `derived/reports/paired_effects.csv`, `paired_model_means.csv`, `counts.csv`: strict results.
- `derived/reports/semantic_sensitivity_records.csv`, `semantic_sensitivity_effects.csv`, `semantic_sensitivity_model_means.csv`: semantic sensitivity.
- `derived/reports/semantic_review_all_exceptions.csv`: all 19 complete-output exceptions.
- `derived/reports/source_exclusion_sensitivity.csv`: conservative benchmark-risk exclusion results.
- `reports/original_vs_recovery_effects.csv`: explicitly labelled original and recovered contrasts.
- `reports/reviewed_recovery_outputs.csv`: per-output review notes for all 29 selected recovery outputs.

All processing and statistics are implemented in R. Primary results remain at `Two_Model_Collection/facts/reports/`; this appendix is a separate secondary analysis.
