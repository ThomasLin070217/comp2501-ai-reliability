# Callable Self-check workflow

Implementation: `R/selfcheck_runtime.R`, with command-line entry `R/run_selfcheck.R`. It reuses the installed R libraries rather than adding a second runtime. The user has now allowed other languages; keeping R here is an implementation choice, not an ongoing language restriction.

Self-check means copying a complete MiniMax independent initial conversation, retaining its system configuration, generation parameters and native tool history, then adding exactly:

> Please check the original problem again and give your final answer.

All replayable correct, incorrect and explicit-abstention initials are eligible, up to 500. No DeepSeek answer, reference key, initial correctness label or evaluator judgment enters a Self-check payload. Each branch starts from the original initial conversation. It does not inherit another follow-up.

## Commands

Run from the repository; the entry point also resolves its own repository location when invoked by absolute path.

```sh
# Check the real baseline gate; no credentials or model calls.
Rscript Math_Crosscheck_500/R/run_selfcheck.R --mode check

# After all 1,000 initial tasks are terminal and scored, prepare the full study.
# Include approved OR documented excluded material decisions for every correct MiniMax initial.
Rscript Math_Crosscheck_500/R/prepare.R --materials Math_Crosscheck_500/inputs/synthetic_materials.csv

# After real adapter certification and the current quota/expense guard are recorded:
Rscript Math_Crosscheck_500/R/run_selfcheck.R --mode freeze

# Default scope sends only self tasks, pausing at the next cross-check in the joint schedule.
Rscript Math_Crosscheck_500/R/run_selfcheck.R --mode run

# For the already-authorized full experiment: process the same frozen interleaved schedule.
# Includes natural and manipulated cross-check, as well as self-check.
Rscript Math_Crosscheck_500/R/run_selfcheck.R --mode run --scope joint

# Rebuild a grading handoff without model requests.
Rscript Math_Crosscheck_500/R/run_selfcheck.R --mode export
```

The self-only command deliberately pauses when the next scheduled task belongs to another condition. This preserves the existing randomized branch order instead of silently collecting all self-checks first. A joint orchestrator can call the functions below. Resume uses the same freeze/output directory and skips terminal tasks. `--task TASK_ID` selects exactly one task; earlier scheduled tasks must already be terminal. The three conditions share a ledger and lock.

```r
source('Math_Crosscheck_500/R/selfcheck_runtime.R')
plan <- sc_read('Math_Crosscheck_500/prepared/execution/run_manifest.json')
# ID must come from the frozen manifest, not a constructed replacement question.
run_self_check(plan, task_id, 'Math_Crosscheck_500/runs/followups')
# The joint scheduler uses sc_run_one(plan, task_id, out) for the other conditions.
```

## Preparation and transport

`--mode check` waits when the reviewed mathematics baseline index is missing or unfinished. It never searches old experiments for substitute answers. `--mode freeze` also requires a complete synthetic decision ledger, even for a self task: every initially correct MiniMax question must have an approved material or a documented exclusion before any follow-up results are seen. The prepared tasks, exact donor text, receiver settings, all replay files, code, configuration and reviewed design hashes are bound into the execution freeze.

Copy `protocol/v2/selfcheck_transport.example.json` to `inputs/selfcheck_transport.json` and complete it using current applicable authorization and actual interface certification. The example intentionally cannot run: certification is false and the new quota/expense ceiling is unset. Set `adapter_verified`, a certification evidence file, `authorization_source`, and a finite guard ceiling. The receiver model must exactly match the recorded initial request. Do not use old candidate generation settings to overwrite actual baseline parameters.

The current adapter supports the project's HKU Anthropic-compatible MiniMax endpoint and native server-side tool replay. Authentication is read only from `MINIMAX_API_KEY` at dispatch and never placed in requests/manifests. Certification must demonstrate that the actual initial tool transcript can be replayed with this adapter; offline tests do not prove live compatibility. Unsupported client tools remain incomplete; the worker does not fabricate tool results. Model aliases and returned identifiers are recorded, with no claim of immutable provider versions.

The guard reserves each HTTP attempt against a finite cap, including failed attempts, retries and search continuations; reservations are never refunded on resume. Supported units are CNY (a documented conservative per-attempt reservation) and course-quota HTTP requests (one per attempt). A request quota is not a token limit or a cash-price estimate: use it only where current course authorization is actually in requests; otherwise certify the appropriate guard before collection. Monetary cost stays unknown unless independently established. All raw usage fields, including cache/search fields exposed by the provider, remain in the saved response. Actual bills and usage can be reconciled separately. The worker runs serially, within the existing maximum concurrency of four, to make delivery and checkpoints explicit.

## Delivery, recovery and outputs

Before dispatch, save a full authentication-free request and its hash. Save the raw response body before interpreting it. Atomic files, a shared exclusive lock and frozen task IDs prevent ordinary duplicate dispatches. A stale lock is not automatically removed. Inspect its recorded owner and the raw ledger before manual recovery.

- A received transient 500/502/503/504 allows at most one identical-payload retry per logical task. No correctness-dependent retry occurs.
- Transport exceptions, or a request saved without a durable response, stop the run as unknown delivery. Reconcile with provider records; do not resend automatically.
- 401/402/403/429 stops the entire run for authentication/quota/rate reconciliation. Removing a STOP marker does not bypass unresolved raw failures.
- `pause_turn` continues the same assistant turn, preserving native blocks and parameters, at most three continuations. It adds no new user message. These are extra HTTP attempts, not independent answers.
- Token truncation, empty/malformed final output and unresolved client tools are incomplete/technical missing, never explicit abstention. Complete prose remains pending semantic grading.
- Create `runs/followups/STOP` to prevent the next dispatch. Paid calls occur only in explicit run mode.

Each task has `http_XX_request.json`, `http_XX_response.json` and `final.json`, preserving full messages, raw text, source/settings/task metadata, returned model, finish reason, reservations and file hashes. A crash after saving a response but before saving its final record is reconstructed from that response on resume without a fresh request. `grading_input.csv` is a derived handoff with blank grades and review evidence; save adjudicated grades elsewhere so re-export cannot overwrite them. No numerical string matcher decides correctness, and a justified insufficient-information conclusion must not be called abstention.

After semantic grading, compare initial and self on the same scorable questions using Error rate = Incorrect/N and Non-correct rate = (Incorrect + Explicit abstention)/N. N excludes technical missing and unscorable cases. Preserve wrong→correct, wrong→abstention and correct→wrong transitions separately. Collection completion is not scoring or experimental-result completion.

## Verification and current state

```sh
Rscript Math_Crosscheck_500/R/test_selfcheck.R
```

The tests use temporary, explicitly synthetic fixtures and fake HTTP responses; no credentials or provider requests. They exercise conversation/settings retention, eligible initial grades, neutral prompts, hash tampering, duplicate prevention, unknown delivery, quota/auth stops, native paused-turn continuation, truncation and retry limits. An end-to-end temporary 500×2 baseline tests the real preflight/preparer/execution freeze without substituting fixtures into the study.

The implementation is callable. The real baseline index is not available at implementation time; no new mathematics initial or follow-up calls were made. The paused heartbeat remains paused. Live adapter certification and the current authorized guard still have to be supplied before formal execution.
