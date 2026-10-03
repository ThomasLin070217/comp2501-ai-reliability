# Reviewer API configuration correction

The first three masked-review requests received HTTP 400 and returned no reviewer judgments. The implementation incorrectly requested temperature 0 with Kimi K2.6 in non-thinking mode. The [official model documentation](https://platform.moonshot.cn/docs/guide/kimi-k2-6-quickstart) specifies temperature 0.6 in that mode and says other values are rejected.

Before any actual reviewer judgment, preserve the rejected requests and receipts under `review/configuration_error/`, change only the reviewer temperature to 0.6, and run all 41 planned review jobs for their first actual assessment. Their problem sets, anonymized order, prompts, references and output limits are unchanged. The original review implementation remains unchanged and hashed. A wrapper retains the rejected-attempt cost reservations within the original total CNY8 review guard.

This is a disclosed configuration repair after experimental outcome aggregates were available, not a re-sampling of unfavorable judgments. No experimental model response, primary grade, question selection or experimental prompt is changed. Completed or malformed substantive reviewer judgments still are not retried to obtain better labels.
