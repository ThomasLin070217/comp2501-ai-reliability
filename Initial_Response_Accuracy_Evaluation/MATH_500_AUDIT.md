# 500-question math set: integrity audit

Audit run with `R/audit_math_question_set.R`. The question bank is already frozen; this script does not resample or edit it.

- Total: 500 unique questions; CHAMP: 41; Hendrycks MATH test: 459.
- All 459 new question texts and extracted final boxed answers match the saved 5,000-row source snapshot.
- All 41 reused CHAMP question texts and keys match their original protocol files.
- Missing questions/keys, duplicate IDs/text, and embedded image markup: 0 / 0 / 0.
- Possible wording references to an unseen diagram: 0; inspect flagged rows in the audit CSV.
- Plain numeric keys: 335; symbolic, fractional, tuple, expression, or text keys: 165.

The audit establishes file and source consistency, not independent mathematical proof of all 500 reference solutions. Do not grade symbolic/text answers by raw string equality. Preserve model output and adjudicate equivalent expressions or ambiguous answers separately. Keep `math_scoring_key_500.csv` hidden from tested models. The 41 reused CHAMP items and 459 newly sampled MATH items have different collection histories; analyze them by source as well as in the planned pooled set.
