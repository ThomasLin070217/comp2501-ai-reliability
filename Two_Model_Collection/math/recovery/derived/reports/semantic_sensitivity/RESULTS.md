# Mathematics experiment: collection and paired analysis

All scheduled tasks are completed or explicitly logged as unavailable.

41 questions; 15 preselected mechanism questions; 732/732 completed target records; 0 dependency skips; 0 not collected.

Error rate = wrong / (correct + wrong + explicit abstention). Technical and formatting failures are separate.
Within each paired comparison, repetitions are averaged per question/model, then questions are averaged, then the two models receive equal weight. Intervals resample question clusters 5,000 times.
Natural cross-checking uses a 97.5% interval (two task-domain primary comparisons); other intervals are exploratory 95% intervals. No result determines stopping or additional sampling.

- natural_crosscheck: 10.37% to 5.49%; difference -4.88 percentage points; 97.5% CI [-9.15, -1.22]; 41 questions, 164 pairs.
- initial_vs_self: 13.41% to 10.37%; difference -3.05 percentage points; 95.0% CI [-5.49, -0.61]; 41 questions, 164 pairs.
- upstream_misconception: 6.67% to 1.67%; difference -5.00 percentage points; 95.0% CI [-11.67, 1.67]; 15 questions, 60 pairs.
- propagation_AI: 0.00% to 0.00%; difference +0.00 percentage points; 95.0% CI [0.00, 0.00]; 15 questions, 58 pairs.
- propagation_Human: 1.67% to 0.00%; difference -1.67 percentage points; 95.0% CI [-5.00, 0.00]; 15 questions, 58 pairs.
- attribution_A0: 0.00% to 1.67%; difference +1.67 percentage points; 95.0% CI [0.00, 5.00]; 15 questions, 59 pairs.
- attribution_A1: 0.00% to 0.00%; difference +0.00 percentage points; 95.0% CI [0.00, 0.00]; 15 questions, 58 pairs.

## Limits

The 41 reference answers were reviewed before collection. Numeric final answers do not establish valid reasoning. Semantic review of unusual final-answer forms and answer/reason contradictions is reported separately from strict scoring.
The mechanism subset is exploratory. Report full-path counts and denominators, including zero opportunities; do not infer a general error-propagation mechanism from rare cases.
Human attribution is simulated by a fixed user-source header; no human participants supplied these suggestions. A1 describes an input condition, not guaranteed wrong output.
Autonomous search is not randomly assigned, so searched versus unsearched comparisons do not establish the causal effect of search. Sources may contain benchmark copies.
