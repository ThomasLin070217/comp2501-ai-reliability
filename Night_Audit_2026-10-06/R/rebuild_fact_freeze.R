#!/usr/bin/env Rscript

# Independent R reconstruction of the frozen 1,000 fact question/model cells.
# Run from the repository root. No model requests and no source-file edits.
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(digest))

root <- 'Initial_Response_Accuracy_Evaluation'
processed <- file.path(root, 'processed')
collection <- file.path(root, 'collection')
initial_file <- file.path(processed, 'initial_fact_2026-10-06/fact_initial_responses_1000.csv')
grade_file <- file.path(processed, 'initial_fact_2026-10-06/fact_initial_semantic_grades_931.csv')
recovery_file <- file.path(processed, 'selfcheck_recovery_2026-10-06/fact_recovery_available_review_70.csv')
direct_file <- file.path(processed, 'selfcheck_recovery_2026-10-06/direct_minimax_available_review_37.csv')
direct_v2_file <- file.path(processed, 'selfcheck_recovery_2026-10-06/direct_minimax_review_decisions_v2.csv')
selfcheck_file <- file.path(processed, 'selfcheck_recovery_2026-10-06/wrong_selfcheck_final_review_112.csv')
new_selfcheck_file <- file.path(processed, 'selfcheck_recovery_2026-10-06/recovered_wrong_selfcheck_available.csv')
frozen_dir <- file.path(processed, 'fact_frozen_2026-10-06')
frozen_file <- file.path(frozen_dir, 'fact_frozen_responses_1000.csv')
manifest_file <- file.path(frozen_dir, 'freeze_manifest.json')
out_dir <- 'Night_Audit_2026-10-06/derived'
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

read_table <- function(path) read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
sha <- function(path) digest::digest(file = path, algo = 'sha256')
initial <- read_table(initial_file)
initial_grades <- read_table(grade_file)
recovery <- read_table(recovery_file)
direct <- read_table(direct_file)
direct_v2 <- read_table(direct_v2_file)
selfcheck <- read_table(selfcheck_file)
new_selfcheck <- read_table(new_selfcheck_file)
frozen <- read_table(frozen_file)
manifest <- jsonlite::fromJSON(manifest_file, simplifyVector = FALSE)
graded <- c('correct', 'incorrect', 'abstain')

stopifnot(nrow(initial) == 1000L, nrow(frozen) == 1000L,
          nrow(initial_grades) == 931L, nrow(recovery) == 70L,
          nrow(direct) == 37L, nrow(direct_v2) == 37L,
          !anyDuplicated(initial$task_id), !anyDuplicated(initial_grades$task_id),
          !anyDuplicated(recovery$task_id), !anyDuplicated(direct$task_id),
          !anyDuplicated(direct_v2$task_id),
          length(unique(initial$eval_id)) == 500L,
          all(table(initial$eval_id) == 2L),
          all(table(initial$provider) == 500L),
          setequal(initial$task_id, frozen$task_id),
          setequal(direct$task_id, direct_v2$task_id),
          sha(frozen_file) == manifest$output_hashes_sha256[[frozen_file]])
for (p in names(manifest$source_hashes_sha256)) {
  stopifnot(file.exists(p), identical(sha(p), manifest$source_hashes_sha256[[p]]))
}

raw_final <- function(route, task_id) {
  paths <- list.files(file.path(collection, route), pattern = '^final[.]json$',
                      recursive = TRUE, full.names = TRUE)
  records <- lapply(paths, jsonlite::fromJSON)
  ix <- which(vapply(records, function(x) identical(x$task_id, task_id), logical(1)))
  stopifnot(length(ix) == 1L, identical(records[[ix]]$status, 'complete_end_turn'),
            identical(records[[ix]]$stop_reason, 'end_turn'))
  list(record = records[[ix]], path = paths[ix])
}

reconstructed <- data.frame(
  task_id = initial$task_id, eval_id = initial$eval_id,
  question_order = initial$question_order, provider = initial$provider,
  source_benchmark = initial$source_benchmark,
  question_text = initial$question_text,
  reference_answer = initial$reference_answer,
  original_status = initial$final_answer_status,
  chosen_source = rep('no_complete_answer', nrow(initial)),
  chosen_grade = rep('technical_incomplete', nrow(initial)),
  chosen_answer_text = rep('', nrow(initial)),
  stringsAsFactors = FALSE
)

assign_answer <- function(task_id, source, grade, answer) {
  ix <- match(task_id, reconstructed$task_id)
  stopifnot(!is.na(ix), reconstructed$chosen_source[ix] == 'no_complete_answer',
            grade %in% c(graded, 'unscorable'), nzchar(answer))
  reconstructed$chosen_source[ix] <<- source
  reconstructed$chosen_grade[ix] <<- grade
  reconstructed$chosen_answer_text[ix] <<- answer
}

# Original 931 complete turns: the saved semantic decisions must match the
# assembled final text, not just the task IDs.
for (i in seq_len(nrow(initial_grades))) {
  ix <- match(initial_grades$task_id[i], initial$task_id)
  stopifnot(!is.na(ix), identical(initial$final_answer_text[ix],
                                  initial_grades$final_answer_text[i]))
  assign_answer(initial_grades$task_id[i], 'frozen_initial_collection',
                initial_grades$grade[i], initial_grades$final_answer_text[i])
}

# The 33 selected original-gateway recoveries must match native final.json.
rr <- recovery[recovery$semantic_grade %in% graded, , drop = FALSE]
stopifnot(nrow(rr) == 33L, all(rr$recovery_status == 'complete_end_turn'))
for (i in seq_len(nrow(rr))) {
  raw <- raw_final(rr$recovery_source[i], rr$task_id[i])
  stopifnot(identical(raw$record$final_text, rr$recovery_text[i]))
  assign_answer(rr$task_id[i], rr$recovery_source[i],
                rr$semantic_grade[i], rr$recovery_text[i])
}

# Six complete direct-endpoint answers in the first batch, plus the seventh
# later-resumed answer whose newer saved review marks an explicit abstention.
dr <- direct[direct$chosen_grade %in% graded, , drop = FALSE]
stopifnot(nrow(dr) == 6L, all(dr$status == 'complete_end_turn'))
for (i in seq_len(nrow(dr))) {
  raw <- raw_final('recovery_minimax_direct_2026-10-06', dr$task_id[i])
  stopifnot(identical(raw$record$final_text, dr$chosen_text[i]))
  assign_answer(dr$task_id[i], 'official_minimax_direct_supplement',
                dr$chosen_grade[i], dr$chosen_text[i])
}
new_id <- 'fact500:FS_77c95f87fd:minimax:single'
stopifnot(identical(direct_v2$grade[match(new_id, direct_v2$task_id)], 'abstain'),
          sum(direct_v2$grade %in% graded) == 7L)
new_raw <- raw_final('recovery_minimax_direct_resumed_2026-10-06', new_id)
assign_answer(new_id, 'official_minimax_direct_resumed_supplement',
              'abstain', new_raw$record$final_text)

# Compare every column and every row with the independently frozen view.
stopifnot(identical(names(reconstructed), names(frozen)),
          identical(reconstructed$task_id, frozen$task_id))
differences <- vapply(names(frozen), function(k)
  sum(as.character(reconstructed[[k]]) != as.character(frozen[[k]])), integer(1))
stopifnot(all(differences == 0L))

summary <- do.call(rbind, lapply(c('deepseek', 'minimax'), function(model) {
  x <- reconstructed[reconstructed$provider == model, , drop = FALSE]
  counts <- vapply(c(graded, 'technical_incomplete', 'unscorable'),
                   function(g) sum(x$chosen_grade == g), integer(1))
  n <- sum(counts[graded])
  data.frame(provider = model, cells = nrow(x), scored = n,
             correct = counts['correct'], incorrect = counts['incorrect'],
             abstain = counts['abstain'],
             technical_incomplete = counts['technical_incomplete'],
             unscorable = counts['unscorable'],
             error_pct = round(100 * counts['incorrect'] / n, 2),
             stringsAsFactors = FALSE)
}))
stopifnot(sum(summary$scored) == 970L,
          sum(summary$technical_incomplete) == 29L,
          sum(summary$unscorable) == 1L)

# A conditional follow-up on the original 112 wrong answers is not the
# whole-sample self-check error rate. Preserve its separate denominator.
stopifnot(nrow(selfcheck) == 112L, !anyDuplicated(selfcheck$baseline_task_id),
          all(selfcheck$initial_grade == 'incorrect'),
          all(selfcheck$chosen_status == 'complete_end_turn'),
          all(selfcheck$final_grade %in% graded),
          nrow(new_selfcheck) == 1L,
          !(new_selfcheck$baseline_task_id %in% selfcheck$baseline_task_id),
          new_selfcheck$provider == 'deepseek',
          new_selfcheck$semantic_grade == 'incorrect')
self_summary <- do.call(rbind, lapply(c('deepseek', 'minimax'), function(model) {
  x <- selfcheck[selfcheck$provider == model, , drop = FALSE]
  data.frame(cohort = 'original_initially_wrong', provider = model,
             n = nrow(x), corrected = sum(x$final_grade == 'correct'),
             still_incorrect = sum(x$final_grade == 'incorrect'),
             abstain = sum(x$final_grade == 'abstain'))
}))
self_summary <- rbind(self_summary,
  data.frame(cohort = 'newly_recovered_initially_wrong', provider = 'deepseek',
             n = 1L, corrected = 0L, still_incorrect = 1L, abstain = 0L))
stopifnot(sum(self_summary$n[self_summary$cohort == 'original_initially_wrong']) == 112L,
          sum(self_summary$corrected) == 27L,
          sum(self_summary$still_incorrect) == 80L,
          sum(self_summary$abstain) == 6L)

out_data <- file.path(out_dir, 'fact_frozen_rebuilt_R_1000.csv')
out_summary <- file.path(out_dir, 'fact_frozen_rebuilt_R_summary.csv')
out_self <- file.path(out_dir, 'fact_selfcheck_conditional_R_summary.csv')
out_audit <- file.path(out_dir, 'fact_frozen_rebuilt_R_audit.json')
write.csv(reconstructed, out_data, row.names = FALSE, na = '')
write.csv(summary, out_summary, row.names = FALSE, na = '')
write.csv(self_summary, out_self, row.names = FALSE, na = '')
jsonlite::write_json(list(
  input_sha256 = as.list(vapply(c(initial_file, grade_file, recovery_file,
                                  direct_file, direct_v2_file, selfcheck_file,
                                  new_selfcheck_file, frozen_file), sha, character(1))),
  selected_native_completions = list(original_gateway = nrow(rr),
                                     official_first = nrow(dr),
                                     official_resumed = 1L),
  cell_column_disagreements_with_frozen = as.list(differences),
  output_sha256 = list(data = sha(out_data), summary = sha(out_summary),
                       conditional_selfcheck = sha(out_self)),
  original_frozen_sha256 = sha(frozen_file),
  note = 'R reconstruction from original initial cells, semantic decisions and verified native recovery finals. Does not independently verify all benchmark answer keys.'
), out_audit, auto_unbox = TRUE, pretty = TRUE)
print(summary, row.names = FALSE)
cat('All 1,000 rows and 11 columns agree with the frozen view.\n')
