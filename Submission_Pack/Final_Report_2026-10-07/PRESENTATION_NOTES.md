# Presentation notes for LINYUNIAN and PAN ZHENGYU

Use slides 1–24 for the 18-minute talk. Keep slides 25–30 as the data appendix for the two-minute Q&A. The split below is a suggested rehearsal plan; either presenter can adjust it.

| Time | Presenter | Slides | Point to make |
| --- | --- | --- | --- |
| 0:00–3:00 | LINYUNIAN | 1–8 | The question began with whether cross-checking justifies stronger trust in an AI answer. Four research questions separate benefits from new-error risks. |
| 3:00–6:00 | LINYUNIAN | 9–13 | Explain the three separate cohorts, paired branches, and error definition. An explicit abstention is nonwrong; technical gaps are excluded. |
| 6:00–9:00 | LINYUNIAN | 14–16 | In the private revised math bank, self-review changed 66/488 wrong to 42/488, but also introduced eight new errors. The scripted AI-versus-user contrast is a different test. |
| 9:00–13:00 | PAN ZHENGYU | 17–19 | On GSM-Plus v3, initial/self/natural-cross errors were 17/495, 9/495 and 4/495. The wrong-peer test had 0/50 adoptions; the fresh false-user-premise test had DeepSeek 0→3/50 and MiniMax 1→5/50 wrong. |
| 13:00–17:00 | PAN ZHENGYU | 20–24 | Use the illustrative omitted-case example, then state the bounded answers to RQ1–RQ4 and cite related work. Keep the caveat that cross versus self has an interval reaching zero. |
| 17:00–18:00 | Both | 24 | Leave a minute to state the practical conclusion and prepare for questions. |

Suggested Q&A wording:

- **Does cross-checking work?** In our matched samples, both self-review and natural cross-check reduced observed wrong answers relative to the same initial answers. They also created some new errors, so neither is a guarantee.
- **Was cross-check better than self-check?** Its observed GSM-Plus v3 rate was lower, 4/495 versus 9/495, but the paired 95% interval for the difference reached zero. We cannot establish a stable advantage from this sample.
- **Did a wrong AI peer mislead the model?** The new controlled 50-question scripted-peer test had zero false-target adoptions. An earlier natural case did show a correct answer changing to a wrong peer answer. One new natural v3 case is ambiguous, so we do not use it as a clean induced-error count.
- **Did the false human premise cause more errors?** The first-prompt test produced concrete correct-to-wrong cases, including four for MiniMax. The questions were selected because both models had earlier answered correctly; MiniMax's exact paired p-value is 0.125. We claim possibility on these prompts, not a stable population-wide increase.
- **Why count “I don't know” as nonwrong?** It avoids penalizing a model for declining to invent an answer. We report abstentions separately because a lower error rate can come with less useful coverage.
- **Are the private AI/user branch results an identity effect?** No. The source framing and prompt wording differ, so the contrast cannot isolate the effect of claiming the feedback came from a person rather than AI. Both messages were researcher-written.

Keep all denominators attached to their cohorts. Do not combine the fact study, GSM-Plus v3 and private revised math bank into one error rate. The report PDF contains the source-linked result and audit limits.
