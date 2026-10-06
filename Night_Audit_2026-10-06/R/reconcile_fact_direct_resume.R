#!/usr/bin/env Rscript

# Run from the repository root. This is a derived overlay: source records stay unchanged.
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(digest))

source_dir <- 'Initial_Response_Accuracy_Evaluation/processed/selfcheck_recovery_2026-10-06'
run_dir <- 'Initial_Response_Accuracy_Evaluation/collection/recovery_minimax_direct_resumed_2026-10-06/tasks'
out_dir <- 'Night_Audit_2026-10-06/derived'
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

source_file <- file.path(source_dir, 'fact_direct_supplement_scored_1000.csv')
decision_file <- file.path(source_dir, 'direct_minimax_review_decisions_v2.csv')
old_review_file <- file.path(source_dir, 'direct_minimax_available_review_37.csv')
source_view <- read.csv(source_file, stringsAsFactors = FALSE, check.names = FALSE)
decisions <- read.csv(decision_file, stringsAsFactors = FALSE, check.names = FALSE)
old_review <- read.csv(old_review_file, stringsAsFactors = FALSE, check.names = FALSE)

stopifnot(nrow(source_view) == 1000L,
          !anyDuplicated(source_view$task_id),
          identical(sort(unique(source_view$provider)), c('deepseek', 'minimax')),
          all(table(source_view$provider) == 500L),
          nrow(decisions) == 37L,
          !anyDuplicated(decisions$task_id),
          setequal(decisions$task_id, old_review$task_id))

graded <- c('correct', 'incorrect', 'abstain')
old_graded <- old_review$task_id[old_review$chosen_grade %in% graded]
new_graded <- decisions$task_id[decisions$grade %in% graded]
newly_completed <- setdiff(new_graded, old_graded)
stopifnot(length(newly_completed) == 1L,
          identical(newly_completed, 'fact500:FS_77c95f87fd:minimax:single'),
          identical(decisions$grade[match(newly_completed, decisions$task_id)], 'abstain'))

raw_paths <- list.files(run_dir, pattern = '^final[.]json$', recursive = TRUE, full.names = TRUE)
raw <- lapply(raw_paths, jsonlite::fromJSON)
raw_match <- which(vapply(raw, function(x) identical(x$task_id, newly_completed), logical(1)))
stopifnot(length(raw_match) == 1L,
          identical(raw[[raw_match]]$status, 'complete_end_turn'),
          identical(raw[[raw_match]]$stop_reason, 'end_turn'),
          nchar(raw[[raw_match]]$final_text) > 0L)

updated <- source_view
ix <- match(newly_completed, updated$task_id)
stopifnot(!is.na(ix), updated$provider[ix] == 'minimax',
          !(updated$chosen_grade[ix] %in% graded))
updated$chosen_grade[ix] <- 'abstain'
updated$chosen_source[ix] <- 'official_minimax_direct_supplement_resumed'
updated$chosen_answer_text[ix] <- raw[[raw_match]]$final_text
stopifnot(sum(updated$chosen_grade != source_view$chosen_grade) == 1L,
          sum(updated$chosen_source != source_view$chosen_source) == 1L)

summarize_model <- function(model) {
  x <- updated[updated$provider == model, , drop = FALSE]
  n <- sum(x$chosen_grade %in% graded)
  correct <- sum(x$chosen_grade == 'correct')
  incorrect <- sum(x$chosen_grade == 'incorrect')
  abstain <- sum(x$chosen_grade == 'abstain')
  stopifnot(n == correct + incorrect + abstain, nrow(x) == 500L)
  data.frame(provider = model, total_tasks = nrow(x), scored_complete = n,
             correct = correct, incorrect = incorrect, abstain = abstain,
             unscorable = sum(x$chosen_grade == 'unscorable'),
             technical_incomplete = sum(x$chosen_grade == 'technical_incomplete'),
             correct_pct = round(100 * correct/n, 2),
             incorrect_pct = round(100 * incorrect/n, 2),
             abstain_pct = round(100 * abstain/n, 2))
}
summary <- do.call(rbind, lapply(c('deepseek','minimax'), summarize_model))
stopifnot(summary$scored_complete[summary$provider == 'deepseek'] == 500L,
          summary$scored_complete[summary$provider == 'minimax'] == 470L,
          summary$incorrect[summary$provider == 'minimax'] == 78L,
          sum(decisions$grade %in% graded) == 7L)

write.csv(updated, file.path(out_dir, 'fact_direct_supplement_resumed_scored_1000.csv'), row.names = FALSE, na = '')
write.csv(summary, file.path(out_dir, 'fact_direct_supplement_resumed_summary.csv'), row.names = FALSE, na = '')
audit <- list(
  source_sha256 = digest::digest(file = source_file, algo = 'sha256'),
  decisions_sha256 = digest::digest(file = decision_file, algo = 'sha256'),
  new_raw_final_sha256 = digest::digest(file = raw_paths[raw_match], algo = 'sha256'),
  newly_completed_task = newly_completed,
  newly_completed_status = raw[[raw_match]]$status,
  newly_completed_grade = 'abstain',
  direct_route_graded = as.list(table(factor(decisions$grade[decisions$grade %in% graded], levels = graded))),
  distinct_direct_route_graded = length(new_graded),
  total_scored_cells = sum(summary$scored_complete),
  note = 'Official-endpoint supplement is separate from the frozen original HKU-gateway analysis.'
)
jsonlite::write_json(audit, file.path(out_dir, 'fact_direct_supplement_resumed_audit.json'),
                     pretty = TRUE, auto_unbox = TRUE)
print(summary, row.names = FALSE)
