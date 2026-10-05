# Two-model mathematics collection

**Execution update (2026-10-05):** after the original allocation stopped collection at 321 records, the user explicitly instructed “不用管预算全部收集完”. Global `protocol/budget_amendment_02.json` removes budget stopping while retaining cost accounting and provider/authentication protections. The original 732-task scope, frozen prompts, scoring and no-answer-dependent-retry rule remain unchanged. The earlier budget-stopped report is preserved under `archive/budget_stop_321/`; its partial counts are historical, not the final current totals.

This directory owns the mathematics arm of the newly authorised two-agent collection. The protocol is frozen before calls. It contains **41 CHAMP questions**, MiniMax and DeepSeek, **two independent repetitions**, and **732 planned final responses**. Data handling is entirely in R.

The natural core has 492 responses: 41 × 2 models × 2 repetitions × (neutral initial, self-check, A0-AI). A mechanism subset of 15 questions, selected at seed 25011005 with 3 questions per CHAMP family, adds 240 responses: misconception initial, A0-Human, A1-AI, A1-Human. The selection is independent of newly observed performance and is not modified after collection starts.

The collection order completes neutral initials and natural self/cross-check branches before the mechanism arm. Each parallel revision branch copies the same recipient neutral conversation and native search history. Donor material comes from the opposite model on the same question and repetition. AI/Human suggestions differ only in their introduction; all actual answer, abstention and reason content is unchanged. A misconception-conditioned donor may correct the premise or abstain and is retained.

Tool availability is configured by the shared collector. No model-facing prompt commands searching, no search is forced and no researcher evidence is supplied. Native tool use and technical failures are logged separately from the final answers. The math arm's guard is **CNY 140**, including failures and unresolved request reservations; it cannot borrow the fact arm's allocation without the coordinator explicitly reallocating inside the existing total cap.

## Frozen inputs

- `protocol/prompts.json`: exact reviewed model-facing prompts and templates.
- `protocol/tasks.csv`: dependency graph and planned ordering.
- `protocol/mechanism_subset.csv`: fixed mechanism sample.
- `protocol/researcher_reference.json`: researcher-only reference keys and proofs; never supplied to models.
- `protocol/SCORING.md` and `R/scoring.R`: numeric and semantic scoring, conflict handling and separate sensitivity review.
- `protocol/freeze.json`: pre-collection hashes.

Run `Rscript Two_Model_Collection/math/R/check.R` for offline checks. Do not rebuild or overwrite frozen protocol files once calls have started. The shared collector and cost guard are managed at `Two_Model_Collection/`; this directory never invokes the historical three-model collector. Final acquired count, coverage, costs and conclusions will be reported from actual records, not planned totals.
