# Collection plan v2

Status: 1,000-task initial manifest and design hashes prepared offline. No model calls made in this review. This is a concrete collection specification; it is **not** a claim that the provider adapter, pricing or budget has already been certified for this new run.

## Phase 0 — freeze and certify

1. Use the reviewed v2 inputs/key. Validate `review_manifest.json` and `protocol/v2/plan_freeze.json` with `R/certify_plan.R`. The original bank is source evidence only. Check whether another chat already has a collection lock or matching initial run; reuse its matching records and never restart it. Different question hashes require explicit version reconciliation, not pooled results.
2. Proposed models are MiniMax-M3 on the local HKU Anthropic-compatible endpoint and deepseek-v4-pro on the locally configured DeepSeek Anthropic-compatible endpoint. These names are read from existing project configuration, not verified claims about current public products. Record returned model identifiers, endpoint, timestamps and resolved versions where exposed. Aliases may change; avoid treating the name alone as immutable.
3. Proposed common settings: temperature0.6, max output2048 tokens, non-thinking mode where supported, native web_search available, no added system instructions. Initial message is **only input_text**. Availability of tools and effective thinking settings must be verified in both current adapters; no silently asymmetric fallback. Both models decide whether to search. Follow-ups replay the exact initial settings and native history.
4. Adapt the existing R native-tool collector patterns, not a naive text-only request. Offline fixtures must cover normal text, server tool blocks, tool results, pause_turn, truncated output, transient5xx, unknown delivery and quota failure. Never synthesize a tool result or discard tool history to make replay work. Freeze actual live collector code/hash, supported tools, effective settings, retry policy and remaining expenditure/quota ceiling before paid requests. A necessary real-interface development check must fit applicable current authorization and be logged outside the primary question sample.
5. Exact new expenditure cap is not specified by the latest review/design request. Resolve it from current applicable authorization/configuration before calls; old unrelated unlimited-budget instructions do not establish this ceiling. Local historical conservative DeepSeek guards are20/50 CNY per million input/output tokens, **not verified prices**. HKU quota price is unknown. Track tokens, chargeable native search, cached tokens, estimates and invoices separately. Stop on quota/auth failure or projected cap breach. Candidate settings explicitly retain this unresolved gate.

## Phase 1 — one independent initial per cell

`protocol/v2/initial_tasks_1000.csv` has all500×2 cells, unique task IDs, random order within the two fixed stages (R seed25011011). Pair-adjacent scheduling balances temporal variation; each provider session remains entirely independent. No references, category labels, grades or peer output reach the API payload.

Stage A: first100 questions×2=200 initials. The fixed 40/30/30 mix is an operational checkpoint for completion, native-tool replay, latency and quota, **not** a sample selected for finding a result. Retain these records. Stage B: remaining400×2=800 initials (160 distraction,120 missing-information,120 understanding). Do not replace questions based on Stage A accuracy. If protocol changes are necessary, freeze an amendment and identify affected data; do not silently mix settings.

Concurrency cap4 total and2 per provider. Fresh conversation, one question, one logical final answer. Record each request *before* dispatch and durably save the raw response before parsing. Checkpoints and exclusive task locks prevent duplicate calls after interruptions. Never read/store keys in public manifests; authentication comes from existing private configuration and is redacted from saved request headers.

Known transient transport/5xx errors allow at most one retry with identical payload. Read timeouts after possible delivery are `unknown_delivery`; reconcile rather than automatically sending a second independent answer. Completed wrong answers, explicit abstentions and unexpected prose do not trigger retries. A provider pause_turn can continue the **same** assistant turn, with native blocks intact, bounded at3 continuations. A client tool requirement needs the actual approved tool adapter; unresolved tool execution is technical missing. Output cut by token limit is incomplete. Neither truncation nor an unfinished search turn is an initial final answer. Do not raise max_tokens inside the primary collection because a question was difficult; any technical recovery with changed settings belongs to a separately frozen appendix.

## Phase 2 — score and freeze baselines

All1,000 tasks must have terminal statuses, including declared unrecoverable technical failures. Save full raw requests/responses and model-visible replay JSON, effective parameters, hashes, finish/stop reason, tool history, token usage and cost. Score in R against the reviewed key with semantic adjudication. Keep original text, extraction and grading evidence. Correct missing-information conclusions are correct, not abstention.

Export `inputs/baseline_index.csv` according to `inputs/README.md`. Its question text must match v2 byte-for-byte; preserve `family_id`, provider, independent origin, unique observation ID, settings ID, grade and complete conversation path. `R/preflight.R` blocks mismatches/unfinished coverage. No first100 follow-ups while the other800 initials are still being collected.

## Phase 3 — freeze all follow-up stimuli and tasks

Select candidates **only** by frozen initial outcomes. Prepare all synthetic wrong explanations for correct MiniMax initials; one approved material per question, with original key, wrong target, identifiable error, why wrong, review provenance and hash. A missing-information item's synthetic number must rest on a documented unjustified assumption. If valid wrong material cannot be produced, record exclusion.

Before any follow-up results are viewed, freeze stimuli, tasks, eligibility, prompts, initial replay references, parameters, live collector and spending guard. `R/prepare.R` prepares manifests from the baseline index; it does not dispatch requests. Independent task branches copy the same MiniMax initial. DeepSeek's actual visible text is used unchanged in natural cross-check; hidden reasoning is not manufactured. Run randomized question/branch order, seed25011010, one outcome per eligible condition.

## Phase 4 — score, analyze and synchronize

Use R for all extraction, scoring, transitions, missingness, category summaries, paired intervals and figures. Primary results are natural overall net benefit, conditional correction/elimination and controlled correct→wrong risk, each with its denominator. Keep natural wrong-peer risk separate from simulated advice risk. Publish explicit limits: selected short GSM-Plus items, substantial missing-information proportion, AI-assisted review, source familiarity and finite samples. Preserve raw data and versioned grades. Commit and push only this study's files; never stage PPT/Excel/Word or the factual collector from other chats.

## Record contract

| File/record | Required content |
|---|---|
| Run manifest | Edition and input/key/code hashes, model/settings versions, seeds, start/end time, tools, retry/continuation limits, authorized guard. |
| Attempt log | Task/attempt/request IDs, payload hash, dispatch time, status/HTTP error, finish reason, raw file hash, selected attempt or unknown delivery. |
| Replay JSON | Authentication-free request_template and complete provider-valid user/assistant/tool messages. Initial has exactly one user question. |
| Usage/cost | Provider input/output/cache/tool counts, estimated charges, guard basis, invoice charges if available, quota state. |
| Score CSV | Task ID, observed final answer, correct/incorrect/abstention/unscorable/missing, reason, reviewer/time, key hash, original and adjudicated grades. |
| Baseline index | Existing schema plus binding to run manifest and the reviewed bank; all500 cells per model terminal. |
| Synthetic ledger | Question ID, full wrong answer/reasoning, target, error type, why wrong, reviewed/approved status, reviewer/date, frozen hash. |

Offline commands are in `question_review_v2/README.md`. Neither the design freeze nor passing preflight authorizes changing a separate running collection or inventing an expenditure limit.
