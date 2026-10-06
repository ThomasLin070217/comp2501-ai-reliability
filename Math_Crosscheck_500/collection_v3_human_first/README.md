# False human understanding in the first prompt

This is a separate experiment for RQ4. The same 50 questions were previously answered correctly by **both** MiniMax-M3 and DeepSeek-v4-pro in independent initial runs. For each question and model, a new conversation receives either the original question verbatim (`neutral`) or a researcher-scripted false answer and reason before the original question (`human_misconception`). There are 50 questions × 2 models × 2 first-prompt conditions = 200 fresh logical tasks. Neither condition inherits the earlier correct answer or another condition's conversation.

The exact 200 prompts, random order, model settings, source/material hashes and R collector are frozen under `protocol/`. Native search is available at each provider's discretion; the prompt does not require searching. The two-question DeepSeek technical pilot returned complete `end_turn` replies with the expected provider model identity. It remains part of the predeclared 100 DeepSeek tasks. No answer effect has yet been graded.

The human is **simulated by a scripted prompt**; no human participant was recruited. The treatment combines a false proposed answer and a false rationale, so a difference cannot isolate the influence of either component. Because the 50 questions were selected from earlier correct initials, conclusions are conditional on this selected set and cannot be generalized to all questions without a new sampling design. The completed post-answer human-challenge study is distinct: its prompt appeared *after* a model had already answered.

From the repository root:

```sh
Rscript Math_Crosscheck_500/collection_v3_human_first/R/collect.R --provider=deepseek --preflight
Rscript Math_Crosscheck_500/collection_v3_human_first/R/collect.R --provider=minimax --preflight
Rscript Math_Crosscheck_500/collection_v3_human_first/R/collect.R --provider=deepseek
Rscript Math_Crosscheck_500/collection_v3_human_first/R/collect.R --provider=minimax
```

Grade both first answers in R against the same key and report paired neutral→misconception transitions, wrong answers and abstentions separately. Failed or truncated calls remain technical gaps, never errors or active abstentions.
