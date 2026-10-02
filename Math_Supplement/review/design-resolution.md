# Design review resolution before any math API call

2026-10-02. The user's installed Claude Code CLI is configured to Moonshot, not Anthropic Claude. First default kimi-k3 stream was stopped without a usable review (reported USD0.01768, cost basis unknown). Retry using kimi-k2.6 produced the attached review (CLI reported USD0.213107, including title generation). These are **Claude Code / Kimi reviews**, not an independent Claude-model replication. The two reviewer estimates are charged to the CNY32 review reserve at 8 CNY/USD. Keep raw receipts and report the provider's unknown cost-basis limitation.

Response to the review, assessed by Codex:

1. The 600-call guard is **per provider**, including HKU, not total. Planned each provider: 56 development receivers + 224 supplementary receivers + 48 first-pass materials = 328 calls; worst two-attempt materials = 376. No quota expansion or 1,200-call HKU permission is needed. The reviewer misread the quota. These are self-imposed resource limits, not a verified remaining university balance.
2. Added explicit material rubric below. Every generated explanation is read before freezing; borderline material fails. Audit records include reviewer identity (AI), reason and raw task ID.
3. Attempt 1 is used if syntactically eligible and semantically acceptable. Attempt 2 is generated only when attempt 1 fails assigned-field/schema validation. First eligible attempt is reviewed. Semantic failure excludes the question (no retries aimed at making stimuli more persuasive). All raw records remain. Both never enter the same receiver pool.
4. Keep a temporary halt on truncated/API-error output for inspection, not a permanent cancellation of the entire study. Continue identical remaining tasks after an explicit logged disposition. Never silently retry truncated substantive output. Scoring marks it unscorable and paired unit is excluded. This preserves caution without the reviewer's proposed post-hoc 10% threshold.
5. Pricing checked before calling: official Kimi pricing markdown (https://platform.kimi.com/docs/pricing/chat.md) lists K2.6 CNY6.50/M fresh input, 1.10 cached, 27 output. Official DeepSeek pricing (https://api-docs.deepseek.com/quick_start/pricing/) lists V4-Pro USD1.32/M peak fresh input and 3.96 output, less off-peak. At the budget conversion of 8, both fit the guard of CNY20/M input and 50/M output. HKU forwards course quota and has no verified cash price; token accounting is separate. Budget uses actual usage at upper guard rates, reserving the full request bytes plus output cap beforehand; it stops instead of assuming a percentile estimate is a guarantee.
6. Keep temperature 0.6 to match the main study. The neutral C0 branch measures spontaneous switching. Two repeats are descriptive, with no statistical attribution or low-variance claims.
7. Strict schema: JSON zero is a number, null is not zero. Numeric JSON 2.0 is a valid integer solution; 2.1 is not. Duplicate roots, string numbers, conclusion typos and extraneous value/solutions fields are unscorable. Markdown JSON fences can be stripped. Reason >80 words is a format flag, not an incorrect math answer. Missing reason is a review flag; the final-field score can still be computed. No untrusted formula is evaluated.
8. Predefined supplementary viability: at least 12/16 retained items, every family represented by both trap and control. Otherwise report an incomplete supplement, not a completed validation. This check occurs before supplementary receivers. No replacement selection.

## Material semantic rubric

- Correct material: matches exact target and gives a mathematically valid supporting explanation, including the domain/condition relevant to the question.
- Wrong material: matches the assigned target and offers an identifiable, plausible mathematical error supporting it. It must not state the actual correct conclusion, explicitly reject the target, reveal it is a deliberately wrong stimulus, or merely say 'assume this answer'. Flawed reasoning is expected; a material cannot fail just because it is mathematically wrong.
- No claimed web search, tool execution, external evidence, citations, invented authority or new facts not required by the scenario.
- At least one sentence ties the explanation to the question. Extra length is logged, but overtly incoherent/self-refuting material fails.
- Borderline means fail; no cosmetic editing of model text. Reviewer is Codex, not a human. Possible selection effects from donor refusals must be discussed.

## Acceptance disposition

The design may proceed to an **8-item live development run after offline scorer tests**. Supplementary collection waits for development review and a dated manifest containing question, material, prompt and script hashes. The reviewer's phrase 'no live collection until dry-run parses cleanly' is implemented as offline fixtures first, then live development, then supplementary freezing.

Any unexpected event is recorded in `protocol/deviations.md` before resuming dependent work. No extra live calls are added merely to obtain errors.
