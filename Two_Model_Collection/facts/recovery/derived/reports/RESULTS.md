# Facts experiment: collection and paired analysis

All scheduled tasks are completed or explicitly logged as unavailable.

100 questions; 25 preselected mechanism questions; 1591/1600 completed target records; 9 dependency skips; 0 not collected.

Error rate = wrong / (correct + wrong + explicit abstention). Technical and formatting failures are separate.
Within each paired comparison, repetitions are averaged per question/model, then questions are averaged, then the two models receive equal weight. Intervals resample question clusters 5,000 times.
Natural cross-checking uses a 97.5% interval (two task-domain primary comparisons); other intervals are exploratory 95% intervals. No result determines stopping or additional sampling.

- natural_crosscheck: 22.97% to 4.79%; difference -18.18 percentage points; 97.5% CI [-22.25, -14.00]; 100 questions, 385 pairs.
- initial_vs_self: 19.69% to 23.22%; difference +3.54 percentage points; 95.0% CI [1.52, 5.81]; 100 questions, 388 pairs.
- upstream_misconception: 12.00% to 15.00%; difference +3.00 percentage points; 95.0% CI [-6.00, 12.00]; 25 questions, 99 pairs.
- propagation_AI: 2.00% to 3.00%; difference +1.00 percentage points; 95.0% CI [-2.00, 4.00]; 25 questions, 100 pairs.
- propagation_Human: 3.00% to 1.00%; difference -2.00 percentage points; 95.0% CI [-5.00, 0.00]; 25 questions, 97 pairs.
- attribution_A0: 2.00% to 3.00%; difference +1.00 percentage points; 95.0% CI [0.00, 3.00]; 25 questions, 99 pairs.
- attribution_A1: 3.00% to 1.00%; difference -2.00 percentage points; 95.0% CI [-5.00, 0.00]; 25 questions, 98 pairs.

## Limits

Reference dates are inherited from the retained question bank, not newly adjudicated against every primary source. Model answer/reason conflicts and unusual date formats require separate semantic review.
The mechanism subset is exploratory. Report full-path counts and denominators, including zero opportunities; do not infer a general error-propagation mechanism from rare cases.
Human attribution is simulated by a fixed user-source header; no human participants supplied these suggestions. A1 describes an input condition, not guaranteed wrong output.
Autonomous search is not randomly assigned, so searched versus unsearched comparisons do not establish the causal effect of search. Sources may contain benchmark copies.
