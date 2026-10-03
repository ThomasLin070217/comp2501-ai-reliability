# Natural cross-check supplement (module A)

Status: protocol frozen on 2026-10-03, before new calls. User authorized execution after reviewing [architecture v2](../docs/experiment-architecture-v2.md). This is a post-hoc follow-up on previously studied questions, not a new held-out benchmark.

49 questions (36 facts, 13 mathematics), three receiving models, one repeat. Each model answers independently (N0); its own answer seeds independent self-check (N1), natural peer-check (N2), and structured natural peer-check (N3) branches. A peer is a different model's independent answer to the same question, with no assigned truth target. Primary contrast N2−N1. All scoring, analysis and plots use R. No search tools are given to tested models.

See [freeze](protocol/freeze.json), [input questions](protocol/questions.jsonl), [units](protocol/units.csv), [prompts](protocol/prompts.json), and [offline checks](protocol/offline-tests.json). Raw responses and skipped tasks will remain in `runs/`. Completed results will appear in `reports/`.

## Budget and collection

Additional paid API ceiling ¥30 (¥15 per paid provider), inside the existing ¥100 authorization; prior additional experiment/CLI estimate ¥15.433696, not an invoice. HKU price unknown and tokens recorded separately; its independent 202-attempt and token-envelope guards remain active. No more than six transport retries per provider (18 total). Output format failures are retained, not regenerated. Deadline for new requests: 22:57 Shanghai, 2026-10-03.

2026-10-03 pricing check: [DeepSeek official pricing](https://api-docs.deepseek.com/quick_start/pricing/) lists V4 Pro peak uncached input/output $1.32/$3.96 per million; using a budget conversion of ¥8/$ gives ceilings below the ¥20/¥50 guard. [Kimi official pricing](https://platform.kimi.com/docs/pricing/chat) lists K2.6 uncached input/output ¥6.50/¥27 per million (Markdown table inspected); the same ¥20/¥50 guard is conservative. These are guards, not verified bills.

Live collection requires environment credentials DEEPSEEK_API_KEY, KIMI_API_KEY, MINIMAX_API_KEY; no credentials or credential recovery paths are in this repository. Run each provider's baseline stage, then after all three completion receipts run branches:

```sh
Rscript Natural_Crosscheck/R/collect.R baseline deepseek
Rscript Natural_Crosscheck/R/collect.R branches deepseek
```

Repeat for kimi and minimax. Never start concurrent collectors for the same provider. An unresolved attempt stops resumption for investigation. Original B/C datasets and frozen scores are unchanged.
