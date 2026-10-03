# Audit of the mathematical reasoning reviewer

Kimi supplied labels for 432 complete mathematical N1/N2 responses. Codex read all 28 flagged outputs and 24 fixed-seed reviewer-valid controls (52 distinct outputs). This audit was unmasked, targeted and conducted after outcomes. It does not establish error-free labels for the remaining 380 outputs. Explicitly withdrawn exploratory errors do not invalidate the final solution; an unwithdrawn false subsidiary mathematical claim does, under the stated reviewer rule.

Codex disagrees with 8 labels: 5 among the 28 flags and 3 among the 24 valid controls. The original Kimi annotations and raw responses are retained; separate Codex evidence is in `codex_reasoning_annotations.csv`.

Examples: the reviewer miscalculates a correct sum-of-squares identity; it treats a valid nonminimal period 12 as wrong; it misses an incorrect common-denominator numerator and an unjustified exclusion of a Diophantine candidate. Five R checks corroborate identities, a recurrence period, eigenvalues and a degree-one counterexample. These checks are not a formal proof of all mathematical annotations.

## Matched, exploratory comparison



|version             |label      | pairs| questions|  N1|  N2| difference_pp|     ci_low|    ci_high|
|:-------------------|:----------|-----:|---------:|---:|---:|-------------:|----------:|----------:|
|original_kimi       |incorrect  |   206|        39|  16|   7|    -4.3689320| -8.4210526| -0.9478673|
|original_kimi       |incomplete |   206|        39|   9|   9|     0.0000000| -2.3696682|  2.3923445|
|original_kimi       |valid      |   206|        39| 181| 190|     4.3689320|  0.4975124|  8.5427136|
|original_kimi       |uncertain  |   206|        39|   0|   0|     0.0000000|  0.0000000|  0.0000000|
|partial_codex_audit |incorrect  |   206|        39|  13|   8|    -2.4271845| -5.7594140|  0.4717540|
|partial_codex_audit |incomplete |   206|        39|  11|  10|    -0.4854369| -2.5641026|  1.5463918|
|partial_codex_audit |valid      |   206|        39| 182| 188|     2.9126214| -0.4651163|  6.5734253|
|partial_codex_audit |uncertain  |   206|        39|   0|   0|     0.0000000|  0.0000000|  0.0000000|

Only pairs with both complete reviewed responses enter this table; field-unscorable but complete mathematical text may enter. Therefore its denominator differs from final-answer analysis. Raw condition totals (N1=224, N2=208) must not be compared as if they were matched. Question-cluster bootstrap uses 5,000 draws, seed 25011010; intervals are exploratory and ignore annotation uncertainty.

The partial-audit sensitivity changes only the 52 inspected labels, preserving the remaining original labels. Finding false negatives among the controls means these revised counts cannot be presented as verified population reasoning-error rates. Keep the primary final-answer endpoint separate, and use individually checked repair/failure examples as illustrative evidence.

This review supports the existence of genuine mathematical mistakes and of both successful corrections and peer-induced failures. It does not justify an unqualified claim that cross-model checking improves logical rigor across all problems.
