#!/usr/bin/env Rscript

# Align the two independently collected GSM-Plus v3 initial-answer runs.
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(digest))
mini_file <- 'Math_Crosscheck_500/collection_v3_minimax/derived/final_scores_500.csv'
deep_file <- 'Math_Crosscheck_500/collection_v3_deepseek/derived/final_scores_500.csv'
out_dir <- 'Math_Crosscheck_500/collection_v3_deepseek/derived'
m <- read.csv(mini_file, stringsAsFactors = FALSE, check.names = FALSE)
d <- read.csv(deep_file, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(m) == 500L, nrow(d) == 500L,
          !anyDuplicated(m$eval_id), !anyDuplicated(d$eval_id),
          setequal(m$eval_id, d$eval_id))
d <- d[match(m$eval_id, d$eval_id), ]
stopifnot(identical(m$eval_id, d$eval_id),
          identical(m$question_order, d$question_order),
          identical(m$input_text, d$input_text))

out <- data.frame(eval_id = m$eval_id, question_order = m$question_order,
                  question = m$input_text, reference_answer_used = m$reference_answer_used,
                  minimax_task_id = m$task_id, minimax_grade = m$grade,
                  minimax_response = m$model_response,
                  deepseek_task_id = d$task_id, deepseek_grade = d$grade,
                  deepseek_response = d$model_response,
                  deepseek_search_calls = d$search_calls,
                  stringsAsFactors = FALSE)
stopifnot(all(as.numeric(m$reference_answer_used) ==
              as.numeric(d$reference_answer_used)))
out$minimax_scorable <- out$minimax_grade %in% c('correct','incorrect')
out$deepseek_scorable <- out$deepseek_grade %in% c('correct','incorrect')
out$common_scorable <- out$minimax_scorable & out$deepseek_scorable
write.csv(out, file.path(out_dir, 'matched_initial_baseline_500.csv'),
          row.names = FALSE, na = '')

summarize <- function(x, label) {
  subset <- out[x, ]
  data.frame(view = label, question_cells = nrow(subset),
             minimax_correct = sum(subset$minimax_grade == 'correct'),
             minimax_incorrect = sum(subset$minimax_grade == 'incorrect'),
             deepseek_correct = sum(subset$deepseek_grade == 'correct'),
             deepseek_incorrect = sum(subset$deepseek_grade == 'incorrect'),
             both_incorrect = sum(subset$minimax_grade == 'incorrect' &
                                    subset$deepseek_grade == 'incorrect'),
             mini_wrong_deep_right = sum(subset$minimax_grade == 'incorrect' &
                                           subset$deepseek_grade == 'correct'),
             mini_right_deep_wrong = sum(subset$minimax_grade == 'correct' &
                                           subset$deepseek_grade == 'incorrect'),
             stringsAsFactors = FALSE)
}
s <- rbind(summarize(rep(TRUE, nrow(out)), 'all_500'),
           summarize(out$common_scorable, 'common_scorable_frozen_key'),
           summarize(out$common_scorable & out$question_order != 12L,
                     'common_scorable_exclude_posthoc_ambiguous_12'))
write.csv(s, file.path(out_dir, 'matched_initial_summary.csv'),
          row.names = FALSE, na = '')
write_json(list(minimax_score_sha256 = digest(file = mini_file, algo = 'sha256'),
                deepseek_score_sha256 = digest(file = deep_file, algo = 'sha256'),
                rows = nrow(out), common_scorable = sum(out$common_scorable),
                same_id_order_and_question = TRUE,
                note = 'MiniMax and DeepSeek are independent initials; no cross-check effect is measured here.'),
           file.path(out_dir, 'matched_initial_manifest.json'),
           auto_unbox = TRUE, pretty = TRUE)
print(s, row.names = FALSE)
