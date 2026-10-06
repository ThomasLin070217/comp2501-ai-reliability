# Short reasoning-math questions for COMP2501

This is the **replacement candidate** for the earlier 500-question MATH/CHAMP set. It keeps 500 distinct questions but uses elementary arithmetic word problems from [GSM-Plus v1](https://huggingface.co/datasets/qintongli/GSM-Plus), a benchmark designed to test whether models understand changes to a simple problem. The [authors' paper and repository](https://github.com/qtli/GSM-Plus) describe its perturbations and report that v1 corrected some unrealistic or ambiguous v0 items. The original difficult MATH/CHAMP set remains archived unchanged.

| Category | Count | What the model must notice |
| --- | ---: | --- |
| Distraction insertion | 200 | Extra numbers or details do not belong in the calculation. |
| Critical thinking | 150 | A required condition is missing, so no unique numerical answer is possible. |
| Problem understanding | 150 | The question is rephrased; the model must still follow the intended quantities and relationships. |

Each item comes from a different original GSM8K problem. Selection used R seed `25011009`, a maximum question length of 300 characters, and a cap of 1,000 on numbers in the prompt and on numeric reference answers. These filters reduce long computations; they do not guarantee that every question is easy for a person or a model. The first 100 questions form a fixed 40/30/30 batch across the categories. All 500 may be used later under the same protocol without selecting questions based on model outcomes.

## Files

- `model_inputs_500.csv`: send `input_text` as the complete user message in a fresh conversation; do not append a hint or the category label.
- `first_batch_100.csv`: the first, balanced batch, with the same input columns.
- `scoring_key_500.csv`: source ID, category, reference answer, and source solution. Never send this file to a tested model.
- `selection_manifest.json`, `composition.csv`, `AUDIT.md`: reproducibility and quality checks.
- `R/build_reasoning_math_500.R`, `R/audit_reasoning_math_500.R`: all sampling and data processing in R. From the repository root, run the builder and then the audit. The builder downloads a pinned source revision if the local source snapshot is absent.

## Scoring

For numeric items, score the mathematical value, allowing equivalent formatting. For critical-thinking items, `None` in the source key means that the **question lacks necessary information**. A response that identifies the missing condition and says the requested number cannot be determined is **correct**. A generic “I don't know” without recognizing the missing condition is an **abstention**. A made-up numerical answer is **incorrect**. Keep technical failures and genuinely unscorable responses separate.

Report the three categories separately before any pooled error rate. A 500-question sample deliberately containing 150 impossible-to-determine questions is not a natural prevalence estimate for everyday math queries. It tests the model's response to these specified conditions. The 500 questions were checked against the pinned source data for exact question/answer/solution consistency and unique base problems. A manual logic review found five original "critical thinking" items whose source key said `None` even though the question determined a number; those five were excluded and replaced within the same category, with reasons and replacement IDs in the manifest. The remaining numeric items have **not** all been independently re-solved.

Rebuilding the questions does not itself run any model calls. The number of API calls in a full double-check experiment will still depend on the chosen branches and repeats; the fixed first 100 supports an earlier, smaller readout without changing the 500-question pool.

## Source and license

GSM-Plus v1: [dataset](https://huggingface.co/datasets/qintongli/GSM-Plus), [paper/repository](https://github.com/qtli/GSM-Plus). Its dataset card lists **CC BY-SA 4.0**; the redistributed selected-question CSVs and scoring key are shared under that same license with attribution to the GSM-Plus authors. [License text](https://creativecommons.org/licenses/by-sa/4.0/legalcode).
