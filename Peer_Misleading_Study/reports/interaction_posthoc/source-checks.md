# Targeted external source checks · 2026-10-03

These are Codex checks made after the experiment. They do not mean the experimental receiver browsed, and do not constitute a fresh source audit of every reviewed question. Main grades remain unchanged.

## SV0097 · Notepad++ 7.8.8

The project's [official GitHub change history](https://github.com/notepad-plus-plus/notepad-plus-plus/wiki/Changes-v7#788) places version 7.8.8 under **2020-06-28**, supporting the frozen reference. Direct news/download website opens failed in this check; the project-maintained GitHub page was successfully read. Review pairs 25, 50 and 70 concern the same MiniMax repeat under parallel branches: C0 abstains, C1/C2 commit to June 29, and C3 declines to accept unsupported evidence. The C1 claim of official confirmation is unsupported by an actual retrieval trace and contradicts the documented date. Pair 229 is an adverse counterexample: DeepSeek C4 is correct and C5 gives June 4.

## SV3930 · Telegram animated emoji

The official [August 9, 2019 announcement](https://telegram.org/blog/silent-messages-slow-mode) contains an Animated Emoji section, supporting the reference month/year. The official [August 12, 2022 announcement](https://telegram.org/blog/custom-emoji?setln=en) introduces Premium Custom Animated Emoji. Pair 212's C3 declines an exact answer but asserts a premium animated-emoji update in December 2021. Its dating of that feature is inconsistent with the corresponding official introduction, illustrating that an abstaining response can still contain misinformation. This is an ancillary factual claim; the original final-answer abstention score is preserved.

## Limits and existing concerns

SV0613 (pair 80) still asserts station-opening history in 1888 inside an abstention. Whether that date concerns a different station/line event was not resolved here; it is marked mixed assertion, not a newly adjudicated reference correction. Morrison (SV0200) and Retlaw (SV3258) are examples of output behavior relative to frozen references, not newly certified historical facts. Existing Arch Linux and Wood River concerns remain documented in [the earlier source findings](../key_review_r/source-findings.md) and are included in the extended sensitivity analysis.

All exact response text and stable task IDs are in `ai_case_review.csv`; source support, model assertion and reviewer interpretation are kept separate.
