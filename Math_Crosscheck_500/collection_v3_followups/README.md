# GSM-Plus v3 follow-up branches

This collection replays each of the 496 scoreable MiniMax-M3 initials that has a scoreable independent DeepSeek v3 initial. It creates two **parallel** user follow-ups from the same original MiniMax conversation: a neutral self-check and a natural cross-check containing DeepSeek's actual independent visible reply. It does not run them in sequence. The original question and full native assistant content, including server-side search blocks where present, are retained; the answer key and grades never enter a prompt.

The exact suffix and peer wrapper come from `../protocol/prompts.json`. The R preparer saves 496 immutable replay transcripts, 992 immutable request payloads, a source-hashed baseline index, transport configuration and randomized branch schedule under `protocol/`. The R collector uses the existing native MiniMax worker, logs complete request and response JSON per HTTP attempt, stops on 401/402/403/429 or unknown delivery, and never retries based on correctness. The 1,100-request guard is a technical reservation ceiling, **not** a monetary estimate or guarantee of course quota.

This v3 protocol deliberately stages the controlled wrong-peer experiment separately from self/natural collection. Before any follow-up text was examined, `R/select_controlled_targets.R` fixed a 50-question initially-correct MiniMax subset (20 distraction, 15 problem-understanding, 15 restored-source). Its wrong answers and explanations still require independent checking and freezing before that branch can run. The scripted false **first** human prompt is a further separate experiment; neither can be inferred from the natural cross-check.

The first two scheduled branches passed a real interface pilot: one self-check and one natural cross-check, both `MiniMax-M3` HTTP 200 `end_turn`. Only technical status was inspected before the 50-ID controlled selection was frozen. This pilot belongs to the predeclared full sample, not a replacement set.

From the repository root:

```sh
Rscript Math_Crosscheck_500/collection_v3_followups/R/collect.R --preflight
Rscript Math_Crosscheck_500/collection_v3_followups/R/collect.R --pilot 2
Rscript Math_Crosscheck_500/collection_v3_followups/R/collect.R
```

Receiving 992 answers will not itself establish a double-check benefit; final responses must be graded in R on the common paired set, with correct→wrong transitions and technical gaps audited against the raw files.
