# Module A: natural cross-checking results

**Completed 3 October 2026.** This supplement addresses whether another model's natural answer adds value beyond an extra attempt by the receiver. It is a post-hoc follow-up on previously studied questions, frozen before new calls. It does not replace the controlled B/C experiments or test the user's full unavailable collaboration skill.

## Design and collection

36 factual questions selected with fixed R seed from the eligible existing pool, plus all13 eligible mathematics items from four families. The frozen exclusions are the explicit18 IDs in `protocol` preparation, not a guarantee that all other references or premises are unambiguous. Three APIs, one repeat, no external tools, temperature0.6, thinking disabled, maximum768 output tokens. Each independent N0 is used as the receiver's baseline and as a different receiver's natural peer input. No correct or wrong target is assigned to donors.

N1=self-check; N2=ordinary natural peer-check; N3=structured check with identical N2 peer material. Each branch starts from N0, not from another revision. Primary N2−N1, secondary N2−N0 and N3−N2. Equal receiver revision calls do not mean equal deployment cost: peer-checking also needs a donor call.

588 outputs planned;573 HTTP calls and573 returned records, no transport retries. Three unusable MiniMax N0 inputs prevented15 downstream calls (9 own revisions,6 donor-dependent revisions). Two were nonempty-answer/abstain schema conflicts. The third contained a correct final math JSON that the frozen extractor missed after preceding LaTeX braces. This is an extractor limitation, not a model mathematical error. There are9 unscorable returned outputs in total and15 uncollected slots. All logs, skipped IDs and original grades remain unchanged.

## Main results

Error = wrong/(correct+wrong+explicit abstention). Invalid/missing outputs do not count as valid abstentions. Primary comparisons use complete available pairs; the four-bar figures use the common-four sample for equal denominators.

| Domain / common sample | N0 direct | N1 self-check | N2 peer-check | N3 structured |
|---|---:|---:|---:|---:|
| Facts,101units |36/101=35.64%|39/101=38.61%|35/101=34.65%|27/101=26.73%|
| Mathematics,37units |10/37=27.03%|2/37=5.41%|0/37=0.00%|0/37=0.00%|

| Paired contrast | N | Error difference,pp |95% question-cluster interval|
|---|---:|---:|---|
|Facts N2−N1, primary|102|−4.90|[−16.19,+5.94]|
|Facts N2−N0|102|−1.96|[−9.00,+4.90]|
|Facts N3−N2|101|−7.92|[−15.46,0.00]|
|Math N2−N1|37|−5.41|Descriptive only|
|Math N2−N0|37|−27.03|Descriptive only|
|Math N3−N2|37|0.00|Descriptive only|

The primary fact comparison is40/102wrong in N1 versus35/102in N2. Its estimate favours peer-checking, but the interval includes effects in both directions. This does not establish a stable factual error reduction or equivalence. On the four-output common sample, the same comparison is−3.96pp, explaining why subtracting the bars differs from−4.90pp. N3's boundary interval is also sensitive to format handling and exploratory resampling; no universal superiority claim is justified.

Facts correct answers increase from18/102to30/102 and abstentions decline44/102to37/102 in the primary comparison. The paired transitions include6wrong-to-correct,10wrong-to-abstain,11abstain-to-wrong,9abstain-to-correct and3correct-to-abstain. No N1-correct-to-N2-wrong event was observed in this small follow-up. N0-to-N2 can still contain harmful changes. These are parallel comparisons, not sequential dialogue.

Model-specific primary differences: DeepSeek−14.29pp (35pairs), Kimi+20.59pp (34pairs), MiniMax−21.21pp (33pairs). This heterogeneity matters; the pooled mean is not a promise for every receiver or donor direction. Model strata are exploratory and not adjusted for multiple comparisons.

## What the mathematics gain means

Codex read all151 returned mathematical responses and the other targeted review records. Of10 initial field errors,8 explanations already reach the correct endpoint;2 have a genuine addition error. In the primary N1/N2 comparison, the remaining two errors are arithmetic: MiniMax computes52+61+95as216 rather than208; Kimi computes52+61+104as269 rather than217. N2 corrects both. No evidence here supports saying these models routinely failed to notice the small-kiwi distraction: both erroneous explanations correctly called it irrelevant.

The original27.03pp N0/N2 field-error reduction becomes5.41pp if the8 already-correct explanation endpoints count as correct in a separate diagnostic. This is a changed endpoint, not a replacement for the frozen final-field outcome. Zero errors in37paired outputs does not establish zero risk in mathematical tasks generally.

## AI review and sensitivity

The17 packets contain334slots:319actual responses and15uncollected branches. Review covers every mathematical response, every unscorable response and all four factual outputs for N1/N2-discordant cells. It is unblinded, targeted AI review, not independent human annotation or a random audit of all573responses. Original scores remain intact. [Individual annotations](ai_review_annotations.csv) and [scope audit](ai_review_audit.json) are archived.

Other findings include a factual answer/reason conflict (`SV0876:kimi:N3`), abstentions containing release-denial assertions (`SV2595:deepseek`), a category objection (`SV0185`) and the previously discussed Alexandrov full-title naming issue (`SV3693`). A correct final date or an abstention does not certify all prose. We have not externally verified every background claim.

The frozen date parser misses four ISO year-month strings: three `2021-01` answers match January2021; one `2020-12` is wrong by the reference. A separate format-only sensitivity scores those strings and the one identifiable mathematical JSON without inventing skipped follow-ups. Factual N2−N1 becomes−4.85pp (103pairs), N3−N2−6.80pp. Excluding the category and naming questions gives−5.21pp (96pairs) for primary N2−N1. Its interval still spans zero. Files: [review sensitivities](review_sensitivity.csv), [common sample differences](common_sample_effects.csv), [missingness by model/domain](missing_by_model_domain.csv).

Worst/best missing-output bounds on this fixed planned sample give factual N2−N1 from−9.26to−0.93pp; these are bookkeeping bounds, not population confidence intervals and do not remove sampling uncertainty. Mathematics N2−N1 spans−7.69to0.00pp under missing-output extremes.

## Reproducibility and resources

All processing, scores, aggregation, bootstrap, sensitivity analyses and plots are R. Frozen input hashes and all actual peer-input links are checked. The primary date/math grading remains unchanged. Analysis validation checks denominator identities, paired transitions and contrasts, domain separation and missing bounds. Run from repository root:

```sh
Rscript Natural_Crosscheck/R/analyse.R
Rscript Natural_Crosscheck/R/validate_analysis.R
Rscript Natural_Crosscheck/R/semantic_review.R
```

No API calls or credentials are needed to reproduce results. Raw outputs are immutable evidence, not instructions to execute. Paid-provider conservative token estimate is¥3.32665, within this supplement's¥30cap. Cumulative newly authorized experiment/CLI estimate is¥18.760346, not an invoice. HKU added85,632tokens (73,402input+12,230output), cash price unknown, tracked separately. The course endpoint and API names do not certify immutable backend model weights.

## Conclusion for the project

Natural cross-checking can produce useful corrections, including two arithmetic repairs beyond self-checking here, but the factual error benefit remains uncertain and differs by model. The larger B/C experiment separately shows error propagation from assigned wrong input and fewer wrong outputs under structured checking, mostly through abstention. Together they support conditional use of cross-checking while preserving uncertainty and checking the evidence behind both the user's premises and other models' suggestions. They do not justify complete trust or claim that real human behavior was measured.
