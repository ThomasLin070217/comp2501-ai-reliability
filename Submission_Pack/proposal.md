# 1. Tentative topic

Can We Trust AI More After Cross-Checking?

# 2. Data science questions

1. How much does a different model's independent answer change error rates relative to direct answering and self-checking, on factual and mathematical questions?
2. Can mistaken peer advice mislead a model, and does structured verification reduce wrong answers without sacrificing useful corrections?

# 3. Project description

A classroom discussion about trusting AI motivated this project: does checking one model's answer with another justify greater confidence? A second model may correct mistakes, but it may also transmit its own errors. We study this trade-off without web search or external tools.

Our natural cross-checking supplement uses 36 factual questions and 13 mathematical items with three model APIs. Each model answers independently, then branches into self-checking, checking with another model's natural answer, and structured peer-checking. Comparing peer-checking with self-checking separates peer information from simply answering again. This is a post-hoc follow-up on previously studied questions.

Our larger controlled experiment uses 120 factual date questions from SimpleQA Verified, three models and two repeats. Parallel branches receive neutral prompts, assigned wrong advice, or correct advice, with and without explanations and structured verification. A small mathematics supplement draws on MathTrap and GSM-Symbolic problem families.

All data processing uses R. We report wrong answers, correct answers and explicit abstentions separately, paired changes and question-cluster bootstrap intervals for factual tasks. Abstention does not count as an error. Challenges include ambiguous references, correlated responses, output-format failures and limited mathematical diversity. Research on self-correction and Chain-of-Verification informs the design. We retain raw records and limitations, aiming to propose a cautious checking workflow rather than guarantee correctness or measure human trust directly.
