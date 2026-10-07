# All experimental answer records in one CSV

For the current four research questions, use the [question-specific selection and pairing guide](QUESTION_SELECTION.md). Its two derived CSVs keep the full inventory unchanged and separate task rows from matched comparisons.

[`all_experiment_responses.csv`](all_experiment_responses.csv) is the single R-ready, response-level table for **every evaluation task recorded in the studies' canonical outcomes and skip logs**. It contains 14,095 unique task rows from the pilot, factual and mathematical development/formal studies, natural cross-check and expanded validation, the standalone web factual test, the stopped online replication, the two-model recovery overlay, and the scripted human-challenge follow-up. The 136 branches that were never requested remain rows with missing response text and a nonresponse status. Failed technical attempts are represented through the selected task outcome; retry attempts are preserved in their original source logs, not duplicated as extra answers.

This is an **append-only research inventory, not a pooled statistical sample**. The studies used different questions, models, tools, prompts, dates, and eligibility rules. In particular, `online_replication_partial` was stopped early and has no finalized semantic grades for its 317 normally completed records; tasks planned for after that stop are not observations and are not padded into this table. Earlier development and pilot responses are retained for provenance, not merged into later formal effect estimates. Source-material generation, AI-judge calls, acquisition probes, duplicate archived snapshots, aggregate tables, and individual web-search/tool events are not question-answer observations and are not rows in this CSV. Their original files remain available in the named study folders.

### Public release, 8 October 2026

The current public release is [`../Public_Data_Release_2026-10-08/`](../Public_Data_Release_2026-10-08/). Its 14,174-row response inventory withholds question, answer-key, prompt, and response text for six local university-exam/workbook questions whose redistribution was not cleared, while retaining non-sensitive outcome metadata. The complete local working inventory remains an internal source and should not be uploaded as-is. Use the public release's README and R script for reproducible current results.

| Experiment (`experiment`) | Rows |
|---|---:|
| `pilot_2026_09_30` | 540 |
| `peer_misleading_development` | 315 |
| `peer_misleading_main` | 5,040 |
| `math_supplement_development` | 126 |
| `math_supplement_supplementary` | 546 |
| `natural_crosscheck` | 588 |
| `followup_validation` | 4,032 |
| `web_factcheck_100` | 100 |
| `online_replication_partial` | 320 |
| `two_model_facts` | 1,600 (1,591 selected answers + 9 blocked branches) |
| `two_model_math` | 732 |
| `human_challenge_followup` | 156 |
| **Total** | **14,095** |

The grain is **one question × receiving model × repetition × prompt condition task**, except the human-challenge follow-up, which has one selected correct initial answer per question/model and two follow-up conditions. `observation_id` is globally unique across the table. `source_file` and `source_record_id` identify the canonical study record. The same underlying question may occur in multiple studies; use `experiment` and `question_id` together. An original baseline reused across two follow-up arms is deliberately represented by two *follow-up* observations, with the common `baseline_id`.

Key columns:

| Column(s) | Meaning |
|---|---|
| `experiment`, `experiment_phase`, `domain`, `question_family` | Study identity and context. |
| `question_id`, `question_text`, `reference_answer` | Input item and its retained study reference; reference answers can be JSON-like for mathematical nonnumeric outcomes. |
| `provider`, `other_model`, `repeat_id`, `condition`, `baseline_id`, `donor_response_id` | Model roles, task condition and link to original baseline/peer records when available. Condition codes have study-specific meanings; see the original protocol before comparing them. |
| `prompt_last_user`, `intervention_answer`, `intervention_reason` | Last user turn sent to the model, drawn from retained raw requests when available. The two intervention fields hold the scripted false answer and rationale in the human-challenge arm; blank means they do not apply. The full multi-turn prompt and tool history remain in the original raw logs. |
| `response_status`, `response_text` | Task status and unchanged selected model text. Missing text means there was no answer for that task. |
| `grade`, `grade_basis`, `grade_frozen`, `grade_semantic` | Harmonized grade plus its provenance. `grade` is `correct`, `incorrect`, `abstain`, `unscorable`, or missing. For the two-model recovery overlay it uses the documented post-hoc semantic grade; the frozen original remains in `grade_frozen`. A missing grade is **not** an error or abstention. |
| `is_wrong`, `is_abstain` | 1/0 indicators only when scorable; `NA` for unscorable or ungraded tasks. These are per-response indicators, not an analysis denominator. |
| `final_answer`, `response_conclusion`, `answer_value`, `reason` | Parsed or source-supplied fields for convenient filtering. Mathematical structured conclusions and numeric values are kept separately. The full `response_text` is authoritative when extraction is missing or ambiguous. |
| `native_search_available`, `native_search_calls` | Whether a native search tool was enabled and recorded calls when available. Enabled does not mean used. |
| `note` | Important row-level qualifications, including partial collection and the scripted nature of the human challenge. |

Read it in R:

```r
path <- 'All_Experiment_Data/all_experiment_responses.csv'
d <- read.csv(path, stringsAsFactors = FALSE, na.strings = '', fileEncoding = 'UTF-8')
table(d$experiment)
subset(d, experiment == 'human_challenge_followup' & grade == 'incorrect',
       select = c(question_id, provider, condition, final_answer, response_text))
```

Do **not** compute a project-wide average of `is_wrong`: it would weight the 5,040-row older factual study far more heavily than the 156-row human-challenge supplement and ignore matched-pair selection. Use the study's original analysis script and eligibility rules for effects and intervals.

Rebuild entirely in R from the original study files:

```bash
Rscript All_Experiment_Data/R/build_all_responses.R
```

The script asserts each source count, globally unique IDs, valid grade categories, and CSV round-trip equality of IDs and raw response text. [`audit.json`](audit.json) records counts, grade distributions, completeness and a SHA-256 checksum of the generated CSV. It does not alter any original dataset or frozen score.
