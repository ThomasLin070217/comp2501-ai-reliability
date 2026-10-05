# Two-model autonomous-search collection

This new collection tests **Can We Trust AI More After Cross-Checking?** using MiniMax M3 and DeepSeek V4 Pro. Collection started on 5 October 2026 after the domain protocols, shared runtime and analysis scripts were frozen. Historical offline and earlier three-model records are retained separately.

## Scope

| Domain | Questions | Mechanism subset | Planned responses |
|---|---:|---:|---:|
| Facts | 100 | 25 | 1,600 |
| Mathematics (CHAMP) | 41 | 15 | 732 |
| Total | 141 | 40 | 2,332 |

Both models independently answer each question twice. The receiver's same neutral initial response is reused in parallel self-check and cross-model-check branches. The donor is always the other model in the same repetition. No third judge or iterative debate is used.

The natural comparison includes neutral initial answers, self-checks and cross-checks using neutral donor answers (A0_AI). The fixed mechanism subsets additionally collect donor answers following a misconception prompt (A1), then compare A0/A1 material attributed to an AI or a human. The supplied answer, abstention state and reason are identical across source labels; only the introduction changes. A1 answers are retained whether wrong, correct or abstaining. Human attribution simulates an interaction; there are no human participants.

Each model has its native web-search tool available and chooses whether to use it. Prompts do not instruct it to search. No shared retrieval evidence is inserted. A response without a search remains eligible. The receiver's initial native tool history is preserved in its follow-up branches.

## Frozen files and execution

- Shared runtime and analysis hashes: [runtime_freeze.json](protocol/runtime_freeze.json).
- Fact tasks, sample, prompts and grading: [facts/protocol](facts/protocol).
- Mathematical tasks, sample, prompts and grading: [math/protocol](math/protocol).
- Offline runtime checks: [runtime_checks.json](protocol/runtime_checks.json).
- All collection, processing, scoring, statistics and plots use R.

From the repository root, in separate R processes:

```r
source("Two_Model_Collection/R/runtime.R")
run_domain("facts", 280)
# In the other process: run_domain("math", 140)
```

Credentials are loaded from a private temporary file, excluded from this repository. This command is not a public credential setup recipe. Do not launch duplicate collectors. Each domain maintains a lock, append-only attempt and HTTP-response logs, completed/skipped records and `runs/status.json`. Frozen hashes are checked before any request. Invalid initial/donor outputs make dependent branches unavailable; they are recorded, not replaced. HTTP failures, incomplete outputs and schema failures are distinct from explicit abstention. There are no automatic retries of failed or unknown requests and no retries to obtain a desired answer.

## Budget

**Current authorization:** after the budget stops, the user explicitly instructed “不用管预算全部收集完” (complete collection without the budget limit). [Amendment 02](protocol/budget_amendment_02.json) removes monetary stopping thresholds for the existing 2,332-task scope. Cost accounting and provider-error safeguards remain; prompts, questions, scoring and analyses are unchanged. Both domains resume their pending tasks with `run_domain("facts")` / `run_domain("math")`. The following amounts document the earlier authorization and stops, not current spending limits.

The existing additional authorization is **CNY 500**, not CNY 500 per agent. Prior guard expenditure is CNY 62.39277 and an unresolved historical request reserves CNY 2. New disjoint ceilings are CNY 280 for facts and CNY 140 for mathematics, leaving CNY 15.60723 unallocated. The ledger includes failures and now reserves CNY 10 before each new HTTP request. Collection stops at its ceiling or a provider/reservation fault.

An early protective stop occurred after a factual DeepSeek request made six autonomous searches and its conservative estimate reached CNY 2.47951, exceeding the original CNY 2 reservation. [Budget amendment 01](protocol/budget_amendment_01.json) raises only the per-request reservation to CNY 10; the overall budget, domain caps, prompts, tasks, scoring and analyses are unchanged. The original freeze and code are archived. The first 16 fact and 8 math responses are retained without retries, and collection resumes with pending tasks.

These are conservative token/search accounting estimates, **not supplier invoices**. The HKU gateway's cash price is unknown. Exact rates and limits are in [budget.json](protocol/budget.json).

## Interpretation

Report facts and mathematics separately and first average repetitions within each question, then questions within each model, then the two model means equally. Paired comparisons disclose coverage and cluster uncertainty by question. Errors include genuinely wrong answers; correct answers and explicit abstentions remain in the valid-response denominator. Incomplete/malformed/transport responses are separately reported, with missingness visible. Mathematical claims of impossibility or non-attainment are substantive answers, not automatically abstentions.

The target of 2,332 is a task count, not a claim of 2,332 valid answers or independent questions. Live progress is not a final result. No conclusion is selected in advance.
