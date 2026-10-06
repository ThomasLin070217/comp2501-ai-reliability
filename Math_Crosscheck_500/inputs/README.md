# Inputs: created only after upstream mathematics collection finishes

Do not create empty “completed” data or copy the old 41-question experiment into this index.

`baseline_index.csv`: 1,000 terminal initial-task records, with 500 question IDs for each model. Required columns:

| Field | Meaning |
|---|---|
| question_id | Exact upstream question ID; shared across both models. |
| question_text | Exact initial user question; shared across both models. |
| family_id | Original/base question identifier; use question_id when each base appears once. |
| model | `minimax` or `deepseek`. |
| initial_record_id | Unique selected upstream initial observation ID. |
| origin | `independent_initial`; no self/cross answers allowed. |
| status | `complete`, `technical_failure`, `incomplete`, or `unscorable`. |
| grade | `correct`, `incorrect`, `abstention`, `unscorable`, or `missing`. |
| answer_text | Complete original user-visible answer and explanation, unchanged. |
| settings_id | Hash/ID for actual initial model, system, decoding, token and tool settings. |
| conversation_path | Replay file path relative to repository root; complete original provider-valid request/history, with no credentials. |
| grade_evidence | Reference/decision provenance for grading, including mathematical-equivalence decisions. |

Scorable labels require `status=complete`, nonempty answer text/evidence and a replay file. Terminal unsuccessful records remain in the index so full coverage is audited, but are not eligible for a response-rate denominator. Preserve full raw source records and their hashes. The adapter must not fabricate replay history from a final-answer-only CSV.

The replay JSON contains `request_template` (actual non-message settings, including model and tool configuration) and `messages` (the original complete provider-valid initial conversation). Append one user follow-up to these messages for each separate branch. Copy the original provider protocol and native tool history; do not insert references/grades into the payload. The template must not contain credentials or secret headers.

`synthetic_materials.csv`: one row per initially correct MiniMax question selected for the controlled test. Fields: `question_id`, `wrong_answer`, `peer_text`, `error_type`, `why_wrong`, `review_status`, `reviewer`, `reviewed_at`. Approved rows have `review_status=approved`. Record failed/excluded materials too. The mathematical judgment is made by Codex from the question/reference/solution; R validates the presence and provenance of that judgment, not the proof itself. An approved ledger may cover fewer than all initially correct questions; disclose every omission. Freeze this ledger before any follow-up outcomes are viewed.

`preflight.json` and `prepared/` are generated local study outputs. A missing index means waiting, not completed collection. Preparers do not send API requests.
