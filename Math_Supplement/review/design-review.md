### Prioritized Fixes

**1. FATAL — Call-quota arithmetic mismatch.**  
The plan consumes ~984–1,128 API calls (168 development receiver + 672 supplementary receiver + 144–288 donor material). The HKU quota is stated as **600 calls**. If that 600 is a cumulative hard cap, the study is impossible as written. Clarify immediately whether 600 is per-provider, per-day, or total. If total, prune to ≤600 calls or secure a quota increase before launch.

**2. HIGH — Semantic precheck has no rubric.**  
“One semantic precheck per material by Codex” is a single point of failure without documented criteria. Freeze a rubric before collection, e.g.: (a) assigned conclusion/value is present and not contradicted; (b) explanation is non-empty; (c) no claim of external tools/sources; (d) no overt rejection of the assigned error. Define how borderline cases are adjudicated.

**3. HIGH — “Maximum two attempts per material, retaining both” is ambiguous.**  
State explicitly whether this means *retry-on-failure* (keep the usable one, discard the other) or *A/B retention* (both enter the pool). If retry, specify selection hierarchy; if retention, specify randomization so receivers are not cherry-picked post-hoc.

**4. HIGH — Global “stop on output truncation” is too brittle.**  
A single truncated JSON should not abort the entire study. Amend to: log truncation, score that unit *unscorable*, and continue unless >10 % of a condition truncates, which signals a systemic token-limit issue requiring a protocol amendment.

**5. MEDIUM — Unverified provider pricing.**  
The CNY20/M input and CNY50/M output envelope assumes uniform pricing across DeepSeek/Kimi/MiniMax. Retrieve actual list prices per provider/model before reserving budget; DeepSeek and MiniMax rates can differ by >2×. Recompute the CNY60 envelope with real per-request costs at the 768-token cap.

**6. MEDIUM — Temperature 0.6 with n=1–2 repeats inflates sampling variance.**  
High temperature makes it harder to attribute C1–C5 shifts to peer pressure rather than sampling noise. Either lower to 0 for the frozen supplementary collection (noting the deviation from the factual study) or justify 0.6 as a deliberate robustness probe and accept wider variability.

**7. MEDIUM — JSON scoring edge cases undefined.**  
Clarify scorer behavior for: `value: 0` vs `null`; `solutions` containing floats instead of integers; conclusion-string typos (e.g., `insufficient information` vs `insufficient_information`); reason fields >80 words. Decide now whether strict parse fail = *unscorable* or whether a lenient normalizer is applied.

**8. LOW — No minimum-retention threshold for exclusions.**  
With only 16 supplementary items, losing one family to donor failure is a 25 % loss within that family. State a minimum viability rule (e.g., “proceed only if ≥12 of 16 items yield complete 7-response units; otherwise report as an incomplete replication”).

---

### Precise Preflight Acceptance Criteria

- [ ] **Quota confirmed in writing**: HKU or provider call limit is documented ≥ 1,200 total calls, or the design is pruned to fit the documented limit.
- [ ] **Price sheet verified**: Actual per-provider input/output token prices retrieved, entered into the budget sheet, and CNY60 envelope shown to cover the 95th-percentile token estimate including retries.
- [ ] **Donor precheck rubric frozen**: A committed markdown file lists exact Codex pass/fail criteria; any deviation during collection triggers a logged protocol amendment.
- [ ] **Donor attempt protocol explicit**: Committed protocol states whether Attempt 2 replaces Attempt 1 or both are retained, with a frozen randomization rule for assignment.
- [ ] **Truncation protocol amended**: Global halt removed; per-call exclusion rule committed, with systemic-abort threshold defined.
- [ ] **JSON schema + scorer committed**: Validator code/script is frozen, with explicit rules for nulls, typos, integer parsing, and tolerance application.
- [ ] **Dry-run completed**: End-to-end pipeline tested on the 8 development items (donor gen → precheck → receiver → score → parse) with all failures logged; no live collection until dry-run parses cleanly.
- [ ] **Credential hygiene checked**: `.gitignore` and any `renv`/`requirements` exclude API keys and raw private config; repo is clean.
- [ ] **Amendment template ready**: A version-controlled protocol-amendment template exists so any mid-collection fix is timestamped before implementation.

---

### Verdict

**Conditional No-Go.**  
The design correctly avoids over-claiming (no p-values, honest about repeats, clear abstention rules), but the **quota–call arithmetic (Fix 1)** is potentially fatal, the **precheck is underspecified (Fix 2)**, and the **~24-hour deadline leaves no margin for a dry run**. Do not launch live collection until the quota is confirmed sufficient and Fixes 2–4 are documented in the committed protocol. If the quota clears and all preflight criteria are met, downgrade to **Conditional Go** with strict monitoring of truncation rates and per-provider budget burn.
