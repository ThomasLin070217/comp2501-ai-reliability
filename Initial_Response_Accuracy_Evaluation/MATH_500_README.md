# Math question set for the initial-answer test

This frozen set has **500 English questions**: 41 questions already used in the project's formal CHAMP math round and 459 distinct questions sampled from the 5,000-question Hendrycks MATH test split. Sampling was proportional across MATH subject and difficulty, with R seed `25011008`. The R builder excludes exact normalized matches to previously collected math questions and MATH questions containing `[asy]` diagram blocks.

## Files and use

- `math_model_inputs_500.csv`: one row per question, with `question_order`, `eval_id`, and the exact `input_text` to send as the user message. Give the model no answer key.
- `math_scoring_key_500.csv`: reference answer and source metadata; keep separate from model prompts.
- `math_selected_459_audit.csv`: full selected MATH records for source inspection.
- `math_question_quality_audit.csv` and `MATH_500_AUDIT.md`: R integrity audit and grading-risk flags.
- `R/build_math_question_set.R`: reproducibly builds the fixed set from the saved 5,000-row source snapshot.
- `R/audit_math_question_set.R`: verifies uniqueness, source text, and answer-key extraction without resampling.

From the repository root, run `Rscript Initial_Response_Accuracy_Evaluation/R/audit_math_question_set.R` to repeat the audit. No model has been called by the dataset-building or audit scripts.

## Evaluation boundary

For a new model answer, start a fresh conversation and pass only the question text. Record model/version, date, settings, raw answer, technical status, whether native search was available and used, and the final correctness judgment. Follow the frozen collection protocol for repeats and search availability; the 41 reused questions retain their original collection metadata. Analyze CHAMP and MATH rows separately before quoting a 500-question pooled rate. A two-repeat design yields up to 1,000 answers per model, but repeats are clustered within questions.

Grade equivalent mathematical expressions, fractions, ordered pairs, and textual answers by mathematical meaning rather than raw string equality. Report correct, incorrect, explicit abstention, technical failure, and unscorable counts separately. In the project's current metric definitions, error rate is `incorrect / (correct + incorrect + explicit abstention)` and non-correct rate is `(incorrect + explicit abstention) / (correct + incorrect + explicit abstention)`; technical failure and unscorable cases are excluded from these denominators.

The audit confirms consistency with the saved benchmark sources, not independent proof that every source solution is correct or that every question is equally difficult for today's models. These are benchmark questions, so possible prior training exposure also limits claims about out-of-distribution performance.

Source: Hendrycks et al., [Measuring Mathematical Problem Solving With the MATH Dataset](https://arxiv.org/abs/2103.03874); [original MATH repository](https://github.com/hendrycks/math); [dataset mirror used for the snapshot](https://huggingface.co/datasets/EleutherAI/hendrycks_math). The 41 CHAMP items come from the project's frozen prior protocol.

The upstream MATH repository's MIT notice is preserved in `MATH_SOURCE_LICENSE.txt` alongside the redistributed source snapshot and selected questions.
