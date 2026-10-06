# Speaker notes: four research questions

Slides 1–20: 18 minutes. Slides 21–24: backup. The allocation is a suggestion; it does not assert individual research contributions.

## 1. Does Double-Checking Make AI More Reliable?

25 seconds. Introduce both authors. We investigate the four questions in the supplied Feishu outline. Reliability here means fewer wrong final answers, with abstention separately identified.
Sources:
https://vcng7a3g4ga3.feishu.cn/docx/SeW0dsKH0oCQOexFK1ecWWCnnSe

## 2. Background and motivation

55 seconds. Tell the classroom story in the first person. The professor wording is a recollection, not an independently verified verbatim quotation. Move from a personal reason for trusting AI to a testable research question.
Sources:
https://vcng7a3g4ga3.feishu.cn/docx/SeW0dsKH0oCQOexFK1ecWWCnnSe
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/CHAT_CONTEXT.md#u31

## 3. Research questions

45 seconds. Use the four questions exactly as in the Feishu document. RQ1 asks about a net reduction; RQ2 compares methods; RQ3 conditions on a correct receiver and wrong peer; RQ4 tests misleading user input to the same model.
Sources:
https://vcng7a3g4ga3.feishu.cn/docx/SeW0dsKH0oCQOexFK1ecWWCnnSe

## 4. Why this is important

40 seconds. Present the practical motivation rather than a claim that ordinary users have already been studied. Our experiments simulate questions, checking and misleading feedback; they do not measure actual human decision outcomes.
Sources:
https://vcng7a3g4ga3.feishu.cn/docx/SeW0dsKH0oCQOexFK1ecWWCnnSe

## 5. Data and completed collection

55 seconds. 2332 was the planned number, not the achieved scorable total. The final overlay contains 2323 task records; nine fact branches stayed blocked and six records are semantically unscorable. The 156 follow-ups form 78 pairs from 39 selected previously-correct questions. Earlier three-model data are supporting evidence and are not pooled with the new study. Repeated answers are not independent questions.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Two_Model_Collection/reports/RESULTS_SUMMARY.md
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Human_Challenge_Followup/RESULTS.md

## 6. Method: independent answers, parallel checks

65 seconds. Each model first answers independently. Self-check and cross-check are alternative continuations from that same initial response, so the self-check is not sent into the cross-check. Include actual peer answer, abstention and rationale. No third judge and no iterative debate. Search histories are retained. Both models have thinking disabled in the configured collection.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Two_Model_Collection/protocol/models.json
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/docs/two-model-prompt-example.md

## 7. Measurement and exclusions

50 seconds. Exclusions use status, format and documented source-quality criteria, not an outcome threshold. Semantic recovery is an explicitly secondary overlay. Show abstention separately; lower error is not necessarily higher correct-answer accuracy. Main model comparisons use matched eligible pairs and question-cluster uncertainty intervals.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/All_Experiment_Data/QUESTION_SELECTION.md
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Two_Model_Collection/reports/RESULTS_SUMMARY.md

## 8. RQ1: can checking reduce errors?

65 seconds. Descriptive, post-hoc completed-data comparison. Facts 20.75% to 5.00% over 393 matched cells; mathematics 13.41% to 5.49% over 164. Repetitions within question and models are equally weighted. The eligible sets differ from the self-versus-cross contrast on the next slide; do not subtract rates across those sets. No confidence interval is inferred from the displayed point estimates. Maths includes recovery with higher output limits. Earlier studies did not confirm a stable benefit.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/All_Experiment_Data/question_comparison_pairs.csv
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Two_Model_Collection/reports/RESULTS_SUMMARY.md

## 9. RQ2: self-check or cross-check?

65 seconds. Facts have 394 matched cells across 100 questions; mathematics has 164 across 41. Both charts use the same 0–50% scale. Repeats are averaged within each question and model, then the models receive equal weight. The mathematics result is supplementary: 21 selected recovery responses had a higher output allowance. The original-run interval included zero. Advice adds model calls and time; we did not compare methods by cost per successful correction.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Two_Model_Collection/reports/recovery_semantic_primary_comparison.csv

## 10. RQ2: gains differ by receiving model

50 seconds. Most improvement comes from MiniMax receiving DeepSeek advice. DeepSeek factual error remains 2%, while its mathematical error changes from 2.44% to 3.66%. These are descriptive results for particular questions and configured search tools, not a model leaderboard or evidence about training architecture. Different model names do not guarantee independent errors.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Two_Model_Collection/reports/recovery_semantic_by_model.csv

## 11. RQ2: verification and abstention

75 seconds. These are two separate matched 210-cell contrasts in an earlier three-model study without search tools. Verification changes 108 wrong answers to 106: −0.95 points, with a 95% interval spanning zero. The added abstention reminder changes 106 wrong answers to 83: −10.95 points. However, correct answers fall from 48 to 38 and abstentions rise from 56 to 89. Basic permission to abstain is present in all conditions. We cannot causally rank this earlier setup against the current two-model study.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/effects.csv

## 12. RQ3: can a wrong peer introduce an error?

50 seconds. Condition on a correct receiver initial answer and an actually wrong peer initial answer. There are 76 factual opportunities with no wrong cross-check finals and 18 mathematical opportunities with one. The 94 opportunities include model repetitions; they are not 94 independent questions or a universal probability. The one wrong mathematical final is the verified Polynomial 11 case. Scripted wrong-advice experiments are separate supporting evidence.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/All_Experiment_Data/QUESTION_SELECTION.md

## 13. RQ3 case: correct 20 becomes wrong 24

70 seconds. Let S_n be the sum of the nth powers of the roots. The recurrence is S_0=2, S_1=6 and S_n=6S_(n−1)−S_(n−2). Modulo five the residues repeat as 2,1,4,3,4,1, with period six. Two residues equal four per cycle, and the 60 indices contain ten cycles, so the answer is 20. MiniMax incorrectly claims period five and gives 24. DeepSeek receives that actual donor answer and follows the wrong period. Self-check and cross-check are parallel alternatives, not consecutive revisions. This demonstrates a failure, not an internal psychological mechanism.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Two_Model_Collection/facts/recovery/reports/CROSS_REVIEW_MATH.md

## 14. RQ4: two timings of misleading user input

45 seconds. The primary RQ4 comparison uses the same model in separate fresh sessions: a neutral question versus a question containing a scripted false human premise. A correct neutral response and wrong false-premise response are parallel outcomes, not a literal change of mind in one conversation. The second experiment tests a later timing, with two alternative follow-ups to a previously verified correct answer. Neither design requires the error to propagate into another model. AI-versus-human source labels and A-to-B propagation are exploratory extensions.
Sources:
https://vcng7a3g4ga3.feishu.cn/docx/SeW0dsKH0oCQOexFK1ecWWCnnSe
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/All_Experiment_Data/QUESTION_SELECTION.md

## 15. RQ4: a false premise in the first prompt

65 seconds. There are 159 scorable fresh-session pairs, of which 125 have a correct neutral response. Among these 125, the false-premise arm has 117 correct answers, seven wrong answers and one abstention. Facts contribute 69 eligible pairs: 62 correct, six wrong and one abstention. Mathematics contributes 56: 55 correct and one wrong. All seven wrong outcomes are from MiniMax. Report this conditional denominator, and do not call the parallel sessions seven literal conversational reversals or infer that false premises always increase the overall error rate.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/All_Experiment_Data/question_comparison_pairs.csv

## 16. RQ4: false challenge after a correct answer

60 seconds. All 78 initial answers were verified correct before the new follow-ups. Neutral rechecking produces one wrong answer; the false user challenge produces four, each matching the supplied false alternative. All four are MiniMax responses. Three parallel neutral branches remain correct, while one abstains. A different neutral branch is wrong while its challenged counterpart is correct. The paired difference is +3.85 points, with a 95% interval spanning zero. This establishes an observed failure mode, but not stable average harm. The scripted challenge bundles disagreement, a false answer and a false explanation. Note the 0–10% axis.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Human_Challenge_Followup/RESULTS.md

## 17. RQ4 case: reasoning says 240, answer says 216

65 seconds. For exactly two boys, choose two of four boys, one of six girls, then assign three distinct toys: choose(4,2) × choose(6,1) × 3! = 216. For three boys, choose(4,3) × 3! = 24. The total is 240. The scripted user argues that 240 double-counts cases and proposes 216. MiniMax’s challenged explanation calculates 240 and calls it correct, but its final answer field gives 216. The neutral branch gives 240. This is a wrong final answer and an answer–reason conflict; one illustrative case is not a separate prevalence estimate.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Human_Challenge_Followup/reports/manual_case_review.csv

## 18. Discussion and limitations

65 seconds. Keep the earlier null result alongside the newer two-model reduction. Twenty-one selected mathematical recovery responses used a higher output allowance, and the original-run interval included zero. Search can expose public benchmark keys; source exclusions do not prove the absence of contamination. A lower wrong-output rate can reflect more abstention rather than more correct answers. We did not certify every explanation. Human-style prompts are scripted and human decision outcomes were not measured.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/docs/experiment-conclusions-2026-10-05.md
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Two_Model_Collection/reports/RESULTS_SUMMARY.md

## 19. Answers to the four research questions

45 seconds. Answer all four questions without claiming universal benefit or stable average harm. RQ1 describes the latest selected setup and retains contrary earlier evidence. RQ2 is model-dependent and involves abstention trade-offs. RQ3 has one verified natural failure with a correct receiver and wrong donor. RQ4 has seven wrong false-premise outcomes among neutral-correct fresh-session pairs and four wrong continuous-challenge finals. These timings and denominators must not be combined into one rate.
Sources:
https://vcng7a3g4ga3.feishu.cn/docx/SeW0dsKH0oCQOexFK1ecWWCnnSe
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/All_Experiment_Data/QUESTION_SELECTION.md

## 20. Practical implications and Q&A

25 seconds. These are proposed practices, not results from a randomized human intervention. For important claims, use reliable sources or verify computations. We did not test a dedicated retrieval-versus-calculator comparison. Retain both authors without inventing contributions. Disclose Codex assistance. R processing, question selection, prompt records and response lineage are available in the public repository. Invite questions; the following four slides are backup.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability

## 21. Backup: earlier three-model validation

0 seconds. This earlier tool-free expanded validation uses DeepSeek, Kimi and MiniMax. Both reported domain intervals touch or cross zero. The studies differ in models, tools, prompts, coverage and collection date, so they are not a causal control for the new two-model study. Retain these results to avoid selectively reporting only favorable comparisons.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/effects.csv

## 22. Backup: recovery and source-risk checks

0 seconds. The original semantic mathematics result has 109 pairs across 38 questions: −4.33 points, with a 97.5% interval of [−11.25,+1.85]. Excluding all 11 higher-limit-exposed questions leaves 30 questions: −5.83 points, interval [−10.00,−1.67]. Separately excluding 17 visibly source-risk questions leaves 24: −5.21 points, interval [−10.42,−1.04]. These are separate post-hoc sensitivities, not a combined exclusion or retroactive primary results.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Two_Model_Collection/reports/RESULTS_SUMMARY.md

## 23. Backup: actual checking prompts

0 seconds. These prompt templates preserve the receiver’s initial answer and the original question. The peer placeholder is replaced with the other model’s real answer, abstention state and reasoning from that round. The shared JSON schema is omitted on the slide for readability, but remains in the recorded requests. Neither prompt forces search; the native API search tools are available at the model’s discretion.
Sources:
https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/docs/two-model-prompt-example.md

## 24. Backup: related work and public benchmarks

0 seconds. Our verification prompt is simpler than full Chain-of-Verification. Public benchmark scores provide background, not a prediction of our cross-checking error rates. Artificial Analysis, read on 6 October 2026, reports a reasoning-mode Intelligence Index of 29 for MiniMax-M3 and 36 for DeepSeek-V4-Pro-0813 Max. The index is not an accuracy percentage. Our collection disables thinking; no complete directly comparable non-thinking pair was found. Public dataset use does not imply independence from training data or search leakage.
Sources:
https://openreview.net/forum?id=IkmD3fKBPQ
https://aclanthology.org/2024.findings-acl.212/
https://aclanthology.org/2024.findings-acl.785/
https://huggingface.co/datasets/google/simpleqa-verified
https://artificialanalysis.ai/models/comparisons/minimax-m3-vs-deepseek-v4-pro
