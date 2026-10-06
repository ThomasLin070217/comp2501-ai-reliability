# Fact recovery: independent R reconciliation (6 October 2026)

The earlier `fact_direct_supplement_scored_1000.csv` includes six scoreable responses from MiniMax's separate official China endpoint. A later resumed run produced one more complete final response for `fact500:FS_77c95f87fd:minimax:single`. The raw final has status `complete_end_turn` and ends by explicitly saying it cannot confidently identify the requested parish school board. The newer review decisions mark it `abstain`, but the earlier 1,000-cell export still labels the task technically incomplete. One prose addendum also says four scoreable direct-route responses, inconsistent with the seven graded rows in its associated decisions CSV.

[`R/reconcile_fact_direct_resume.R`](R/reconcile_fact_direct_resume.R) checks unique task IDs, source coverage, the raw resumed final, the later grading decision, and that exactly one cell changes. It writes a **derived overlay** under `derived/`; it does not modify the original collection or scoring files.

| View | DeepSeek scoreable | MiniMax scoreable | MiniMax correct | MiniMax incorrect | MiniMax abstain | MiniMax error |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Frozen original initial review | 497 | 433 | 330 | 69 | 34 | 15.94% |
| Original-gateway recovery view | 500 | 463 | 350 | 77 | 36 | 16.63% |
| Prior official-endpoint supplement | 500 | 469 | 354 | 78 | 37 | 16.63% |
| **Resumed official-endpoint overlay** | **500** | **470** | **354** | **78** | **38** | **16.60%** |

DeepSeek's last three views are 423 correct, 44 incorrect, 33 abstain among 500 scored, or 8.80% wrong. The seven graded direct-route MiniMax responses comprise four correct, one incorrect, and two explicit abstentions. In the final overlay, 29 MiniMax tasks remain technically incomplete and one is unscorable. Different scored subsets and provider routes prevent a matched model ranking from these percentages. The original HKU-gateway result remains unchanged.

Run from the repository root:

```sh
Rscript Night_Audit_2026-10-06/R/reconcile_fact_direct_resume.R
```

Files: `derived/fact_direct_supplement_resumed_scored_1000.csv`, `derived/fact_direct_supplement_resumed_summary.csv`, and `derived/fact_direct_supplement_resumed_audit.json`. This is a reconciliation of recorded final-answer labels, not an independent verification of every benchmark key or every sentence in the model explanations.

## Independent R rebuild of the later frozen fact snapshot

The later `Initial_Response_Accuracy_Evaluation/processed/fact_frozen_2026-10-06/` snapshot can be reconstructed by [`R/rebuild_fact_freeze.R`](R/rebuild_fact_freeze.R) from the initial 1,000 cells, their 931 semantic decisions, the 33 selected original-gateway recovery finals, the six first-batch official-endpoint finals, and the one resumed official-endpoint final. The script checks every selected recovery text against its native `final.json`, verifies the source hashes listed in the freeze manifest, and compares **all 1,000 rows and 11 columns** with the frozen snapshot. There were zero cell/column disagreements.

The R-derived export and counts are `derived/fact_frozen_rebuilt_R_1000.csv` and `derived/fact_frozen_rebuilt_R_summary.csv`; `derived/fact_frozen_rebuilt_R_audit.json` contains input/output hashes. The result is DeepSeek 423 correct, 44 incorrect, 33 abstain among 500 scoreable; MiniMax 354 correct, 78 incorrect, 38 abstain among 470 scoreable, with 29 technical gaps and one unscorable answer. This is a reproducible reconstruction of the recorded **final-answer labels**, not an independent validation of every reference key or reasoning explanation.

The same R script separately exports `derived/fact_selfcheck_conditional_R_summary.csv`: of the **originally wrong** 112 answers, 27 changed to correct, 79 remained wrong and six abstained. One *newly recovered* wrong DeepSeek answer was self-checked separately and remained wrong. These conditional counts do not estimate the error rate after self-checking all 1,000 question/model cells; newly recovered MiniMax errors were not self-checked.
