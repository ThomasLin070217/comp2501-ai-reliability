# Speaker notes: integrated final evidence

LINYUNIAN and PAN ZHENGYU. Slides 1-18: 18 minutes total, followed by 2 minutes for questions. Slides 19-20 are backup. Suggested split: LINYUNIAN 1-8 (8:45), PAN ZHENGYU 9-18 (9:15). This is a suggested presentation allocation, not a statement of individual research contributions.

## Slide 1: Can We Trust AI More After Cross-Checking?

30 seconds. Introduce the project and both authors. Trust is the motivation; the measured endpoint is wrong final answers. The latest results integrate the expanded follow-up and retain the earlier controlled-advice evidence separately.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/CHAT_CONTEXT.md#u37

## Slide 2: The classroom question

60 seconds. Tell this as LINYUNIAN’s classroom recollection, not a verbatim professor quotation. I raised my hand because I use different agents to cross-check. Our question tests whether that workflow justifies extra confidence.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/CHAT_CONTEXT.md#u31

## Slide 3: Research questions and evidence

60 seconds. Keep two questions separate: the net value of natural cross-checking, and susceptibility when advice is deliberately wrong. A wrong-advice experiment alone cannot show that normal cross-checking has a net benefit. The new reminder ablation helps explain an earlier reduction in error.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/report.md

## Slide 4: Different models, independent initial answers

90 seconds. The three APIs answer independently. In each repeat every receiver gets one of the other models; the second repeat reverses direction. N1 and N2 are separate branches from the same N0. N2 does not receive N1. We test one receiver revision, not a third judge, debate, browsing or calculators. Peer generation adds cost. No same-model independent-donor arm was included.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/protocol/prompts.json

## Slide 5: Data and collection

60 seconds. Facts are 100 previously studied date questions. CHAMP contributes 41 new-to-project numeric questions in five topics, after four pre-call exclusions. Three models answer twice. Repeated replies are dependent. The controlled study is separate and is not pooled. The latest raw totals are 3932 attempts, 3893 complete outputs and 3829 scorable answers, from 4032 planned slots.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/summary.json

## Slide 6: What counts as an error

60 seconds. Abstention stays in the error-rate denominator and is not wrong. It also is not a correct answer. Invalid format, missing calls and truncation are separate. A correct final answer may still contain false reasoning. Main statistics resample whole questions 5000 times; two primary domain contrasts use 97.5% marginal intervals. The plotted denominator always matches its reported difference.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/README.md

## Slide 7: Facts: no clear improvement over self-checking

75 seconds. Facts: self-check 254/578 wrong, cross-check 258/578. Difference +0.69 percentage points, 97.5% interval -4.98 to +6.17. We cannot establish stable benefit or equivalence. The earlier -4.90-point estimate was much smaller and uncertain; it is historical rather than the latest finding.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/effects.csv

## Slide 8: Mathematics: fewer errors, limited certainty

90 seconds. Mathematics: self-check 8/199 wrong, cross-check 4/199. Difference -2.01 points, 97.5% interval -5.21 to zero. Note the 0-10% axis. Only 199 of 246 planned pairs and 39/41 questions survive. Two difficult questions have no complete pair. Versus direct answer, the exploratory result is 11/202 to 4/202, -3.47 points with a negative 95% interval. Do not replace the primary comparison with this more favourable one.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/effects.csv

## Slide 9: Factual effects differ by receiver

60 seconds. The factual averages hide opposite receiving-model directions. DeepSeek 32.31% to 42.05%, Kimi 25.38% to 31.98%, MiniMax 75.81% to 60.75%. Paired sample sizes are 195,197,186. This is a descriptive sample-specific comparison, not a model leaderboard or evidence about training architecture.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/effects.csv

## Slide 10: Wrong advice increases factual error

75 seconds. This is the earlier controlled study, 719 complete units per condition. Neutral error46.04%, wrong answer64.81%, wrong answer with reason52.43%. The differences are +18.78 and +6.40 points with positive exploratory95% intervals. These all-unit comparisons are post hoc. The original hypothesis that adding an explanation raises harmful flips was not supported:5/154 versus3/154. AI advice simulates suggested judgments, but no human-label experiment was performed.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Peer_Misleading_Study/reports/interaction_posthoc/effects.csv

## Slide 11: Verification without the extra reminder

60 seconds. New ablation on identical wrong advice: ordinary108/210 wrong versus verification106/210, or51.43% and50.48%. Difference-0.95 points with95% interval-6.76 to+5.19. All conditions retain the basic permission to abstain. Removing the extra reminder does not force guessing. There is no reminder-only arm.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/effects.csv

## Slide 12: The reminder lowers error and increases abstention

75 seconds. Add back the extra abstention sentence:106/210 wrong becomes83/210,50.48% to39.52%. Difference-10.95 points,95% interval-17.93 to-4.26. Correct48 becomes38; abstain56 becomes89. This is useful caution, potentially, but not improved fact finding. Do not claim that we measured human thinking benefits. The original correct-advice control also lost useful corrections76/322 to45/322.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/effects.csv

## Slide 13: Wrong peer advice can overturn a correct answer

75 seconds. The number made of1980 twos has remainder0 on division by1982. Kimi self-check gives0. MiniMax independently gives220 after a false CRT step; Kimi cross-check then accepts220. R digitwise remainder independently confirms0. A separate polynomial case changes-120 to120 with correct peer reasoning, so both repair and failure are real. These are selected illustrative cases, not prevalence estimates.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/case_mathematics_correct_to_wrong_1.md

## Slide 14: What limits the conclusion

60 seconds. Missing hard questions and selected public tasks limit generalisation. Reasoning labels also fail: Kimi reviewed432 outputs; Codex checked28 flags and24 seeded-valid controls, finding8 disagreements. The partial-audit206-pair contrast is13 versus8 incorrect reasons,95% interval crosseszero. The remaining380 labels are not independently checked. No stable rigor claim or universally best method follows.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/review/codex_review_notes.md

## Slide 15: What the experiments establish

45 seconds. Answer the motivating question carefully. Natural cross-model checking has no established stable advantage over self-checking here. Assigned wrong advice can mislead. Lower wrong-output rates can reflect more withholding instead of more knowledge. Cross-checking gives evidence to examine, not100%certainty.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/report.md

## Slide 16: A proposed workflow for users

45 seconds. This is a proposed practical workflow, not a tested intervention: keep initial answers independent, mark user assumptions, compare evidence, retain uncertainty, then use reliable sources or executable checks for important claims. Retrieval, calculators, third judges and human outcomes were not tested.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/docs/accuracy-methods.md

## Slide 17: Related work and data

30 seconds. The relevant original papers motivate self-correction, verification and task selection. Our verification prompt is simpler than full Chain-of-Verification. Public benchmark inclusion does not imply model training independence. Full links and dataset commits are in the report and notes.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/references/README.md
https://openreview.net/forum?id=IkmD3fKBPQ
https://aclanthology.org/2024.findings-acl.212/
https://aclanthology.org/2024.findings-acl.785/
https://huggingface.co/datasets/google/simpleqa-verified

## Slide 18: Authors and reproducibility

30 seconds. Name both team members. Acknowledge public data, R packages and Codex assistance. Earlier Claude Code review used Kimi; it was not an Anthropic Claude review. Do not invent research contributions or claim completed independent human verification. The report and raw data are public. Invite questions. The following two slides are backup, outside the18-minute plan.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Submission_Pack/report.md

## Slide 19: Appendix: original controlled endpoints

0 seconds. Backup: keep original initially-correct harmful-flip and initially-wrong correction endpoints separate from the later all-unit error analysis. Wrong-only versus wrong-with-reason harmful flips5/154 versus3/154. Same wrong advice under verification3/154 versus0/154 is sparse. Correct advice produces76/322 repairs versus45/322 with verification. These findings prevent selective reporting.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Peer_Misleading_Study/reports/main_r/effects.csv

## Slide 20: Appendix: robustness checks

0 seconds. Backup: semantic recovery of complete format failures leaves facts nearzero and the adjusted math interval touchingzero. Missing planned math outcomes permit effect reversal. The partial reasoning-audit interval includeszero and ignores remaining annotation uncertainty. Detailed tables and all original outputs are in the report.
Source: https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/Followup_Validation/reports/report.md
