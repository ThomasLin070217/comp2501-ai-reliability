# COMP2501 AI Reliability — Public Data Release (8 October 2026)

This folder is the versioned, reusable public release for the project. It contains response-level data, item-level scoring references where redistribution is allowed, prompt materials for the controlled first-prompt experiment, R scripts, summary results, and the current presentation/report files.

## Research questions and headline results

1. **Can double-checking reduce AI error rates?** On 495 matched, scoreable GSM-Plus v3 questions, MiniMax wrong answers were 17/495 (3.43%) initially, 9/495 (1.82%) after self-check, and 4/495 (0.81%) after an actual independent DeepSeek cross-check. In the separate revised-math public-source subset, the paired initial/self-check comparison was 66/482 (13.69%) to 42/482 (8.71%); 32 wrong answers became correct and 8 correct answers became wrong. The full-bank headline is 66/488 to 42/488, but six local exam/workbook items are not redistributed here; use the 482-question public-only result when reproducing from released item-level data.
2. **Which checking method is most effective in practice?** On GSM-Plus v3, cross-check had 4/495 wrong versus self-check's 9/495. The paired difference is descriptive and does not establish a stable universal ranking. In a different revised-math analysis restricted to initially wrong questions, M2 self-check and an actual DeepSeek cross-check were compared on 63 matched cases: 32/63 versus 8/63 wrong. This is a selected-error subset, not a whole-bank error-rate comparison.
3. **Can an incorrect peer answer mislead an initially correct model during cross-checking?** In a separate, scripted 50-question GSM-Plus test, MiniMax ended with 0/50 wrong and did not adopt the planted false target. In the actual independent-donor branch, two matched questions had a correct MiniMax initial answer and an incorrect DeepSeek initial answer; the cross-check final was graded wrong in one case, but the wording is ambiguous, so this is not clean causal proof. Revised-math scripted AI-advice cohorts are reported separately: 0/69 and 1/69 wrong in two cohorts, with zero recorded false-target adoptions. These finite tests do not establish immunity; scripted advice is not a naturally generated donor answer.
4. **Can misleading user input cause an otherwise correct model to give a wrong answer?** Each of two models received independent neutral and false-premise first prompts for the same 50 GSM-Plus questions. DeepSeek changed from 0/50 wrong to 3/50; MiniMax changed from 1/50 to 5/50. The paired exact two-sided discordance tests are p=0.25 and p=0.125, respectively. The response-level `wrong_target_adopted` field records 1/50 and 3/50 false-target adoptions. In the separate revised-math post-answer user-challenge branch, 10/69 final answers were wrong and 10/69 adopted the false target; this is not the same as misleading input in the first prompt. These observed cases demonstrate possibility, but the small sample does not establish a stable population-average effect. The false user premise was scripted by researchers, not supplied by recruited participants.

See `results/key_results_reproduced.csv` and `results/revised_math_final_summary.json` for denominators, paired status counts, and source-specific caveats. Run `Rscript reproduce_results.R` from this folder to regenerate the key-result tables using base R only.

## Contents

- `data/all_experiment_responses_public.csv`: public-safe export of the 14,174-row project response inventory. For six local exam/workbook question IDs, question and response text is withheld while score/status and non-sensitive metadata are retained. No restricted local source text is included.
- `data/gsmplus_v3_response_level.csv`: response-level GSM-Plus v3 answers for initial, self-check, actual cross-check, scripted wrong-peer, and the paired first-prompt experiment.
- `data/gsmplus_v3_question_inputs_500.csv`, `data/gsmplus_v3_scoring_key_500.csv`: the GSM-Plus v3 question set and reference keys.
- `protocol/gsmplus_v3_first_prompt_tasks_200.csv`: frozen paired neutral/false-premise prompt tasks for the 50-question, two-model test.
- `data/revised_math_public_question_bank_494.csv` and `data/revised_math_public_responses.csv`: only the 494 source-bank items with redistributable source licenses (280 UGMathBench, 214 Hendrycks MATH). The six local HKU-exam/workbook items and their linked item-level responses are excluded.
- `data/fact_question_inputs_500.csv`, `data/fact_scoring_key_500.csv`, `data/fact_initial_1000_frozen_2026-10-06.csv`, `data/fact_initial_1000_reopened_2026-10-07.csv`: factual question inputs, scoring references, and separately versioned initial-answer snapshots. The frozen and reopened snapshots have different scoring/response states; do not merge them as duplicates.
- `source_data/simpleqa_verified_source.csv`: source facts dataset used for factual-question sampling.
- `results/`: reproduced public-subset tables and transparent full-bank aggregate summaries.
- `DATA_DICTIONARY.md`: field meanings, join keys, and denominator rules.
- `final_materials/`: current evidence report and presentation outputs (GSM-Plus results deck and revised-math deck).
- `FILE_MANIFEST.csv`: SHA-256 and byte size for release files.

## Versioned revised-math comparison views

The package preserves two valid M1-to-M2 comparisons rather than mixing them. The primary frozen-route comparison is 66/488 to 42/488 (32 corrections, 8 regressions); its public-source-only item-level view is 66/482 to 42/482. A later approved supplement recovered three additional paired cases through a mixed route, producing a separate 68/491 to 43/491 full-bank view (33 corrections, 8 regressions); its public-source-only view is 68/485 to 43/485. Use `revised_math_public_responses.csv` for the primary route and `revised_math_m1_m2_mixedroute_pairs_public.csv` for the later mixed-route sensitivity. `revised_math_historical_pre_supplement_summary_2026-10-07.json` is an earlier snapshot and is not the canonical summary. Do not substitute one denominator for the other or pool them.

## Data interpretation

A row is one model response or one registered response slot, depending on the study export. Read `condition`, `model`, `response_status`, and `grade` together. `correct`/`incorrect` are scoreable outcomes; abstentions, ambiguous prompts, unscorable answers, technical incompletes, and missing responses are kept distinct and must follow the denominator rule for that specific study. Do not silently convert them to wrong or correct. Use only matched, scoreable question sets for paired comparisons.

For revised math, `actual_peer_cross_check` is MiniMax's final response after receiving an actual independently collected DeepSeek answer. `independent_donor_initial` is DeepSeek's separate first answer. `scripted_ai_advice` and `scripted_ai_advice_extension` are researcher-written false peer suggestions. `scripted_user_challenge` is a researcher-written false human premise. Removed/replaced historical cases are labeled `historical_removed_*` and must not be mixed into the final cohort estimate.

The released item-level math bank contains 494 public-source questions. The 66/488 → 42/488 primary full-bank result includes six local exam/workbook questions whose text and response records are withheld here. Its public-only counterpart is 66/482 → 42/482. The later mixed-route sensitivity is 68/491 → 43/491 full-bank and 68/485 → 43/485 public-only. The current 69-pair M3/M4 cohort contains 0/69 wrong under scripted AI advice and 10/69 wrong under a scripted user challenge. The aggregate JSON preserves these results transparently; the R script recalculates from released public item-level data.

## Provenance and limitations

- The response text and grades are from the project collection and AI-assisted semantic scoring workflow. They are not independent human labels. The included `grade_basis`, source, condition, and response hash fields retain provenance where available.
- The project uses different question sources, samples, prompt conditions, and models. Do not pool them into a single overall accuracy rate.
- The answer key is provided for evaluation; keep it separate from model prompts when replicating.
- Model/service versions, routing, search availability, and collection dates vary across historical studies. Consult the project report and protocol rows before comparing conditions.
