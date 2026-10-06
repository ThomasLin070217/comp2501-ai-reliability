# Easier reasoning-math set: audit

- Source: GSM-Plus v1 test, revision `3b708db57b96a16e8e3368ed2956990c0809440e`; source SHA-256 `885c279bfa9cde767ea23f79fd462d566fa0dbf6af9f2dcf30c75aa94f3d4041`.
- 500 unique question texts and 500 distinct base problems; every selected question, answer, and solution matches the downloaded source row.
- 200 irrelevant-information questions, 150 missing-information questions, and 150 rephrased word problems.
- The first 100 are a fixed balanced batch: 40 / 30 / 30 in the same category order.
- Every question is at most 300 characters; every number in the question is at most 1,000; 350 reference answers are numeric and 150 are `None` because a required condition is missing.
- No exact normalized overlap with the earlier 41 formal CHAMP questions.
- Five mislabeled source questions were excluded after manual logic review; their IDs, reasons, and replacements are recorded in the selection manifest.

This is an integrity and source-consistency audit, not independent mathematical verification of all 500 benchmark answers. Score a missing-information item as *correct* only when the response explains that the requested number cannot be determined from the given facts; a generic 'I don't know' is an abstention. Numeric items require semantic equivalence, not raw string equality. Keep both outcomes distinct in analysis.
