# Facts experiment: completed scheduled run and reviewed results

**The 1,600 scheduled tasks have reached a terminal state: 1,576 HTTP calls were recorded and 24 dependent tasks were skipped because their required inputs were unavailable or invalid. No scheduled tasks remain pending. This does not mean that 1,600 valid answers were obtained.**

The sample contains 100 factual questions, two models (MiniMax and DeepSeek), and two independent repetitions. A fixed 25-question subset additionally tests upstream misconceptions and AI-versus-human source attribution. The subset was selected before new responses were inspected. All collection and analysis use R.

## Collection and scoring

| Category | Count |
|---|---:|
| Complete model outputs (`ok`) | 1,562 |
| Incomplete outputs | 5 |
| Transport failures | 9 |
| Dependent tasks skipped | 24 |
| Remaining scheduled tasks | 0 |
| Strictly scored correct answers | 1,250 |
| Strictly scored wrong answers | 203 |
| Strictly scored explicit abstentions | 91 |
| Strictly unscorable recorded calls | 32 |

The 32 strictly unscorable records comprise 14 technical/incomplete records and 18 complete outputs with schema or date-precision problems. The overall total above spans unequal condition sizes and should **not** be pooled into one headline error rate.

The conservative cost ledger totals **CNY 316.37104**, including **CNY 90 reserved for nine transport failures whose actual charge is unknown**. It is not an invoice. The original domain budget was reached and collection paused; the user subsequently explicitly authorised completing all collection without the previous budget ceiling. The frozen budget amendments retain this history. No response was retried to obtain a particular answer.

## Primary result: natural cross-checking versus self-checking

Error means a wrong answer. Correct answers and explicit abstentions remain in the denominator; technical and formatting failures are separate. For each matched comparison, repetitions are averaged within each question/model, questions are then averaged, and the two models receive equal weight.

| Receiving model | Self-check error rate | Cross-model error rate | Valid paired responses | Questions |
|---|---:|---:|---:|---:|
| DeepSeek, receiving MiniMax advice | 1.53% | 1.53% | 194 | 98 |
| MiniMax, receiving DeepSeek advice | 44.33% | 6.70% | 180 | 97 |
| Equal-weight average of the two models | **22.93%** | **4.12%** | **374** | **98 unique** |

The paired difference is **−18.81 percentage points**, with a **97.5% question-cluster bootstrap interval of [−23.18, −14.54] percentage points**. The interval uses 5,000 resamples and accounts for the two task-domain primary comparisons.

This run provides evidence of lower error under this particular natural cross-checking setup. The improvement is concentrated in MiniMax receiving DeepSeek's suggestions. It does **not** show that both models benefited equally, that every model pair will improve, or that all AI answers can now be trusted. DeepSeek searched on every initial factual call; MiniMax did so on 63 of its 200 initial calls. Search availability was the same experimental policy, but providers' tools and their decisions to use them differed. This is a comparison of the tested model-plus-tool systems.

The separate initial-answer versus self-check comparison increased error by 3.57 percentage points (95% interval [1.55, 5.81]; 382 pairs). It therefore does not support treating “ask the same model again” as automatically beneficial.

## Misconception and source-attribution module

These comparisons use the preselected 25-question subset and are exploratory. A1 means that the donor received a fixed incorrect premise; it does not mean its resulting answer was necessarily wrong.

| Paired contrast | Error-rate difference | 95% interval, percentage points |
|---|---:|---:|
| Upstream misconception input minus neutral input | +3.00 pp | [−6.00, +11.00] |
| A1 material minus A0 material, AI attribution | +1.00 pp | [−2.00, +5.00] |
| A1 material minus A0 material, human attribution | −2.17 pp | [−5.43, 0.00] |
| Human minus AI attribution for A0 material | +1.00 pp | [0.00, +3.00] |
| Human minus AI attribution for A1 material | −2.08 pp | [−5.21, 0.00] |

These small, discrete exploratory estimates do not establish that human-labelled suggestions are generally more misleading than AI-labelled suggestions. Human attribution is a simulated prompt header, not data from real human participants.

The specific full propagation path requested by the user—**donor A0 correct, donor A1 wrong, receiver B0 correct, receiver final answer wrong**—was **not observed**. There were six eligible donor/receiver opportunities, all with DeepSeek as receiver; none ended wrong in either attribution branch. The same six opportunities appear under both headers and must not be counted as 12 independent opportunities. MiniMax had zero eligible full-path opportunities in the valid matched data. This small denominator does not establish immunity to misleading advice.

No initially correct receiver became wrong in the valid factual peer-review branches. Other risks remain: MiniMax changed from abstention to a wrong answer in 2/48 natural cross-check pairs and 1/17 A1-AI pairs. Counts and denominators are in `conditional_flip_risks.csv`.

## Independent checks and semantic sensitivity

The collection-integrity audit reconstructed **all 1,576 requests** and verified request hashes, independent initial sessions, matched question/model/repetition dependencies, real donor bodies, autonomous tool settings and preservation of provider-native history. It checked 1,076 review branches, including 682 peer branches; 721 review branches retained baseline search blocks.

Codex individually read **all 18 complete outputs that the strict scorer could not grade**. Seven contain genuinely conflicting dates or years, seven explicitly communicate uncertainty despite schema conflicts, three contain correct dates with field-name errors, and one gives the correct month/year while omitting the requested day. These decisions are recorded in `semantic_review_all_exceptions.csv` against the inherited reference keys. They are AI review, not independent human adjudication and not a fresh web verification of all references.

Frozen primary labels were preserved. The separate semantic sensitivity contains 1,253 correct, 210 wrong, 98 abstentions, and 15 unscorable records. Its natural paired comparison is **23.47% versus 4.34%**, a difference of **−19.13 pp**, 97.5% interval **[−23.21, −14.80]**, from 381 pairs across 98 questions. The conclusion for this comparison is not driven by the strict parser's exclusions.

This review does **not** claim that every well-formed answer or reasoning paragraph was independently checked for semantic correctness. The reference key is inherited from the retained question bank, not newly adjudicated against every primary source.

## Search-source exposure and sensitivity

The source screen found **108 benchmark-risk source entries across 56 HTTP tasks and 24 questions**, including visible SimpleQA and Hugging Face dataset results. Seeing these sources does not prove the model copied an answer, but their presence is a material limitation. Baseline search history and donor text can also propagate exposure to downstream branches.

As a conservative post-hoc sensitivity, all 24 flagged questions were excluded completely, across both models and every branch. On the remaining **74 questions and 281 strict valid pairs**, self-check error was **23.96%**, cross-check error **5.47%**, difference **−18.49 pp**, with 97.5% interval **[−23.45, −13.37]**. The semantic variant gives a difference of −18.58 pp [−23.65, −13.51] from 287 pairs.

This supports robustness to the **observed** source flags. It does not certify the remaining questions as contamination-free, and it does not make this a test of unaided internal factual knowledge.

## Technical recovery inventory

There are **nine transport-only recovery candidates** and **three skipped branches whose only blocker is a transport failure**. The three depend on `two:SV1228:minimax:1:neutral_initial`: MiniMax self-check, MiniMax A0-AI and DeepSeek A0-AI. The other 21 skips involve incomplete or schema-invalid inputs and are outside a transport-only appendix. All 1,576 HTTP attempts have terminal response records; there are no unresolved in-flight attempts.

The inventory is in `transport_recovery_candidates.csv`, `transport_only_dependency_candidates.csv`, `dependency_recovery_inventory.csv` and `technical_recovery_summary.json`. **No recovery calls were made by this report.** Any recovery must preserve the original records and be explicitly labelled as a separate appendix; it must not silently replace the original run.

## Reproduce

From the repository root, run the following R scripts in order:

```sh
Rscript Two_Model_Collection/facts/R/audit_collection.R
Rscript Two_Model_Collection/facts/R/analyse.R
Rscript Two_Model_Collection/facts/R/semantic_review.R
Rscript Two_Model_Collection/facts/R/audit_sources.R
Rscript Two_Model_Collection/facts/R/source_sensitivity.R
Rscript Two_Model_Collection/facts/R/recovery_inventory.R
```

These commands read existing records and generate reports; they make no provider calls.
