# DeepSeek independent initial answers for GSM-Plus mathematics v3

This is the missing second model's initial-answer collection for the **same 500 reviewed v3 questions** already answered by MiniMax-M3. It does not use the older v2 bank, CHAMP/MATH files, or the separate UGMathBench/HKU candidate. `R/prepare.R` freezes the task order, source/key/review hashes, model configuration and collector code in `protocol/run_manifest.json`. The task CSV contains question text and IDs, but no reference answer.

Each task is a fresh conversation with the English question verbatim as its only user message. The recorded provider configuration is `deepseek-v4-pro`, temperature 0.6, 2,048 output tokens, thinking disabled, with native web search available at the model's discretion. The prompt does not instruct the model to search. Two requests may run concurrently. The first 100 task IDs are a frozen checkpoint before the remaining 400.

Append-only attempt, raw HTTP response and completed ledgers are under `runs/`. A known 5xx can be retried once with the same payload; unknown delivery, 401, 402, 403 and 429 stop collection. Wrong or abstaining answers are never retried. A `pause_turn` or truncated response is saved as technically incomplete pending a **separately frozen same-turn continuation**, not graded as an answer or abstention. Usage and native search calls are recorded. `conservative_guard_cny` is a provisional usage guard, not an invoice.

From the repository root:

```sh
Rscript Math_Crosscheck_500/collection_v3_deepseek/R/prepare.R
Rscript Math_Crosscheck_500/collection_v3_deepseek/R/collect.R --preflight
Rscript Math_Crosscheck_500/collection_v3_deepseek/R/collect.R --pilot 2
Rscript Math_Crosscheck_500/collection_v3_deepseek/R/collect.R
```

The two-task pilot returned two complete HTTP 200 `end_turn` answers with the expected `deepseek-v4-pro` model identity. Full collection resumed from those same two tasks and ended with 500/500 complete answers, no unknown deliveries or empty outputs, and one native search call. The conservative usage guard reached ¥3.3991; the actual charge is unknown.

The R grading workflow is:

```sh
Rscript Math_Crosscheck_500/collection_v3_deepseek/R/export_scoring_queue.R
Rscript Math_Crosscheck_500/collection_v3_deepseek/R/adjudicate_initials.R
Rscript Math_Crosscheck_500/collection_v3_deepseek/R/build_matched_baseline.R
```

The first script is a **screen**, not a semantic grade: the last number in a response can be a trailing irrelevant detail. All 45 screen/key discordances were read against the full answer; a fixed random 60 of the 455 screen-positive replies were audited. The frozen-key grade is 496 correct, 2 incorrect and 2 prompt-ambiguous, hence 2/498 wrong among scoreable answers. One of those two errors (question 12) has a plausible alternate commission interpretation. It remains wrong under the pre-existing key, while an exclusion sensitivity is explicitly tabulated. These are Codex-assisted judgments, not independent human grades or proof that every explanation is sound. The matched table joins the 500 identical questions answered independently by MiniMax and DeepSeek; it **does not itself measure a cross-check effect**. See `derived/` for raw-aligned grades, audit sample, exception notes, hashes and matched counts.
