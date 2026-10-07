# Protocol files

- `fact_initial_user_prompt_template.txt`: the initial fact-question message (`{question_text}` placeholder).
- `gsmplus_v3_followup_prompt_spec.json`: exact neutral follow-up suffix and actual-donor cross-check wrapper. Self-check and cross-check are parallel branches from the same original MiniMax conversation; the answer key is not sent to the model.
- `gsmplus_v3_first_prompt_tasks_200.csv`: 50 shared questions × two models × neutral/false-premise first prompts. Each row contains the exact model-facing prompt text.
- `gsmplus_v3_scripted_wrong_peer_materials_50.csv`: the 50 researcher-written false peer suggestions used in the controlled wrong-AI-advice test. They are not real DeepSeek outputs.
- `revised_math_m3_wrong_advice_public.csv`, `revised_math_ai_extension_wrong_advice_public.csv`: public-source scripted AI-answer/reason materials. Local exam/workbook items have been filtered out.
- `revised_math_induction_prompt_templates.md`: exact prompt templates for revised-math self-check and scripted AI/user induction.

Raw HTTP request/response envelopes and transport configuration are not included because the public response tables preserve the answer text and scoring metadata without potentially exposing transport headers or local credential paths.
