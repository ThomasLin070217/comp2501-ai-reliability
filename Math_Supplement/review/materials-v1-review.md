# Development material review, version 1

Codex AI inspected all 49 original donor responses before any receiver call. Decision: reject this generation pass as a set and revise uniformly, preserving every original response. No original result was hidden or used in receiver analysis.

Examples of failed rubric items:

- M-triangle-0-control deepseek/kimi wrong a0: derives 25*sqrt(3), approximately 43.3, then asserts 50; explicitly reveals the correct result rather than one coherent flawed route.
- M-integer-0-control minimax wrong a0: final field says no integer solutions while reason proves roots 1 and -2.
- M-integer-0-trap kimi wrong a0: explicitly says the roots are noninteger and proposes changing the question.
- M-integer-0-trap minimax correct a0: correct conclusion but false claim that negative integers make x^2+x smaller, overlooking arbitrarily large negative inputs.
- M-month-0-trap minimax wrong a0: no reason; a1 is the retained raw format retry, not a second independent suggestion.

Some v1 suggestions are usable, but using only successful families would narrow the supplement according to generation artifacts. The uniform v2 development amendment supplies a researcher-specified reasoning route. It changes material construction transparently, without changing receiver prompts or choosing problems according to receiver mistakes.
