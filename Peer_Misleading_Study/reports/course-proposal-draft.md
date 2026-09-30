# COMP2501 proposal draft

**Tentative presentation topic:** When AI Advice Misleads: Can Structured Double-Checking Protect Factual Answers?

**Data science questions**

1. When another AI gives a wrong date, does adding a plausible explanation increase the probability that an initially correct answer becomes incorrect?
2. Can structured checking reduce this harmful revision while preserving the ability to accept genuinely correct answers?

**Proposed project description (within 300 words)**

Double-checking with another AI seems useful, but fluent explanations may spread errors rather than correct them. We study this problem through controlled factual question answering, focusing on historical dates so that answers can be scored at an explicit precision.

Our public data source is SimpleQA Verified. We preserve a pinned snapshot, verify reference dates against accessible sources, exclude ambiguous questions, and separate development from formal evaluation. After material-quality screening, we retain 120 formal questions, with three receiving models and two repetitions per question.

Each model first answers independently. Six isolated review branches then receive either no advice, a wrong date, a wrong date with an AI-generated explanation, the identical wrong advice with a structured checking prompt, a correct target with an explanation, or the identical correct-target advice with structured checking. Peer material comes from a different model and is frozen before receiver evaluation. Wrong dates are selected deterministically, not optimized against receiver responses.

We measure accuracy, abstention, correct-to-incorrect transitions, and incorrect-to-correct transitions. Paired contrasts and question-cluster bootstrap intervals account for repeated observations. Complete prompts, responses, source decisions, exclusions, usage, and grading rules support offline reproduction.

Challenges include imperfect reference sources, unsupported peer explanations, selective abstention, and public-benchmark contamination. Findings will apply to this constrained setting, not identify a universally best AI model. The practical output is an evidence-based recommendation about when simple peer checking is insufficient and what additional verification should be tested next.

**Sources:** [SimpleQA Verified](https://arxiv.org/abs/2509.07968); [Towards Understanding Sycophancy in Language Models](https://arxiv.org/abs/2310.13548).

**Course alignment:** Original project PDF requests “One to two data science questions you are going to answer” and “A description of your proposed project (within 300 words)”. The PDF states proposal deadline Oct 3 at 23:59; confirm in Moodle before submission. This file is a draft, not a submitted assignment. Source: the user's `About the project.pdf`, pages describing proposal requirements.
