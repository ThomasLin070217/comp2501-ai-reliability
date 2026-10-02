# 1. Tentative topic

Can Structured Double-Checking Resist Misleading AI Peers?

# 2. Data science questions

1. When an AI peer gives a wrong answer, does adding an explanation increase the probability that a model changes an initially correct answer to a wrong one?
2. Does a structured verification prompt reduce this harm while preserving the ability to learn from correct peer advice?

# 3. Project description

People increasingly ask one AI assistant to check another, but an additional explanation may introduce errors as well as corrections. This project measures that trade-off under controlled conditions without web search or external tools.

We collected responses from three model APIs on 120 factual date questions selected from the public SimpleQA Verified dataset. Each model answered twice. From each initial answer, we created six independent follow-up branches: neutral rechecking, a wrong peer answer, that answer with an explanation, the same explanation with structured verification, correct peer advice, and the same correct advice with structured verification. We retain raw prompts, responses, failures and costs. A separate small mathematics supplement uses published trap-problem families to examine inconsistent conditions, irrelevant information and logical constraints.

The main challenges are ambiguous reference answers, distinguishing uncertainty from factual errors, correlated repeated responses, and separating deliberate experimental misinformation from natural model mistakes. All data processing uses R. We analyse correct-to-wrong changes, successful corrections, accuracy and abstention, with question-level cluster bootstrap intervals for the factual study. Existing work on self-correction, Chain-of-Verification, MathTrap and GSM-Symbolic informs the design. Our goal is to identify the limits of this specific checking prompt and propose evidence-based improvements, rather than claim one universally best method.
