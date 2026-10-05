# Facts technical recovery — separate appendix

Status: finished. **30 new HTTP attempts produced 29 selected complete responses**, resolving all 14 original technical failures and enabling 15 dependent branches. Nine other branches remain blocked by original schema-invalid initial answers. They were not retried.

Read [the recovery report](reports/RECOVERY_REPORT.md). Original primary results remain unchanged in `../reports/`. The derived secondary view is in `derived/`, with explicit provenance. Every direct replay retained the exact original request payload and 768-token limit; the HTTP timeout was increased to 600 seconds. The five original incomplete records were `tool_use` failures, not output-token truncation.

Rebuild the offline appendices from the repository root:

```sh
Rscript Two_Model_Collection/facts/recovery/R/audit.R
Rscript Two_Model_Collection/facts/recovery/R/analyse.R
Rscript Two_Model_Collection/facts/recovery/R/review.R
```

These commands do not make model calls. `R/collect.R` is the separately frozen, already completed recovery collector; all raw attempts and responses are retained in `runs/`. No correctness-dependent retry occurred.
