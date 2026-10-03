# Completed follow-up: reading and offline reproduction

Start with [中文结果说明](reports/结果说明_中文.md) or the [full report](reports/report.md). The directory's original README and protocol are frozen design records, not a live results summary.

From the repository root, with R, jsonlite, digest, curl, ggplot2 and knitr installed:

```sh
Rscript Followup_Validation/R/analyse.R
Rscript Followup_Validation/R/diagnostics.R
Rscript Followup_Validation/R/semantic_sensitivity.R
Rscript Followup_Validation/R/peer_diagnostics.R
Rscript Followup_Validation/R/review_math.R analyse
Rscript Followup_Validation/R/codex_reasoning_audit.R
Rscript Followup_Validation/R/write_report.R
Rscript Followup_Validation/R/chinese_digest.R
```

These commands use saved responses and annotations, make no model calls and do not need credentials. `codex_reasoning_audit.R` reproduces explicitly recorded Codex judgments and arithmetic checks; running it is not a fresh independent review. The semantic sensitivity reads saved Codex annotations and preserves original field grades.

For a second-pass byte comparison of deterministic tables, Markdown and charts, run:

```sh
Rscript Followup_Validation/R/verify_reproduction.R
```

Generation timestamps in JSON receipts are not compared. Frozen inputs and every raw experimental/reviewer response file must remain byte-identical. Receipts appear in `reports/reproduction_validation.json` and `reports/reproduction_hashes.csv`.

Do not rerun `prepare.R`, `test.R` or reviewer `prepare` in this frozen directory: they write design/request artifacts. Live `collect` modes incur costs and are not part of offline reproduction. The three rejected initial reviewer requests and temperature correction are retained as a documented implementation amendment, not concealed retries.

The follow-up is a separate supplement. Earlier PPT, PDF and ZIP files in `Submission_Pack` were built before this follow-up and do not contain these results. Do not describe those historical artifacts as the final integrated version of this supplement.
