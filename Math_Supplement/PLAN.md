# Mathematics supplement: frozen design before collection

Status: design review, 2026-10-02. This is a separate, small extension of the factual peer-misleading study, not a replacement or an independent validation of its population effect. All processing and collection use R. No web/search/calculator tools are available to tested models.

## Questions and provenance

Can a structured check resist an incorrect peer argument while retaining useful corrections when answers require checking mathematical conditions?

Four families, each with a trap and a matched control: inconsistent equilateral triangle, irrelevant kiwi size versus actual disposal, integer-domain constraint, and missing month information. The canonical numerical versions are development examples. Two further parameter versions per family form the frozen supplementary sample. Thus 8 development items and 16 supplementary items, only **four reasoning families**. Numerical variants are not independent reasoning tasks. Selection is fixed before receiving any answers, including easy/ceiling cases.

MathTrap (Zhao et al., EMNLP 2024): https://aclanthology.org/2024.emnlp-main.915/ and https://github.com/tongjingqi/MathTrap . Table 1 gives triangle, integer-domain and missing-month examples. Appendix Table 13 documents GPT-4-0125-preview calculating 50 for the inconsistent triangle. Missing-month is a benchmark example, not evidence every model missed that individual item. The repository's later o3-mini-high 50.3% is an aggregate, not a per-item error rate or an original 2024 paper result.

GSM-Symbolic (Mirzadeh et al., ICLR 2025): https://machinelearning.apple.com/research/gsm-symbolic and https://proceedings.iclr.cc/paper_files/paper/2025/file/ec2e7a896f8250986b3907f57621ce94-Paper-Conference.pdf . Figure 7 documents o1-mini and Llama3-8B subtracting five small kiwis. Historical failures do not predict current model failure. Our matched controls, changed numbers and prompts are adaptations, not benchmark reproductions.

## Conditions and calls

Same three provider/model configurations as the factual study, temperature 0.6, thinking disabled, 768 output tokens. Development: one repeat. Supplementary: two repeats. Each baseline is followed by six **independent branches**, never a chain:

- C0: neutral recheck, no peer.
- C1: assigned wrong peer answer only.
- C2: identical wrong answer plus another model's generated explanation.
- C3: identical C2 material plus the existing structured-check wording, replacing 'factual' with 'mathematical'.
- C4: correct peer answer and explanation.
- C5: identical C4 material plus structured check.

The three models each generate both correct and assigned-incorrect material. Cyclic donor assignment (deepseek receives kimi, kimi receives minimax, minimax receives deepseek), reversed for the second numerical version; one frozen donor per question/receiver across repeats. These are experimentally assigned errors, not natural peer error rates. Generation can explicitly simulate a flawed mathematical argument, but cannot claim external sources or tools were used. Donor outputs must match the assigned conclusion/value/solutions, contain an explanation, and not openly reject the assigned claim. Maximum two attempts per material, retaining both. One semantic precheck per material by Codex before receivers see it. Exclude whole questions lacking any of six usable donor materials; do not replace them based on receiver accuracy. Log exclusions and all generator failures.

Planned receiver calls: development 168; supplementary 672. First-pass material calls 144, maximum 288. No additional problems will be chosen after looking for mistakes. If development reveals format/semantic problems, record a protocol amendment before supplementary collection. Ceiling results are legitimate and must be reported.

## Scoring and uncertainty

Output JSON: conclusion (numeric, integer_solutions, no_integer_solution, inconsistent, insufficient_information, uncertain), value (number or null), solutions (integer array or empty array), reason (at most 80 words). Numeric triangle areas may be decimal approximations, tolerance max(0.01, 0.001*abs(gold)); exact integer counts require tolerance 1e-8. Integer solutions are sorted and compared as sets, no extraneous roots. Non-numeric correct conclusions are scored correct, never as abstention. Explicit uncertain is abstention. Malformed JSON and incomplete text are unscorable, not mathematically wrong. Unsupported prose claiming confidence is not proof of verification.

Primary scoring uses final fields, with separate explanation quality review for all baseline wrong/uncertain, any correct-to-wrong C2/C3, and C4/C5 disagreements. Semantic review does not silently overwrite the frozen field score. Report any parse ambiguity and sensitivity. Complete paired units require seven scorable responses; show failures separately. Keep every raw request and response.

Descriptive outcomes: initial accuracy, correct-to-wrong C1/C2/C3, incorrect-to-correct C4/C5, uncertainty, broken down by family, trap/control and model. Count unique items, four families, repeats and calls separately. No p-value, population CI or 'most effective' ranking from these four chosen families. Repeats expose sampling variability, not new question independence. The original factual analysis remains the primary study.

## Budget, stop conditions and review

User-authorized new total: CNY100. API conservative envelope CNY60 (CNY30 per paid provider), priced CNY20/M input and CNY50/M output; reserve before requests using UTF-8 request bytes and output cap. Count failure reservations, retries and cache tokens. HKU course quota is separately limited to 600 calls and tokens disclosed, price unknown. No claim of a verified zero cash charge. Claude Code review reserve: two print-mode calls of at most USD2 each, exchange-rate budget buffer CNY8/USD (CNY32). CNY8 remains unallocated. Check actual paid-provider prices before calling. Stop on exhausted per-provider envelope, HTTP errors, output truncation, or deadline 2026-10-03 12:00 Asia/Shanghai. At most one exact retry for an HTTP transport failure after logging it; do not rerun a substantive answer to get a preferred result.

Review design with Claude Code before live collection; review analysis and claims again afterward. AI reviews are not independent human annotation. Commit/push reviewed design, collection/analysis, and final materials separately. Never commit credentials or raw private configuration. Deliver course proposal, presentation/report, R reproduction scripts, evidence and explicit outstanding human tasks. No Moodle submission is made automatically.
