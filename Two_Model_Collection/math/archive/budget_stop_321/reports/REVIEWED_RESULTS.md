# Mathematics collection: partial, budget-stopped results

The mathematics agent executed the frozen two-model protocol and stopped when the remaining CNY 140 allocation could no longer cover the next CNY 10 request reservation. **This is not the completed 732-response experiment.** The misconception/source-attribution mechanism phase has not started, so this run cannot answer the new A1-versus-A0 or AI-versus-human source questions.

## Acquisition and integrity

| Item | Actual count |
|---|---:|
| CHAMP questions in the frozen natural core | 41 |
| Prespecified mechanism subset, 3 per mathematical family | 15 |
| Models × repetitions | 2 × 2 |
| Planned response tasks | 732 |
| HTTP attempts / terminal task records | 321 |
| Complete responses | 298 |
| Truncated/incomplete responses | 15 |
| Transport failures, with no retry | 8 |
| Dependency skips | 25 |
| Not collected | 386 |

The guard total is **CNY 130.37595**, including **CNY 80 reserved for eight transport failures**. This is conservative accounting, not a verified cash invoice. No unresolved request remained at stopping. All 321 recorded requests were reconstructed successfully from frozen prompts and the actual dependency records, including the recipient's original native tool history. Search was available without a forced call. No question was selected or retried because of the answer it produced.

## Why strict and semantic results differ

The frozen strict scorer accepts a JSON response or a JSON-only code fence. The collector concatenates the native tool response's text blocks, which can include narration before or between searches as well as the final JSON. Many complete records therefore contain substantial prose before their final JSON, especially DeepSeek initial answers. This is partly a mismatch between the tool-response representation and strict whole-text scoring, not a measure of mathematical failure or necessarily a final-output format violation. Strict scoring yields **122 correct, 6 wrong, and 193 unscorable**; the last number must not be presented as model errors or abstentions.

A separately labelled post-collection sensitivity uses the already frozen acquisition parser to recover a unique complete JSON object from surrounding prose. It restores 166 records without changing the answer fields. Codex then reviewed all 23 recovered wrong answers, the four remaining complete but unresolved cases, and a fixed sample of 40 strict-correct answers. Three unresolved definite symbolic/nonexistence conclusions were wrong, and one response explicitly corrected its earlier abstention and ended with a valid answer of 0. Thus the final semantic sensitivity contains **272 correct, 26 wrong, and 23 unavailable records** (15 incomplete plus 8 transport failures). No active abstention remains as the final adopted answer in these complete responses.

Frozen strict outputs, automatic JSON-recovery outputs and Codex semantic decisions are retained separately. Full reasoning in all 321 records was not independently verified. The review is AI-assisted, not an independent human assessment.

## Partial paired comparisons

Repetitions are first averaged within each model–question; questions are then averaged within model, followed by equal weighting of the two models. Comparisons include only their own valid matched units. They do not compare unrelated group denominators.

| Semantic sensitivity comparison | Error before | Error after | Difference | Interval | Matched units |
|---|---:|---:|---:|---|---:|
| Self-check → natural cross-model check | 2.27% | 0.00% | −2.27 percentage points | 97.5% question-cluster interval [−8.33, 0.00] pp | 37 across 27 questions |
| Initial answer → self-check | 13.54% | 8.37% | −5.17 percentage points | Exploratory 95% interval [−10.58, −0.83] pp | 84 across 38 questions |

The primary self-versus-cross comparison remains sparse, interval reaches zero, and collection is incomplete. **Do not claim established stable superiority from these partial results.** Its paired subset has no wrong cross-check final answers, but this does not mean all observed cross-check outputs were correct: there were two wrong cross-check outputs outside that subset because their matching self-check branches had not yet been collected. A zero-event bootstrap interval does not establish zero true risk.

## A real natural error-propagation example

For `CHAMP:P_Polynomial_11`, repetition 1:

- DeepSeek's independent initial answer was **20**, with the correct six-term residue cycle.
- MiniMax's independent answer was **24**, incorrectly calling that residue cycle a five-term cycle.
- After receiving MiniMax's actual answer, DeepSeek changed its final answer to **24** and repeated the false period-five argument.

The original question asks how many indices from 61 through 120 give a power-sum remainder of 4 modulo 5. The correct residue period is six; two hits per six indices give 20. This is an observed correct-to-wrong transition after real cross-model advice. Its paired self-check was not collected, so a case alone cannot quantify advice's causal effect beyond ordinary revision variability. Across available DeepSeek baseline-to-cross pairs, this was **1 wrong final among 35 originally correct opportunities**; the comparable MiniMax count was 0/26.

This case is from naturally generated A0 advice. It is **not** an A1 human-misconception or human-source-attribution result.

## Correct final answers can still have faulty reasoning

Of the 40 fixed strict-correct responses read by Codex, 8 contained clear reasoning errors, 1 a minor mathematical statement error and 3 a proof gap. Examples include a correct final Fibonacci count accompanied by incorrect base cases, a correct sequence value justified using the wrong period, and an integer-part answer accompanied by a contradictory statement about whether a sequence becomes large or small. These are a limited diagnostic sample, not a population estimate or evidence that one condition improves logical rigour.

There is also direct benchmark-contamination evidence: one MiniMax self-check explicitly says it found the CHAMP ground-truth answer before correcting its result. This is relevant to interpreting autonomous searching on a public benchmark. The present experiment evaluates the configured model-plus-search systems; it does not isolate internal reasoning from accessible answer copies.

## Reproduction and files

- `../R/analyse.R`: frozen strict analysis.
- `../R/audit.R`: request reconstruction and acquisition integrity.
- `../R/sensitivity.R`: unique-JSON recovery sensitivity.
- `../R/review_decisions.R`: 67 explicit Codex decisions and their mathematical reasons.
- `../R/final_analysis.R`: same paired estimator applied to the separate semantic labels.
- `semantic_sensitivity/`: final semantic tables and paired effects.
- `codex_semantic_decisions.csv`: review decisions; no original response was overwritten.

Completing the remaining fixed tasks would require an explicitly audited reallocation within the existing global cap or further user budget authorisation. This report does not authorise extra spending or change the sample.
