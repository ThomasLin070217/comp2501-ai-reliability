# GSM-Plus v3 presentation addendum

Updated 2026-10-07. The current deliverable is
`output/COMP2501_presentation_FINAL_RESULTS_GSMPLUS_2026-10-07_v8.pptx`
(30 slides). It extends the earlier 27-slide private-math/fact deck without
overwriting the user-supplied template or the earlier finished copies. The
v7 deck remains available as a historical version.

The GSM-Plus v3 result slides are 17–19. R-derived counts support the charts;
slide 18 shows the two zero-event conditions in an editable table:

| Slide | Cohort and condition | Checked result |
|---|---|---|
| 17 | GSM-Plus v3 MiniMax, common 495 scoreable questions | Initial 17/495 wrong, neutral self-check 9/495, natural cross-check using a real independent DeepSeek reply 4/495. Natural-minus-self 95% bootstrap interval is −2.22 to 0.00 percentage points. |
| 18 | Separate selected 50-question GSM-Plus v3 test, MiniMax | Neutral self-check and researcher-scripted wrong AI peer both 50/50 correct and 0/50 wrong; scripted false-target adoption 0/50. |
| 19 | Separate selected 50-question GSM-Plus v3 first-prompt test, fresh calls | DeepSeek neutral 0/50 wrong versus false premise 3/50; MiniMax 1/50 versus 5/50. MiniMax four paired correct-to-wrong changes, three direct false-target adoptions, exact paired p=0.125. Orders 86, 160 and 252 have post-hoc question-ambiguity sensitivity. |

The final cover uses the user-approved title “Can We Trust AI More After
Cross-Checking?” and names LINYUNIAN and PAN ZHENGYU. The private revised
mathematics 500-question M1–M4 study is a different bank.
Its rates remain on separate slides and are not pooled with GSM-Plus v3. The
simulated AI peer and user prompts are researcher-written. GSM natural cross
uses an actual independent DeepSeek answer. The first-prompt experiment starts
fresh conversations; private M4 is a post-answer follow-up.

In private M3, the one wrong answer on 68 complete pairs was an unrelated
wrong decimal beside a correct exact expression. None of the 69 scoreable M3
answers adopted the injected false target. This does not show successful
persuasion by the simulated AI suggestion. The appendix now keeps the main
same-question 66/488 to 42/488 comparison and lists technical truncations
without juxtaposing nonmatching mixed-budget rates.

Slide 22 answers the possibility question with a separate, older natural
Polynomial 11 case. DeepSeek answered 20 initially and after self-check,
received MiniMax's independently generated wrong answer 24, then changed its
cross-check answer to 24. An independent R recurrence confirms 20. This is
one verified correct-to-wrong case, not an estimate of how often it occurs.
The new selected scripted GSM-Plus v3 wrong-peer test had 0/50 false-target
adoptions. The two studies have different questions and conditions. The
older case is documented in `Two_Model_Collection/reports/RESULTS_SUMMARY.md`
and `Two_Model_Collection/R/summarize_results.R`.

New figures were produced in R from graded CSVs, with input-value checks.
The local authoring script is `R/render_gsmplus_v3_addendum.R`. Main sources are
`Math_Crosscheck_500/collection_v3_followups/analysis/condition_counts_common.csv`,
`Math_Crosscheck_500/collection_v3_followups/analysis/paired_error_effects.csv`,
`Math_Crosscheck_500/collection_v3_controlled/derived/controlled_summary.csv`,
and `Math_Crosscheck_500/collection_v3_human_first/derived/*_first_prompt_summary.csv`.
The cross-study inventory is
`Night_Audit_2026-10-06/derived/current_evidence_inventory.csv`.

The four-page evidence report is now available at
`Submission_Pack/Final_Report_2026-10-07/output/pdf/COMP2501_evidence_report_2026-10-07.pdf`
and was published in Git commit `d0b73eb`. It covers GSM-Plus v3, the
private revised-math aggregates and the fact-study limitations. The older
`Submission_Pack/report.Rmd`, `report.md`, `report.html` and
`COMP2501_report.pdf` are historical 2026-10-04 artifacts. A 30-page PDF
backup of the final slide deck is now available at
`output/COMP2501_presentation_FINAL_RESULTS_GSMPLUS_2026-10-07_v8.pdf`.
