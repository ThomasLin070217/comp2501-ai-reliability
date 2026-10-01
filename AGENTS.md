# Project context entry point

Read the full, current `CHAT_CONTEXT.md` before each user-facing answer; follow higher-priority instructions for message ordering. If you update it during a turn, read it again before the final answer.

The direct user source for this requirement is CHAT_CONTEXT U05. The user also requested preserving original wording to avoid information loss (U06). These labels identify verbatim quotations in the context file, not platform message IDs.

Keep explicit user instructions, exploratory questions, assistant implementation choices, draft plans, and recorded results distinct. Prefer exact quotations with source locations; label paraphrases and omissions. Do not upgrade an assistant proposal into a user decision or make a quotation out of a summary.

U10 explicitly authorizes web collection, implementation, and live experiments during the current eight-hour work window, superseding A01. Follow the existing staged design; record development findings and freeze the formal sample, prompts, grading, and budget before formal collection. Do not ask for repeated permission for authorized steps. Record any necessary deviations and actual costs.

Preserve original results and keep credentials out of the public repository.

The user requires all data processing in R (CHAT_CONTEXT U13). Use `Peer_Misleading_Study/reproduce_main.R` and the R modules for current cleaning, scoring, statistics, bootstrap, sensitivity analysis, plotting, and report exports. Do not wrap Python processing in R. Preserve frozen collection records and historical code; do not relabel the original collection as having been performed in R. Current R outputs are in `reports/main_r/` and historical Python outputs remain in `reports/main/` for audit.
