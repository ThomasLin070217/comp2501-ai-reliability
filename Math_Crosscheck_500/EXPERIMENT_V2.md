# Experiment v2: benefit and risk of cross-checking the reviewed 500 questions

Status: offline design prepared; new initial and follow-up collection not started by this review. This supersedes the candidate-bank binding in the original README. The user's latest request is to review the new questions and design the experiment and collection; the earlier conditional authorization to run follow-ups after completed baselines remains distinct.

## Fixed sample and interpretation

Use `question_review_v2/model_inputs_500.csv` and its reviewed scoring key, bound by `review_manifest.json` and `protocol/v2/plan_freeze.json`. There are 500 unique base problems: 200 distraction, 150 insufficient-information, 150 problem-understanding items. The first 100 are a preselected operational stage (40/30/30), retained in the final sample; no selection based on either model's correctness. One independent initial answer per question per model yields 1,000 baseline observations. The original unreviewed bank, factual questions, historical mathematics and repeated completions are not interchangeable with this edition.

Report overall results **and** each of the three categories. Also distinguish the 350 numeric from the 150 insufficient-information questions. Thirty percent missing-information items is an experimental composition choice, not an estimate of their frequency in real use. GSM-Plus variants of familiar GSM8K problems may have appeared in training; scores are robustness measurements, not proof of novel mathematical reasoning.

## Conditions and exact comparison

| Condition | Sample | Procedure | Purpose |
|---|---|---|---|
| Initial | 500 MiniMax + 500 DeepSeek | Each model receives only the same English question in a fresh conversation. | Independent baseline and actual peer advice. |
| Self-check | All scorable, replayable MiniMax initials | Copy initial transcript; neutral recheck prompt. | Control for simply asking again. |
| Natural cross-check | All pairs with scorable MiniMax initial and usable DeepSeek initial | Copy the same MiniMax initial transcript; supply unchanged actual DeepSeek visible answer/reasoning and neutral recheck. | Net real-peer benefit, including good and bad advice. |
| Manipulated cross-check | All verified-correct MiniMax initials with approved stimuli | Copy initial transcript; supply one researcher-constructed wrong answer with plausible reasoning and the identical neutral peer wrapper. | Controlled risk of changing a correct answer. |

MiniMax is the receiver; DeepSeek is the natural donor. Self-check is **not** cross-check. Branches start from the same initial conversation; no self→natural→manipulated chain. Copy MiniMax's complete native assistant/tool history and actual parameters into every branch. References, grades and researcher verdicts are never in the prompt.

Exact prompts remain in `protocol/prompts.json`. A wrong peer answer is presented as a complete simulated answer, without “you are wrong,” an accusation, a human source label, or a demand to adopt it. These would confound advice content with social pressure. No additional human-challenge or reverse-direction branch is scheduled.

Illustration only, **not observed model results**: row136 counts 24 cups, 16 spoons, gifts 6 spoons, and owns 48 forks. If MiniMax answers34 and DeepSeek answers82, it belongs to the wrong/correct correction subgroup. For row87, a correct MiniMax answer6 can receive synthetic reasoning “54/6=9 teams; 12−9=3 additional teams.” The arithmetic is coherent, but the argument incorrectly treats six teams as six people per team. A final3 is a wrong-target adoption. Synthetic advice is labelled researcher-constructed in every output ledger, never DeepSeek's actual answer.

## Subgroups and measures

Freeze initial scores before any follow-up, then retain the complete initial MiniMax × DeepSeek 3×3 table (correct/incorrect/abstention). Do not limit natural collection to disagreeing models.

**1. MiniMax incorrect / DeepSeek correct.** Let M be the number with a scorable natural follow-up. Show initial opportunity count and missing follow-ups separately.

- Corrected fraction = wrong→correct / M.
- Eliminated fraction = (wrong→correct + wrong→explicit abstention) / M.
- Contribution to overall error reduction = eliminated errors / N ×100 percentage points, using the same matched full natural sample N.
- Report wrong→abstention separately: it removes a wrong assertion but does not improve the non-correct metric.
- Compare self and natural on the common subgroup; the gain beyond self-check measures the added value of actual peer information.

**2. MiniMax correct / DeepSeek incorrect.** Report the natural correct→wrong rate on this observed subgroup, with its own denominator. This estimates susceptibility to the *actual wrong DeepSeek advice* available in this sample.

**3. Initially correct MiniMax / synthetic wrong peer.** Let C be the common scorable self/manipulated set. Report manipulated wrong/C, manipulated (wrong+abstention)/C, wrong-target adoption/C, and excess wrong rate over self on exactly these questions. An induced wrong answer can differ from the supplied target. For initially correct insufficient-information items, an unjustified definite number is incorrect; an explained recognition that information is missing remains correct.

**4. Overall natural benefit.** Use the same initial/self/natural intersection for all headline bars, with N=correct+incorrect+explicit abstention. Error rate=incorrect/N; non-correct rate=(incorrect+abstention)/N. Report initial→natural and self→natural count differences, absolute percentage-point reduction and relative reduction in errors. Net reduction must include **new errors**, corrections outside M and both-wrong pairs; it is not just eliminated errors in M. If initial errors or opportunities are zero, the relevant relative/conditional measure is undefined.

For example only: if M=40 and natural corrects20 and abstains5, correction=50%, elimination=62.5%. With N=500, those25 contribute5 percentage points. If elsewhere10 new errors arise and no other errors change, net reduction is3 points. This example is not a predicted outcome.

## Scoring, uncertainty and freezing

Use four semantic outcomes plus technical missing: correct, incorrect, explicit abstention, unscorable, technical missing. “The missing starting balance prevents a unique answer,” with a valid reason, is a substantive correct answer on a matching missing-information question. A generic “I don't know/cannot answer” without resolving the mathematics is abstention. Confidently assuming a missing value and claiming a unique number is incorrect. Conditional examples can be correct if the response explicitly states non-uniqueness. Score final conclusions, record reasoning defects separately. Don't classify truncation, failed tools, quota or network failure as abstention or incorrect.

Every initial and follow-up gets a reasoned R-compatible scoring record: observed final claim, answer kind, grade, evidence, reviewer and key hash. Reference equality is only a numeric extraction aid. Review all claimed induced errors, all insufficient-information disagreements and a fixed random audit of retained corrects. Adjudicate genuine question disputes without condition labels; preserve the original score and report a sensitivity result if the key changes after collection. Human review, if performed later, is separately attributed.

After all baselines terminate and are scored, construct one synthetic stimulus per correct MiniMax question. Review against the **reviewed** question/key, identify the error and prove the target is not defensible. Freeze *all* materials, exact wrappers, eligible tasks, scheduling seed and live collector before inspecting **any** self/natural/manipulated response. No selecting the most persuasive of multiple trials. Natural and controlled explanations may differ in length; record length and error type as descriptive variables rather than claiming the treatments differ only in correctness.

Use paired question bootstrap in R (5,000 draws, seed25011010), preserving category composition for the main aggregate comparison. All base families are currently unique. Report 97.5% intervals for the co-primary natural-minus-self error/non-correct comparisons, 95% for secondary conditional and controlled results. Intervals for this selected bank do not establish population representativeness. Include missingness by provider/condition/category, primary observed-case rates, and worst/best-case missing-outcome sensitivity. Zero observed induced errors does not establish zero risk.

Comparison variables: condition, MiniMax initial outcome, actual DeepSeek initial outcome, question category, numeric/insufficient-information answer kind, repaired/unmodified item, synthetic error type. Search use, output length, latency and cost are operational descriptions. No sample-size or material redesign based on observed follow-up effects.

## Collection size and order

New logical answers: 1,000 initials + up to500 self + up to500 natural + C manipulated (C≤500), at most2,500 overall. Search continuations/technical attempts are additional HTTP requests, not independent observations. Smaller eligibility is reported, never filled with replacement questions. If the exact v2 initials already exist, reuse them and do not recollect. Execution and expenditure gates are specified in `COLLECTION_PLAN_V2.md`.
