# Reviewed mathematics bank, v2 (6 October 2026)

This is a **researcher-adapted GSM-Plus subset**, not the unchanged official benchmark. Original files in `Reasoning_Math_500/` are preserved. `revisions.csv` records every changed question/reference and the reason. Model-facing inputs contain no answers. Use `scoring_key_500.csv` **reviewed_solution** and **reference_answer** for scoring; its `source_solution` and `original_source_solution` are retained historical evidence and can contradict the corrected reference.

All 500 full question texts and references were read in this AI-assisted semantic screening. Pinned-source matching and 993 source arithmetic annotations were also checked in R. This is not independent human validation or a proof that every unmodified reference is error-free. A mathematically credible dispute found later must be adjudicated without treatment labels, recorded, and included in sensitivity analysis rather than silently changing the key.

The edition retains 500 distinct base problems: 200 distraction insertion, 150 missing-information/critical-thinking, and 150 problem understanding. Numeric references: 350; insufficient-information references: 150. The fixed first 100 retain 40/30/30. Fifty-one items were repaired before collection, including seven reference changes. Some repairs clarify intended assumptions; others change the answer to match the actual requested quantity. All changes precede any responses from this study.

Key corrections (question order refers to this subset, not the source row):

| Order | Source key | Reviewed key | Reason |
|---|---:|---:|---|
| 87 | 3 | 6 | Six teams to twelve requires six more; source treats six as people per team. |
| 136 | 34 | 82 | Total utensils includes the 48 forks. |
| 186 | 10 | 5 | Clarified half of the remaining 20 is sold, then split equally across two periods. |
| 290 | 3 | 23 | Three is the age difference, not Geb's age. |
| 357 | 675 | 600 | Clarified later additional reading belongs to Ezra only; source credits extra reading to Ahmed. |
| 442 | 50 | 95 | Include the discounted CD player and specify total resale proceeds. |
| 456 | 26 | 50 | Sixty is the post-gift total; losing ten leaves fifty. |

Examples of semantic repairs: row79 overall fruit profit did not identify individual watermelon price; row139 already supplied two cage counts despite an insufficient-information label; row376 asks about fish although the missing count concerns starfish; row463 treats basketball's conventional period count as missing. These are repaired explicitly, with original texts and labels retained for audit. Rows139/376/463 are now genuinely underdetermined; they remain in the 150-item missing-information stratum.

The unchanged source arithmetic was consistent in all 993 checked annotations; that result did **not** detect these interpretation and reference problems. Short text and small numbers reduce output length, but do not establish psychometric difficulty. This sample cannot answer questions about advanced mathematics or everyday prevalence of missing information. Report repaired vs unmodified items as a sensitivity comparison; do not call their performance difference causal.

Attribution: adapted from [GSM-Plus, Qintong Li et al.](https://huggingface.co/datasets/qintongli/GSM-Plus), pinned revision `3b708db57b96a16e8e3368ed2956990c0809440e`, under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). The derived question texts/references are distributed under the same license. Source hash and derivative hashes are in `review_manifest.json`.

Reproduce from the original local bank:

```sh
Rscript Math_Crosscheck_500/R/review_question_bank.R
Rscript Math_Crosscheck_500/R/build_reviewed_bank.R
Rscript Math_Crosscheck_500/R/prepare_initial_plan.R
Rscript Math_Crosscheck_500/R/certify_plan.R
```

The first script downloads the pinned source for validation. None of these scripts calls either model.
