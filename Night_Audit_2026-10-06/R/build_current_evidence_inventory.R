#!/usr/bin/env Rscript

# R-only inventory of currently usable study cells; never pools versions/domains.
suppressPackageStartupMessages({library(digest); library(jsonlite)})
root <- 'Night_Audit_2026-10-06/derived'
fact_original <- file.path(root, 'fact_direct_supplement_resumed_summary.csv')
fact_later <- file.path(root, 'fact_last_four/source_separated_counts.csv')
math_pairs <- 'Math_Crosscheck_500/collection_v3_followups/analysis/paired_common_scorable.csv'
human_pairs <- 'Math_Crosscheck_500/collection_v3_human_first/derived/deepseek_first_prompt_pairs_50.csv'
human_minimax_pairs <- 'Math_Crosscheck_500/collection_v3_human_first/derived/minimax_first_prompt_pairs_50.csv'
controlled <- 'Math_Crosscheck_500/collection_v3_controlled/derived/controlled_scores_50.csv'
f0 <- read.csv(fact_original, stringsAsFactors = FALSE)
f1 <- read.csv(fact_later, stringsAsFactors = FALSE)
m <- read.csv(math_pairs, stringsAsFactors = FALSE)
h <- read.csv(human_pairs, stringsAsFactors = FALSE)
hm <- read.csv(human_minimax_pairs, stringsAsFactors = FALSE)
c50 <- read.csv(controlled, stringsAsFactors = FALSE)
stopifnot(nrow(m) == 495L, !anyDuplicated(m$eval_id),
          nrow(h) == 50L, !anyDuplicated(h$eval_id),
          nrow(hm) == 50L, !anyDuplicated(hm$eval_id),
          nrow(c50) == 50L, !anyDuplicated(c50$eval_id),
          all(c('correct','incorrect','abstain') %in% names(f0)),
          all(c('correct','incorrect','abstain','scoreable') %in% names(f1)))
row <- function(version, domain, model, condition, questions, paired_n,
                planned, correct, incorrect, abstain, technical, unscorable,
                provenance) {
  scoreable <- correct + incorrect + abstain
  stopifnot(scoreable + technical + unscorable == planned,
            all(c(correct,incorrect,abstain,technical,unscorable) >= 0))
  data.frame(version, domain, model, condition,
             unique_questions = questions, common_paired_questions = paired_n,
             planned_cells = planned, scoreable_cells = scoreable,
             correct, incorrect, explicit_abstain = abstain,
             technical_incomplete = technical, unscorable,
             wrong_answer_rate = incorrect / scoreable,
             provenance, stringsAsFactors = FALSE)
}
rows <- list()
for (i in seq_len(nrow(f0))) {
  z <- f0[i, ]
  rows[[length(rows)+1L]] <- row('fact_frozen_470_mixed_route', 'fact',
    z$provider, 'initial', 500L, NA_integer_, 500L,
    z$correct, z$incorrect, z$abstain,
    z$technical_incomplete, z$unscorable,
    'Frozen original-gateway plus official-endpoint overlay; later HKU rescues separate')
}
for (i in seq_len(nrow(f1))) {
  z <- f1[i, ]
  rows[[length(rows)+1L]] <- row(
    paste0('fact_', z$version), 'fact', z$provider, 'initial',
    500L, NA_integer_, 500L, z$correct, z$incorrect,
    z$abstain, z$technical_incomplete, z$unscorable,
    if (z$version == 'supplemented_500')
      'Four later MiniMax rescues; three disabled search, one also shortened answer'
    else 'HKU-route later view with four MiniMax technical gaps')
}
for (condition in c('initial_grade','self_grade','natural_grade')) {
  g <- m[[condition]]
  stopifnot(all(g %in% c('correct','incorrect','abstention')))
  rows[[length(rows)+1L]] <- row('gsmplus_v3_common', 'math', 'MiniMax',
    switch(condition, initial_grade='initial', self_grade='neutral_self',
           natural_grade='natural_cross_from_DeepSeek'),
    nrow(m), nrow(m), nrow(m), sum(g=='correct'), sum(g=='incorrect'),
    sum(g=='abstention'), 0L, 0L,
    'Selected GSM-Plus v3; same 495 questions; 1 unscorable pair excluded')
}
for (condition in c('neutral_grade','misconception_grade')) {
  g <- h[[condition]]
  stopifnot(all(g %in% c('correct','incorrect','abstention')))
  rows[[length(rows)+1L]] <- row('gsmplus_v3_fresh_first_prompt', 'math',
    'DeepSeek', if (condition == 'neutral_grade') 'neutral_first_prompt'
    else 'scripted_human_misconception_first_prompt',
    nrow(h), nrow(h), nrow(h), sum(g=='correct'), sum(g=='incorrect'),
    sum(g=='abstention'), 0L, 0L,
    '50 questions selected as previously correct by both models; fresh calls')
}
for (condition in c('same_question_self_grade','review_grade')) {
  g <- c50[[condition]]
  stopifnot(all(g %in% c('correct','incorrect','abstention')))
  rows[[length(rows)+1L]] <- row('gsmplus_v3_controlled_50', 'math',
    'MiniMax', if (condition == 'same_question_self_grade')
      'same_question_neutral_self' else 'scripted_wrong_AI_peer',
    nrow(c50), nrow(c50), nrow(c50), sum(g=='correct'),
    sum(g=='incorrect'), sum(g=='abstention'), 0L, 0L,
    'Initially-correct selected 50; scripted false peer, not actual DeepSeek output')
}
for (condition in c('neutral_grade','misconception_grade')) {
  g <- hm[[condition]]
  stopifnot(all(g %in% c('correct','incorrect','abstention')))
  rows[[length(rows)+1L]] <- row('gsmplus_v3_fresh_first_prompt', 'math',
    'MiniMax', if (condition == 'neutral_grade') 'neutral_first_prompt'
    else 'scripted_human_misconception_first_prompt',
    nrow(hm), nrow(hm), nrow(hm), sum(g=='correct'), sum(g=='incorrect'),
    sum(g=='abstention'), 0L, 0L,
    '50 questions selected as previously correct by both models; fresh calls')
}
inventory <- do.call(rbind, rows)
stopifnot(nrow(inventory) == 15L,
          inventory$incorrect[inventory$version=='gsmplus_v3_common'] == c(17,9,4),
          inventory$incorrect[inventory$version=='gsmplus_v3_fresh_first_prompt'] == c(0,3,1,5),
          inventory$incorrect[inventory$version=='gsmplus_v3_controlled_50'] == c(0,0))
write.csv(inventory, file.path(root, 'current_evidence_inventory.csv'),
          row.names = FALSE, na = '')
files <- c(fact_original, fact_later, math_pairs, human_pairs,
           human_minimax_pairs, controlled)
write_json(list(input_files = as.list(files),
                input_sha256 = as.list(vapply(files, digest, character(1),
                                              algo='sha256', file=TRUE)),
                rows = nrow(inventory),
                note = paste('Rows are protocol-specific. No across-version',
                             'or across-domain pooled rate is estimated.')),
           file.path(root, 'current_evidence_inventory_manifest.json'),
           auto_unbox = TRUE, pretty = TRUE)
print(inventory[, c('version','model','condition','scoreable_cells',
                    'incorrect','explicit_abstain','wrong_answer_rate')],
      row.names = FALSE)
