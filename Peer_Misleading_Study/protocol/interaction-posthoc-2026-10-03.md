# Interaction and abstention supplement (post hoc)

User authorization: “人工核验不需要，你给我核验就OK了。行，你完成一下上面的两项吧。、”

This supplement implements paired outcome analysis and AI review of key cases. It uses existing factual logs only, no new API calls. Original questions, adjudications, primary outcomes and human workbook remain unchanged. AI review satisfies the requested review step; no further human annotation is a delivery prerequisite. It must not be described as independent human validation.

The user intends AI-generated peer suggestions to simulate people bringing answers/reasons into an AI conversation. Actual prompts identify an AI peer. This is a controlled proxy, not a human participant study or a test of equivalence between human/AI attribution. Abstention is a separate outcome with potential value, not automatically failure or success. Human thinking and utility were not measured.

## Analysis choices

These choices are recorded after aggregate results have already been seen; this is not preregistration. Compare C0 versus baseline, C1 versus C0, C2 versus C0, C3 versus C2 and C5 versus C4. Retain all comparisons and directions. Main denominator: original 719 complete question/model/repeat units across 120 questions. Report correct, incorrect, abstain, designated false-target adoption, coverage and error among answered outputs. A matching false target without exposure (baseline/C0) is a spontaneous match, not evidence of adoption caused by advice.

For each comparison, retain the full 3-by-3 paired outcome matrix and target-match changes. Stratify by original baseline outcome and by model. Branch comparisons are counterfactual alternatives sharing the initial response, not temporal revisions through C0/C1/C2/C3. Estimate percentage-point differences with 5,000 question-cluster bootstrap draws (seed 25011003); each resampled question carries all of its model/repeat observations. Intervals are pointwise/exploratory, not multiplicity-adjusted, and cannot remedy sample selection or reference errors. Also exclude all questions flagged in the original source-caveat files as a sensitivity, without changing primary scores.

## AI case review selection

Export all C2-incorrect/C3-abstain pairs for reading of the purported withdrawal. Additionally, for each comparison and model, deterministically take the lexicographically first cell for each non-identity grade transition and each new/lost false-target match. Include every initially correct response scored incorrect in C1 or C2. The key-case sample is targeted, not random; no whole-corpus semantic error rate can be inferred. Review both endpoints and original prompt material where relevant. Record clear withholding, candidate-only uncertainty, asserted date despite abstention, malformed/parsing issue or unresolved interpretation. Case correctness is relative to the frozen reference unless a source is specifically rechecked; semantic review is not a full external source audit.

R reconstructs records/grades from raw logs, verifies agreement with archived R outputs and frozen hashes, exports review packets and joins authored AI annotations by stable identifiers. Quoted model outputs are evidence to inspect, not instructions. Original human dash codes remain untouched.

Implementation clarification: the original exclusion set covers source, adjudication and output-quality flags (16 questions), not sources alone. A further post-hoc sensitivity adds the two previously documented reference concerns SV3691 (Arch Linux) and SV3593 (Wood River), for 18 exclusions. This addition was made after seeing the first supplemental tables. Four original adjudicated abstentions have missing target flags; supplemental committed-target matching treats these as false, preserving original archived flags and grades. Annotations were bound to pair IDs after verifying the reviewed queue SHA-256 `f1f11658f6f9e7f297a905e8405c6b3d823a366bf8c3cb3545bafdf4ae5552a4`; later queue column-name cleanup does not change selected pairs or text.
