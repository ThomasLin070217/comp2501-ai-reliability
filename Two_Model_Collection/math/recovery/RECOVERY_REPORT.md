# Mathematics: original run and technical recovery complete

All 732 frozen task positions now have a selected response. The original run remains immutable: 648 attempted records and 84 dependency skips. The separate appendix made 164 requests for 148 fixed targets (64 original technical failures and 84 dependency skips). All 148 targets ultimately returned status=ok; no technical or dependency gap remains. Five original status=ok responses still lack a complete final answer and remain unscorable, not abstentions or wrong answers.

## Results and scoring layers

| Dataset / scoring | Correct | Wrong | Unscorable | Dependency skips |
|---|---:|---:|---:|---:|
| Original strict JSON | 296 | 9 | 343 | 84 |
| Original unique JSON plus documented semantic review | 547 | 32 | 69 | 84 |
| Supplemented strict JSON | 368 | 16 | 348 | 0 |
| Supplemented automatic unique-JSON recovery | 673 | 44 | 15 | 0 |
| Supplemented unique JSON plus documented semantic review | 677 | 50 | 5 | 0 |

The frozen whole-text JSON scorer is preserved. Native search messages can contain several text blocks (search narration followed by final JSON); their concatenation is often invalid as a whole JSON document. The secondary parser recovers a unique unchanged JSON object. Explicit semantic decisions cover symbolic equivalents and definite wrong mathematical assertions such as “impossible”. These changes are post-collection sensitivity analysis, not a retrospective alteration of preregistered scoring. Format failures are not mathematical errors.

Error rate means wrong / (correct + wrong + active abstention); technical/schema missingness is excluded and reported. No selected mathematics final response is classified as an active abstention. Matched contrasts first average valid repetitions within question/model, then questions within model, then the two model means. They are not percentages over all 732 mixed-condition records.

## Supplemented paired results

| Contrast | First error rate | Second error rate | Difference, pp | Question-cluster interval, pp | Questions / pairs |
|---|---:|---:|---:|---|---:|
| natural_crosscheck | 10.37% | 5.49% | -4.88 | [-9.15, -1.22] | 41 / 164 |
| initial_vs_self | 13.41% | 10.37% | -3.05 | [-5.49, -0.61] | 41 / 164 |
| upstream_misconception | 6.67% | 1.67% | -5.00 | [-11.67, 1.67] | 15 / 60 |
| propagation_AI | 0.00% | 0.00% | +0.00 | [0.00, 0.00] | 15 / 58 |
| propagation_Human | 1.67% | 0.00% | -1.67 | [-5.00, 0.00] | 15 / 58 |
| attribution_A0 | 0.00% | 1.67% | +1.67 | [0.00, 5.00] | 15 / 59 |
| attribution_A1 | 0.00% | 0.00% | +0.00 | [0.00, 0.00] | 15 / 58 |

The natural self-check versus cross-check primary interval is 97.5%; other displayed exploratory intervals are 95%. Each uses 5,000 question-cluster bootstrap draws. The complete natural comparison has 41 questions × 2 models × 2 repetitions = 164 pairs. Source-attribution and propagation contrasts use the fixed 15-question mechanism subset and have five malformed-output gaps. Zero-event bootstrap intervals in small mechanism cells cannot establish zero risk.

On the supplemented natural comparison, the equal-model average falls from 10.37% to 5.49%, a 4.88-point decrease. This average conceals model heterogeneity: DeepSeek rises from 2.44% to 3.66%, while MiniMax falls from 18.29% to 7.32%. Thus the current mathematics sample supports an average reduction under this particular two-model setup, not a claim that every model benefits.

The original semantic result was 5.65% to 1.32% (−4.33 pp; 97.5% interval [−11.25, +1.85], 109 pairs). Supplementation restores harder missing tasks and changes coverage. Its clearer interval must be described alongside the original result, the technical retries, and the altered output-limit subset. Supplemented strict JSON alone gives −2.42 pp with a 97.5% interval [−5.71, 0.00] on only 82 pairs; its missingness is strongly affected by response formatting.

## Same output-limit sensitivity

A separate conservative check excludes all 11 questions for which any recovery request ever used 6144 tokens, including unused attempts and baseline/donor exposure. Thirty questions and 120 natural pairs remain. With the unchanged 1536-token limit, self-check gives 5.83% wrong versus 0.00% after natural cross-check (difference −5.83 pp; 97.5% question-cluster interval [−10.00, −1.67]). DeepSeek is 0% in both branches; MiniMax falls from 11.67% to 0%. This is a smaller post-collection subset and zero observed cross-check errors does not imply zero population risk. It remains separate from the 17-question source-risk exclusion.

The human-misconception mechanism is still weakly tested in mathematics: only one of the 60 misconception-conditioned upstream answers was wrong. The full propagation table contains only one eligible initially-correct receiving opportunity per source wrapper, and neither became wrong. This sparse exposure does not support a broad conclusion that human misconceptions are harmless, nor a demonstrated downstream harmful effect.

## Technical appendix and provenance

Original acquisition failures: 41 transport errors, 4 explicitly administrative interrupted_unknown outcomes, and 19 incomplete generations. All 19 original incomplete generations had actual stop_reason=max_tokens. Original failure counts by provider are DeepSeek: 4 transport + 8 max_tokens; MiniMax: 37 transport + 4 unknown + 11 max_tokens. The original log spans 08:31:46–12:28:08 UTC; failures span 08:32:05–12:25:57 UTC on 2026-10-05. Transport entries do not retain detailed curl diagnostics, so an underlying network/provider cause cannot be proven from those records.

The recovery plan allowed at most two technical attempts per target, a 600-second timeout, and no retries for wrong/abstaining/complete-but-malformed answers. Its 164 attempts contain 148 ok, 12 transport errors and 4 max_tokens incomplete outcomes; 16 targets needed a second attempt. Final selection is always the last allowed attempt, never the best or first correct answer.

Only actual max_tokens outcomes permit the fixed 6144-token limit. The selected appendix contains 21 responses with this limit and 127 at the original 1536 limit. This includes two targets that first truncated during recovery, in addition to the 19 original truncations. Their full requests, raw replies, costs and parent observation IDs are retained. This is a declared secondary parameter change and may influence outputs and downstream supplied reasoning.

The original guard estimate is ¥541.11150; recovery adds ¥144.79982; total mathematics guard estimate is ¥685.91132. These conservative ledger values include unresolved-request reservations and are not provider invoices. The user removed the budget ceiling before the remaining collection.

Acquisition audit passed: frozen original logs unchanged, no target beyond two attempts, all attempts accounted for, all payload hashes reconstructed, and 120 available AI/Human paired source bodies identical. The receiver retains its actual baseline transcript and native search history; only the source introduction differs between AI/Human branches.

## Semantic and source review

Codex read 115 distinct original observations, then 58 newly selected recovery observations: all 18 new complete wrong/unresolved candidates plus 40 correct outputs sampled using seed 25011005. The new correct sample contained three clear reasoning errors, one minor algebra typo, one proof gap and 35 with no clear error in the short reason. Correct final answers retain that label; reasoning quality is separate. This is not independent human review and does not claim all 732 explanations are proved valid.

A natural advice counterexample remains Polynomial_11, DeepSeek repetition 1: independent initial answer 20 and self-check answer 20 are correct; MiniMax suggests 24 using a wrong period-five claim; the DeepSeek AI-attributed cross-check then gives 24. This shows a real wrong-advice acceptance in the current workflow, but does not by itself prove the artificial human-misconception mechanism.

Native returned search URL/title records from every original and recovery attempt, including unused/failed attempts and inherited baseline search results, were screened for CHAMP/dataset identifiers. Entire questions were excluded when flagged; same-question donor exposure is therefore included. Seventeen questions were flagged, leaving 24 questions and 96 natural pairs. Their self-check error rate is 11.46% versus cross-check 6.25% (−5.21 pp; 97.5% interval [−10.42, −1.04]). This conservative screen is a risk indicator, not confirmed copying, and no flag does not guarantee absence of answer exposure.

## Reproducible outputs

- `derived/runs/completed.jsonl`: 732 unique selected observations, latest allowed attempt; original logs separate.
- `derived/provenance.csv`: selected source, recovery attempt, HTTP ID and request hash.
- `derived/reports/paired_effects.csv`: frozen strict scoring on the supplemented observations.
- `derived/reports/semantic_sensitivity/{paired_effects,paired_model_means,counts}.csv`: reviewed secondary results.
- `derived/reports/source_exclusion_sensitivity/paired_effects.csv`: whole-question source-risk sensitivity.
- `derived/reports/codex_semantic_decisions.csv`: 173 explicit review records.
- `reports/technical_recovery_inventory.csv`: all 148 target trajectories and selected token limits.
- `reports/remaining_unscorable.csv`: the five incomplete final-answer schema cases.
- `reports/acquisition_audit.json`: reproducible recovery integrity checks.

Original reports stay in `../reports/`; the old 321-record budget-stopped snapshot is historical under `../archive/budget_stop_321/`.
