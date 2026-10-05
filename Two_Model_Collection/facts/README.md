# Facts collection — revised two-model protocol

**Current status:** scheduled run finished: 1,576 recorded HTTP calls, 24 dependency skips, zero pending tasks. See [the reviewed final report](reports/REVIEWED_RESULTS.md) for primary results, semantic and source-exposure sensitivities, missingness and the separate technical-recovery inventory. “Finished” means every planned task reached a terminal state, not that every task yielded a valid answer. The initial budget below was superseded by the user's later instruction to complete collection without that ceiling; frozen amendments preserve the history.

**Subsequent technical recovery:** the [separate recovery appendix](recovery/reports/RECOVERY_REPORT.md) resolved all 14 technical failures and restored 15 dependent branches using 30 new HTTP attempts. Its derived view contains 1,591 complete records and nine remaining schema-blocked branches. Original files and primary results are unchanged; use the labelled derived paths when reporting recovery-completed results.

100 inherited factual questions; MiniMax and DeepSeek; two independent repetitions. Natural initial/self-check/A0-AI comparisons require 1,200 target answers. A fixed, stratified 25-question mechanism subset adds 400 answers, for **1,600 target answers**. These are target counts, not completed observations.

The subset was selected before new output was inspected using R seed 25011005, proportional largest-remainder allocation over date granularity: 9 day, 3 month and 13 year questions. All 100 original neutral questions and reviewed misleading-premise stimuli are preserved; no question was selected because a new model response was wrong.

`protocol/freeze.json` hashes the sampling, prompts, scoring and dependency manifest. `reports/preflight_checks.json` records 15 successful offline checks. Shared runtime configuration and provider checks are controlled by the parent collector. This domain must not start until those checks and the overall budget guard are ready.

- Facts allocation: **CNY 280 maximum**, including failed requests and unresolved HTTP reservations; this does not reset the overall CNY 500 project allowance.
- All model-facing prompts are English and copied from the reviewed prompt package.
- Neutral and misconception initial answers use separate fresh sessions.
- Each final review branch copies the same receiver's neutral history, including native search history.
- Only real, strictly parsed donor output from the other model at the same question/repetition may be inserted.
- Matched AI/Human donor bodies are identical; only the introductory source header changes.
- Search is available but not required. No-search answers remain in analysis.
- No retry for a desired answer or a desired statistical finding.
- Reference answers stay on the researcher side and are never sent in API request messages.

R scoring retains the inherited strict date parser and reference granularity. Explicit abstention is not an error or a correct answer. Empty, malformed, truncated and transport-failed outputs are separate. Per-answer semantic issues are reported separately without silently changing the frozen endpoint.

Run `Rscript Two_Model_Collection/facts/R/analyse.R` to regenerate descriptive and paired reports after collection. The main endpoint is self-check versus A0-AI error probability; question-cluster uncertainty and paired coverage accompany the equal-model mean. Mechanism effects and full propagation paths are exploratory.
