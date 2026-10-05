# Independent cross-review of the original mathematics results

Reviewer: facts collection agent (Codex). Scope: read-only review of the original mathematics run, not the technical recovery appendix. No model calls, label edits or changes to mathematics files were made.

## Result

No evident adjudication error was found in the **10 individually read responses** listed below. The Polynomial 11 example is a genuine correct-to-incorrect change: DeepSeek initially answered **20**, retained **20** under self-check, but answered **24** after receiving the independent MiniMax answer **24** and its incorrect period-five argument. The original HTTP request confirms that exact donor content was supplied. This is not an extraction artifact.

The complete machine-readable tables were checked structurally: all 115 explicit semantic decisions agree with the final labels in the 648-response table. All 442 comparison rows across seven contrasts reference matching response labels. Independent recomputation of every paired point estimate, averaging repeats within question/model, then questions within model, then the two models equally, agrees with the reported values to less than 1e-12. Bootstrap intervals were read but not independently regenerated in this cross-review.

The original natural comparison has 109 valid pairs across 38 questions: self-check **5.6452%**, cross-check **1.3158%**, difference **−4.3294 percentage points**. Its reported 97.5% interval [−11.2497, +1.8503] pp includes zero. This original-run estimate must remain separate from the supplemented recovery estimate.

## Polynomial 11: reconstructing the actual failure

Question: if x₁ and x₂ are the roots of x²−6x+1, how many integer n from 61 through 120 give a remainder of 4 when x₁ⁿ+x₂ⁿ is divided by 5?

Set Sₙ=x₁ⁿ+x₂ⁿ. Vieta's formulas imply S₀=2, S₁=6 and Sₙ=6Sₙ₋₁−Sₙ₋₂. Modulo five the successive residues are **2,1,4,3,4,1,2,1**. The consecutive state (2,1) repeats after six steps, establishing the cycle. The residue four occurs for n≡2 or 4 modulo six. The 60 requested indices contain 10 complete cycles and therefore **20** matching indices.

Independent R enumeration produced:

```r
s <- numeric(121)
s[1:2] <- c(2, 1) # positions 1 and 2 represent n=0 and n=1
for (n in 2:120) s[n+1] <- (s[n] - s[n-1]) %% 5
stopifnot(sum(s[62:121] == 4) == 20)
(61:120)[s[62:121] == 4]
# 62 64 68 70 74 76 80 82 86 88 92 94 98 100 104 106 110 112 116 118
```

The received MiniMax reasoning correctly listed the six-term repeating sequence but asserted a period of five and counted 24. DeepSeek's cross-check repeated this contradiction: it computed S₆≡2 and S₇≡1, then asserted S₆≡S₁≡1 and S₇≡S₂≡4. Thus its final numerical answer and its final period argument are both incorrect.

The baseline and self-check answers each derive the correct period and total. The self-check and cross-check are parallel continuations of the same initial response; self-check was not run first and then fed into the cross-check. This case is in the natural experiment, with `mechanism_selected=FALSE`. It must **not** be presented as a tested human-misconception → wrong donor → wrong receiver chain. The observed record establishes a correct receiver accepting an erroneous peer suggestion on this trial; it does not identify the model's internal causal mechanism or establish a population-level failure frequency by itself.

A join of all original neutral and A0_AI outcomes identified exactly **one** initial-correct → cross-incorrect record, this case. That descriptive transition is different from the main self-check versus cross-check paired estimand.

## Individually inspected responses

Every abbreviated ID below has prefix `two_math:CHAMP:`. All 10 full response texts were read, including text outside the JSON objects.

| ID suffix | Final-answer adjudication | Independent review of reasoning / representation |
|---|---|---|
| P_Polynomial_11:deepseek:r1:neutral_initial | Correct: 20 | Correct recurrence, cycle six and count. |
| P_Polynomial_11:deepseek:r1:self_check | Correct: 20 | Correct independent recount, retained initial answer. |
| P_Polynomial_11:minimax:r1:neutral_initial | Incorrect: 24 | Claims cycle five despite listing cycle six. Actual donor for the next row. |
| P_Polynomial_11:deepseek:r1:A0_AI | Incorrect: 24 | Adopts the same false period and contradicts its own computed residues. |
| P_Combinatorics_5:minimax:r2:neutral_initial | Correct: 144 | Reasoning error remains separately recorded: initial counts should be 2 and 3, not 1 and 2. Correct final answer does not validate its derivation. |
| P_Combinatorics_5:minimax:r2:misconception_initial | Incorrect: 143 | Earlier prose correctly obtains 144, but the final adopted JSON subtracts the empty subset, which the problem includes. The earlier correct sentence does not make the final answer correct. |
| P_Inequality_8:minimax:r2:neutral_initial | Incorrect: claims unbounded below | Its supposed negative witness equals 3, not −1. The true minimum is 0. This is a definite mathematical claim, not uncertainty or abstention. |
| P_Polynomial_17:minimax:r1:self_check | Correct final assertion: 0 | Contains an earlier abstaining JSON then an explicitly adopted final JSON with a valid continuity proof. Strict/unique-object parsing properly remains unscorable; final-assertion sensitivity can label the final conclusion correct. Text explicitly reports finding CHAMP ground truth: preserve source-risk flag. |
| P_Number-Theory_24:minimax:r2:neutral_initial | Incorrect: 544 | Exact R computation gives (2^32+1) %% 641 = 0. The response's division arithmetic and asserted verification are false. |
| P_Polynomial_40:deepseek:r1:self_check | Correct: −3 | Completing the square gives a nonnegative sum minus three, with equality at a=b=1. |

For the subset question, independent exhaustive enumeration of all 1,024 subsets gives 144. For Inequality 8, write S=Σxᵢ and P=∏xᵢ. Convexity gives Σxᵢⁿ⁺¹≥Sⁿ⁺¹/nⁿ and AM–GM gives PS≤Sⁿ⁺¹/nⁿ. Therefore the expression is nonnegative, with zero attained when all variables are equal and positive. These checks substantiate the adjudications without trusting the model explanations.

## Final correctness and reasoning quality are separated

The 115 explicit decisions contain **10 correct final answers with `reason_quality=error`**, two correct with `minor_error`, three correct with `proof_gap`, and one correct with `unsupported_context_claim`. These remain final-answer correct; their reasoning annotations are not silently added to the numerical error-rate endpoint. The Combinatorics 5 example above independently confirms that this separation is meaningful.

Conversely, the “no minimum / unbounded below” answer in Inequality 8 is mathematically false and is correctly counted as an error. Calling a problem impossible is not equivalent to saying the model cannot determine its answer. Missing, unfinished or malformed outputs are also not automatically treated as deliberate abstentions.

The semantic table totals 547 correct, 32 incorrect and 69 unscorable. This cross-review verifies table consistency and a deliberately targeted set of 10 responses; it does not certify all 547 correct explanations or provide independent human verification.

## Reference-text caveat

The preserved `original_reference_solution` contains transcription/algebra slips: Polynomial 11 writes `u^s_(n-1)` where multiplication is intended; Polynomial 17 omits `−x` in one sign alternative; Polynomial 40 has an incorrect intermediate linear-term sign. The separate `reviewed_argument` already corrects these issues and supports the correct reference answers. No adjudication change is needed. Presentations should use the verified argument rather than reproducing the flawed original working. Original source text should remain unchanged for provenance.

## Files inspected

- `Two_Model_Collection/math/reports/semantic_final_responses.csv`
- `Two_Model_Collection/math/reports/codex_semantic_decisions.csv`
- `Two_Model_Collection/math/reports/semantic_sensitivity/paired_records.csv`
- `Two_Model_Collection/math/reports/semantic_sensitivity/paired_effects.csv`
- `Two_Model_Collection/math/reports/semantic_sensitivity/paired_model_means.csv`
- `Two_Model_Collection/math/reports/REVIEWED_RESULTS.md`
- `Two_Model_Collection/math/protocol/SCORING.md`
- `Two_Model_Collection/math/protocol/questions.json`
- `Two_Model_Collection/math/protocol/researcher_reference.json`
- `Two_Model_Collection/math/runs/completed.jsonl` and `http_responses.jsonl` for the Polynomial 11 lineage and actual supplied messages.

This report creates no new labels and changes no original or recovery record.
