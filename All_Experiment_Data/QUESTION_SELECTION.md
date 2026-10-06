# Data selected for the four research questions

The [response-level selection](question_relevant_responses.csv) contains **12,694 unique task rows** from seven completed or explicitly partial-supplement studies. The [matched-comparison table](question_comparison_pairs.csv) contains **9,714 scorable contrast rows**. A response can appear in several contrasts, so 9,714 is **not** a count of independent answers or questions. Both files are generated entirely in R from the unchanged [full inventory](all_experiment_responses.csv).

This selection excludes the 540-row ceiling-effect pilot, 441 development rows, the 100-row standalone MiniMax web test (no checking comparator), and 320 stopped, mostly ungraded online-migration rows. These remain in the full inventory and are not deleted. The selection retains 136 never-requested branches and 27 incomplete tasks for coverage auditing; they are not in the scorable pair file. Do not treat missing output as a wrong answer or an abstention.

| Research question | Direct comparisons in `question_comparison_pairs.csv` | Evidence and limits |
|---|---|---|
| RQ1. Can double-checking decrease the error rate? | Initial answer vs neutral self-check; self-check vs a different model's natural answer; initial answer vs natural cross-check. | Latest two-model completed-data sensitivity: **394 factual** and **164 mathematical** scorable self-vs-peer pairs. The prior three-model expanded validation provides **578 factual** and **199 mathematical** self-vs-peer pairs; it did not confirm a stable benefit. Analyze studies and domains separately. |
| RQ2. Which kind of checking works best in practice? | Natural self-check vs natural peer check; natural peer check vs structured verification; scripted wrong-advice check vs structured verification; structured check with vs without an additional abstention reminder. | Compare methods within the same study and paired eligible set. The earlier controlled factual study and partial mathematical supplement offer mechanism evidence. A reduction in wrong answers can coincide with fewer correct answers and more abstentions. Differences across dates, models, questions, prompts or search access are **not** a causal method ranking. |
| RQ3. Can another model's wrong answer corrupt an initially correct answer? | Latest self-vs-natural-peer pairs link the receiving model's original grade and the actual donor's grade through `baseline_id` and `donor_response_id`. Controlled wrong-advice contrasts are separate supporting evidence. | Among the latest natural pairs, **94** had a correct receiver initial answer and an incorrect peer initial answer; **one** ended wrong after cross-check, the verified Polynomial 11 case. This is a conditional observed case, not an overall error probability. Scripted wrong advice is not a naturally wrong peer answer. |
| RQ4. Can a human misconception create an error that passes through two models? | Model A's neutral vs false-premise initial answer; model B's neutral-donor vs misconception-exposed-donor answer under AI and simulated-human labels; the separate correct-initial-answer neutral vs scripted false-human-challenge comparison. | The full A→B chain had only **seven** eligible opportunities (six facts, one mathematics) and **zero observed final wrong answers** in those opportunities. The separate direct human-challenge test has **78** scorable pairs and **four** wrong challenged finals. The latter is a same-model follow-up, not the full A→B chain; no real human participants supplied the prompts. |

The latest two-model analysis uses a **documented post-hoc semantic completed-data overlay**, not a replacement for the original frozen score. Twenty-one selected mathematical recovery responses used a higher output-token limit. The earlier 13-item mathematical controlled supplement did not meet its planned balanced viability criterion and is descriptive evidence only. The latest two-model search tool was available, but each model chose whether to search; earlier controlled and expanded studies had no search tool. Do not pool these studies into one error rate or infer that all models benefited.

`question_relevant_responses.csv` retains the original columns and adds `condition_role`, `evidence_group`, `receiver_pair_key`, `scorable_answer`, four overlapping RQ membership flags, and `rq4_path`. Each row remains one task. `question_comparison_pairs.csv` has one row per **complete paired contrast** with both original record IDs, grades, wrong-answer indicators, final-answer fields, and—where available—the actual initial and donor grades. The two branches in a comparison are **parallel alternatives**, not a sequential conversation. The direct human-challenge study is also two parallel follow-ups to one selected correct initial answer.

The primary error indicator is `incorrect`; `correct` and explicit `abstain` are both non-errors, while `unscorable`, incomplete, ungraded, and never-requested records are excluded from scorable pair denominators. Show correct and abstain counts separately when interpreting apparent error reductions. Final-answer correctness does not certify every sentence of the explanation.

Rebuild and inspect with R from the repository root:

```r
system('Rscript All_Experiment_Data/R/build_question_subset.R')
system('Rscript All_Experiment_Data/R/build_question_pairs.R')

rows <- read.csv('All_Experiment_Data/question_relevant_responses.csv',
                 stringsAsFactors = FALSE, na.strings = '')
pairs <- read.csv('All_Experiment_Data/question_comparison_pairs.csv',
                  stringsAsFactors = FALSE, na.strings = '')

# Latest RQ1 paired comparison, facts only:
facts <- subset(pairs, experiment == 'two_model_facts' &
                comparison_id == 'self_vs_natural_peer')
table(facts$left_grade, facts$right_grade)

# RQ3: actual wrong peer after a correct receiving-model initial answer:
risk <- subset(pairs, experiment %in% c('two_model_facts', 'two_model_math') &
               comparison_id == 'self_vs_natural_peer' &
               receiver_initial_grade == 'correct' &
               right_donor_grade == 'incorrect')
table(risk$experiment, risk$right_grade)

# RQ4: donor went from correct to wrong after a scripted false premise:
chain <- subset(pairs, comparison_id == 'neutral_ai_vs_misconception_ai' &
                receiver_initial_grade == 'correct' &
                left_donor_grade == 'correct' &
                right_donor_grade == 'incorrect')
table(chain$experiment, chain$right_grade)
```

The [selection audit](question_selection_audit.json) and [pair-coverage audit](question_pair_audit.json) record row counts, exclusions, comparison denominators and SHA-256 checksums. For the published effect estimates and question-cluster uncertainty intervals, use each study's original analysis rather than an unweighted mean over these exports.
