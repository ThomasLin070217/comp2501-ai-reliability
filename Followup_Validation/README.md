# Follow-up validation: larger natural checking and no-extra-abstention verification

User authorization, verbatim: “1 2 补测试，3 不要加强补测试 4 没问题。”

Interpretation: strengthen evidence for natural cross-checking and mathematical reasoning; test verification without adding an abstention reminder; keep wrong/(correct+wrong+explicit abstention) as the primary error metric. Correctness and abstention remain separate secondary outcomes. This is a follow-up designed after reviewing earlier results, with the new sample, prompts and analysis fixed before its own calls. Earlier frozen results are preserved.

## Fixed sample and comparisons

- **100 facts**, the complete eligible old 120-question pool after 18 prior exclusions and the two new premise/naming concerns. These are previously studied questions, not an independent held-out population. Expand from 36 questions and one repeat to 100 questions and two fresh repeats per model. Do not pool old responses into the primary estimate.
- **41 new-to-project CHAMP questions**, covering combinatorics, inequalities, number theory, polynomials and sequences. The initial seeded sample had nine integer-answer text problems per category. Before any model call, two incorrect source answer keys and two zero-side degeneracy ambiguities were excluded without replacement. The public benchmark may occur in model training data; “new” means new to this project.
- Three receiving APIs, two independent repeats; donor direction reverses across repeats, so each receiver uses both other models. Temperature 0.6 and thinking-disabled requests remain fixed. Facts allow 768 output tokens, the harder mathematics allows 1,536. No tools or external retrieval are supplied to experimental models.
- N0: independent answer. N1: self-check. N2: another model's independent answer plus ordinary recheck. N3: same natural peer material plus verification, **without an additional abstention reminder**. The common system still allows abstention; no arm forces guessing.
- On a fixed-seed subset of **36 factual questions**, W0/W1/W2 reuse the same fresh N0 and the same previously frozen wrong answer/explanation: ordinary recheck / verification with no added abstention reminder / original verification including the reminder. The factual W1 prompt differs from W2 only by removing that sentence. W1-W0 evaluates the remaining verification package; W2-W1 isolates the incremental reminder within that package. There is no abstention-only arm, so a full factorial interaction is not estimated.
- All revisions are parallel alternatives, not serial dialogue. Planned: **846 units, 4,032 outputs**. No same-model independent-donor arm or third arbitrator is added in this follow-up.

## Preregistered-for-this-run processing and inference

All acquisition, cleaning, grading, arithmetic, sampling, statistics and plots use R. A private launcher supplies environment credentials; it performs no study data processing and is not published.

Primary contrasts: N2-N1 separately for facts and mathematics. Report paired error difference, correct-answer difference and abstention difference with 5,000 question-cluster percentile bootstrap draws (seed 25011006), keeping every model and repeat for a question together. Also display 97.5% marginal intervals for the two domain-primary error contrasts as a Bonferroni coverage convention; all other intervals are pointwise exploratory 95% intervals. No guarantee of significance and no sample extension or early success stopping based on observed outcomes.

Secondary: N2-N0, N3-N2, W1-W0, W2-W1 and W2-W0; receiving-model and donor strata descriptive. Because some CHAMP items share a mathematical structure (e.g. Fibonacci recurrences), report a conservative mathematical topic-cluster sensitivity and note that only five topics make that interval unstable. Question-level intervals describe the selected problem collection, not all possible mathematical families.

Every comparison uses its own complete pair. Missing or invalid outputs are excluded from that pair, not recoded as abstention. Report missing counts, common-sample diagnostics and worst/best bounds on the fixed planned units. Primary graphics use the same paired denominator as their displayed difference. No merging factual and mathematical error rates.

The new parser accepts one valid answer object after prose/LaTeX, accepts equivalent ISO year-month notation, and rejects conflicting JSON objects and nonempty-answer/abstain conflicts. Numeric mathematical answers use exact numeric comparison with tolerance 1e-8, permitting a decimal, fraction, boxed number or correctly grouped thousands separators. Non-numeric answers are unscorable rather than automatically wrong. Keep all raw outputs and a review queue; any semantic or formatting revision is a separately labeled sensitivity, not silent main-score alteration.

Mathematics requests put the concise solution before the final answer. This changes the response format relative to the old supplement, so old/new differences cannot be attributed solely to question difficulty. Independently assess the displayed reasoning of N1/N2 mathematical outputs as a **secondary AI review**, masked to provider and condition, using the question and vetted reference. Labels: valid, incomplete, incorrect, uncertain; correctness of the final field alone does not earn a valid-reasoning label. Preserve reviewer outputs, and inspect flagged or uncertain judgments before using examples. AI review is not a formal proof checker or independent human annotation.

## Resources and stopping

Remaining previously authorized total budget is not expanded. Prior new-work conservative estimate is CNY18.7603. Experimental paid calls have a combined CNY70 cap (35 per paid provider); optional masked AI reasoning review has CNY8 reserved. Maximum combined estimate is CNY96.7603, below the original CNY100 authorization. HKU's cash price remains unknown; its tokens and a separate CNY35 token-envelope guard are tracked, not counted as a verified cash charge. These are conservative estimates, not provider invoices.

Four concurrent requests per provider. Each transport/network or 502/503/504 failure may have one exact retry, at most 12 retries per provider and 1,360 total attempts per provider. Stop on 401/403/429, budget reservation failure or four-hour collection deadline. Do not retry substantive wrong answers or format failures to improve outcomes. All three baseline phases finish before any natural-peer branches start.

## Sources and reference review

[CHAMP paper, ACL Findings 2024](https://aclanthology.org/2024.findings-acl.785/) and [official repository](https://github.com/YilunZhou/champ-dataset), pinned commit `bfb6651efb3d91c266413db44e41d9a83ab789e5`. Dataset hash, sampled IDs and preflight exclusions are in `sources/CHAMP_manifest.json`; the MIT license is retained. We import problem statements, reference answers and solutions, not prior model conversations or error annotations. The paper records difficulty and reasoning defects for its tested historical models; it does not establish current model error rates.

The CHAMP reference solutions contain some algebraic typographical mistakes even when the final answer is correct. The original solutions remain archived; explicit vetted notes used in AI reasoning review are separate. Facts retain their original source-review records and known limitations.

## Run

Prepare and check before freezing: `Rscript Followup_Validation/R/prepare.R`, then `Rscript Followup_Validation/R/test.R`.

Live collection: `Rscript Followup_Validation/R/collect.R baseline PROVIDER`, then after all baseline receipts `Rscript Followup_Validation/R/collect.R branches PROVIDER`. Credentials must be present in the provider-specific environment variables. Analysis is offline and must not load credentials.
