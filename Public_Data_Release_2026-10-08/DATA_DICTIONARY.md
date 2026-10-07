# Data dictionary

All CSVs are UTF-8 with a header row. Empty cells are missing/unknown, not zero. Preserve condition and source labels when filtering.

## Main response tables

### `data/gsmplus_v3_response_level.csv`

One row per GSM-Plus v3 model/condition response. `question_id` is the paired key; `condition` distinguishes `initial_answer`, `self_check`, `cross_check`, `scripted_wrong_ai_peer`, `first_prompt_neutral`, and `first_prompt_human_misconception`. `model` is the receiver/donor model; `grade` is the semantic outcome; `response_status` describes collection status. `wrong_target` and `wrong_target_adopted` are induction fields, not general correctness labels. `prompt_text` is the exact first-prompt task text where available. `reference_answer` is the scoring reference and must not be treated as model input. `response_text` preserves the collected answer.

### `data/revised_math_public_responses.csv`

One row per released public-source math response or historical replaced response. Join by `question_id`; use `condition`, `response_status`, and `grade` together. `collection_origin` separates original, replacement, and extension cohorts. `response_sha256` is the source response-text digest when available. The `historical_removed_*` rows are retained for audit and excluded from active cohort estimates.

### `data/all_experiment_responses_public.csv`

A public-safe, append-only inventory export with the project schema. `observation_id` uniquely identifies a row. Study labels (`experiment`, `experiment_phase`, `condition`, `provider`, `other_model`, `repeat_id`) separate protocols. Outcome and extraction fields include `response_status`, grade variants, `is_wrong`, `is_abstain`, `final_answer`, `response_conclusion`, `answer_value`, and `response_text`. Search metadata includes `native_search_available` and `native_search_calls`. For six local exam/workbook question IDs, all question/answer/prompt/response/source-file text is withheld; grades and non-sensitive study metadata are retained.

## Question and scoring tables

- Fact and GSM-Plus `*_question_inputs_*.csv` files contain the model-facing question text with stable IDs. Their `*_scoring_key_*.csv` files are separate and must never be sent to the model.
- `data/revised_math_public_question_bank_494.csv` contains one row per redistributable revised-math item. `source_group` and `source_id` identify the benchmark item; `source_license` carries its upstream license. `input_text` and `reference_answer` are the released question and scoring reference. `source_difficulty` is the upstream label, not a calibrated prediction of performance in this experiment.
- `data/revised_math_m1_m2_mixedroute_pairs_public.csv` is the later 485-question public-source paired sensitivity view. `initial_grade` and `m2_grade` are the compared labels; `wrong_to_correct` and `correct_to_wrong` are transition flags. It is separate from the primary-route `revised_math_public_responses.csv` result.
- Fact snapshots `fact_initial_1000_frozen_...` and `fact_initial_1000_reopened_...` are different versions. `chosen_source`, `chosen_grade`, and `chosen_answer_text` identify the selected response/grade for that snapshot; the reopened file also retains frozen/reopened provenance columns.

## Outcome and denominator rules

For the key comparisons, only matched questions with a scoreable `correct` or `incorrect` grade enter the stated denominator. Missing, ambiguous, unscorable, and technical-incomplete entries remain visible and are excluded; never code them as zero or wrong by default. Explicit abstention is preserved as its own grade/status and the analysis rule must be checked for each study before calculating a rate. `results/key_results_reproduced.csv` includes the stated numerator, denominator, rate, measure, and caveat for each headline comparison.
