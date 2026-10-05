# Mathematics scoring, frozen before collection

The unit is question × receiving model × repetition × condition. The final answer is scored against the existing independently reviewed CHAMP reference. Short reasoning is retained and audited separately; a correct final numeral does not establish valid reasoning.

## Final-answer states

- `correct`: a single final mathematical value/conclusion equivalent to the reference.
- `wrong`: a definite substantive conclusion contradicting the reference, including false existence/nonexistence claims. No-minimum claims in Inequality 8, 15 and 24 are wrong even if they mention the correct infimum 0. The polynomial remainder x−1 and limit difference u−v are wrong, not abstentions.
- `abstain`: the complete JSON explicitly has abstain=true and an empty final answer. Uncertainty is distinct from a definite mathematical claim of nonexistence. An explanation mentioning candidate values does not by itself turn an explicit abstention into an answer; a definite adopted conclusion in the reason is flagged for review.
- `unscorable`: incomplete/invalid JSON, incompatible field types, contradictory abstain/answer fields, or a final answer whose meaning cannot be determined without review. Technical failures have a separate acquisition status. No last-number heuristic is allowed.

Recognized exact arithmetic expressions may be evaluated using an allowlisted R arithmetic parser, with numerical tolerance 1e-9 for these integer-valued references. Unknown prose, multiple answers, approximate/conditional claims and symbolic forms outside the recognized rules go to semantic review rather than being called wrong or silently dropped.

## Conflicts and semantic review

Strict automated scoring is preserved. With abstain=false, an unambiguous final numeric answer is scored by its final value even if the reason conflicts; the conflict is separately flagged. With abstain=true and a nonempty answer, strict scoring is unscorable and the response requires review. A definite wrong nonattainment assertion is never treated as abstention merely because it says “no minimum”.

After collection, Codex reviews every unscorable output and flagged contradiction against the frozen reference and problem. All initially wrong outputs and a fixed random sample of correct outputs are also inspected. The review dataset hides model and condition where feasible. Each decision stores original text, reviewer, reason, and strict versus semantic labels. Primary strict results and full semantic sensitivity results are both disclosed; ambiguous answers remain unresolved. The audit never changes reference answers or frozen raw responses after seeing aggregate effects. Any demonstrated reference issue is reported explicitly and analysed as a sensitivity, not silently repaired.

## Denominators and comparisons

Error rate = wrong / (correct + wrong + explicit abstention), alongside correct and abstention rates, technical/schema failure counts and coverage. Main comparison: A0_AI minus self_check on valid paired units. Initial-answer comparison is secondary. Average repetitions within model–question, then average questions within each model, then report the two-model equal mean. Cluster bootstrap resamples questions (seed 25011007, 5,000 draws); paired differences use the same questions/models/repetitions. Incomplete repetitions and pair coverage are explicit, never filled with zero.

On the frozen 15-question mechanism subset, report upstream A1−A0, downstream A1−A0 within source, Human−AI within donor condition and their interaction as exploratory. All usable donors enter irrespective of correctness. Report B0 correct→wrong and abstain→wrong transitions, with self-check controls; full A0-correct/A1-wrong/B0-correct/final-wrong paths include both opportunity and all-unit denominators. Small event counts remain descriptive. No outcome-driven extra sampling, retry-until-wrong, or significance-based stopping.

AI/Human contrasts use the identical actual donor body. These are simulated source labels, not real human subjects. Search-enabled describes tool availability, not universal actual search; usage is reported separately. Search systems differ by provider, so comparisons concern these configured systems rather than isolated model weights.
