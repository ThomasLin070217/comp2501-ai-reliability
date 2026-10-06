#!/usr/bin/env Rscript

# Screen, do not automatically grade, the completed DeepSeek v3 initials.
# Run from the repository root after all 500 task records have a terminal status.
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(digest))
`%||%` <- function(x, y) if (is.null(x)) y else x
base <- 'Math_Crosscheck_500/collection_v3_deepseek'
task_file <- file.path(base, 'protocol/tasks_deepseek_500.csv')
record_file <- file.path(base, 'runs/completed.jsonl')
key_file <- 'Math_Crosscheck_500/question_review_v3/scoring_key_500.csv'
out_dir <- file.path(base, 'derived')
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

tasks <- read.csv(task_file, stringsAsFactors = FALSE, check.names = FALSE)
key <- read.csv(key_file, stringsAsFactors = FALSE, check.names = FALSE)
lines <- readLines(record_file, warn = FALSE)
records <- lapply(lines, jsonlite::fromJSON, simplifyVector = FALSE)
stopifnot(nrow(tasks) == 500L, nrow(key) == 500L, length(records) == 500L,
          !anyDuplicated(tasks$task_id), !anyDuplicated(tasks$eval_id),
          !anyDuplicated(key$eval_id),
          setequal(tasks$eval_id, key$eval_id))
ids <- vapply(records, function(x) x$task_id, character(1))
stopifnot(!anyDuplicated(ids), setequal(ids, tasks$task_id))
records <- records[match(tasks$task_id, ids)]
key <- key[match(tasks$eval_id, key$eval_id), ]
stopifnot(identical(tasks$eval_id, key$eval_id),
          all(tasks$provider == 'deepseek'),
          all(tasks$model == 'deepseek-v4-pro'),
          all(vapply(records, function(x) identical(x$provider, 'deepseek'), logical(1))))

response <- vapply(records, function(x) x$text %||% '', character(1))
status <- vapply(records, function(x) x$status, character(1))
stop_reason <- vapply(records, function(x) x$finish_reason %||% '', character(1))
search_calls <- vapply(records, function(x) as.integer(x$search_calls %||% 0), integer(1))

blinded <- data.frame(task_id = tasks$task_id, eval_id = tasks$eval_id,
                      question_order = tasks$question_order, batch = tasks$batch,
                      input_text = tasks$input_text, provider = tasks$provider,
                      status = status, finish_reason = stop_reason,
                      model_response = response, search_calls = search_calls,
                      stringsAsFactors = FALSE)

last_number <- function(s) {
  tokens <- regmatches(s, gregexpr('(?<![[:alnum:]])[-+]?[0-9][0-9,]*(?:\\.[0-9]+)?',
                                    s, perl = TRUE))[[1]]
  if (!length(tokens)) return('')
  gsub(',', '', tail(tokens, 1L), fixed = TRUE)
}
candidate <- vapply(response, last_number, character(1))
parsed <- suppressWarnings(as.numeric(candidate))
reference_original <- suppressWarnings(as.numeric(key$reference_answer))
stopifnot(all(is.finite(reference_original)),
          identical(as.character(key$reference_answer[tasks$question_order == 276L]), '150'))
reference_used <- reference_original
reference_used[tasks$question_order == 276L] <- 240
equivalent <- !is.na(parsed) & abs(parsed - reference_used) <=
  pmax(1e-8, abs(reference_used) * 1e-10)
abstain_language <- grepl('(?i)\\b(cannot determine|can.t determine|unable to determine|not enough information|insufficient information|not sure|cannot answer|unable to answer)\\b',
                          response, perl = TRUE)
screen <- ifelse(status != 'ok' | stop_reason != 'end_turn', 'technical_incomplete',
          ifelse(!nzchar(trimws(response)), 'empty_response',
          ifelse(tasks$question_order %in% c(375L, 460L), 'prompt_ambiguous',
          ifelse(abstain_language, 'possible_abstention',
          ifelse(is.na(parsed), 'no_numeric_candidate',
          ifelse(equivalent, 'last_number_matches_key', 'last_number_differs_key'))))))

queue <- cbind(blinded,
               data.frame(perturbation_type = key$perturbation_type,
                          original_reference_answer = reference_original,
                          reference_answer_used = reference_used,
                          last_numeric_candidate = candidate,
                          screen_status = screen,
                          final_grade = 'pending_semantic_review',
                          stringsAsFactors = FALSE))
stopifnot(nrow(queue) == 500L, all(queue$final_grade == 'pending_semantic_review'))
write.csv(blinded, file.path(out_dir, 'grading_input_blinded_500.csv'),
          row.names = FALSE, na = '')
write.csv(queue, file.path(out_dir, 'semantic_review_queue_500.csv'),
          row.names = FALSE, na = '')
counts <- as.data.frame(table(screen_status = queue$screen_status),
                        stringsAsFactors = FALSE)
write.csv(counts, file.path(out_dir, 'screen_counts.csv'),
          row.names = FALSE, na = '')
jsonlite::write_json(list(task_sha256 = digest::digest(file = task_file, algo = 'sha256'),
                          completed_sha256 = digest::digest(file = record_file, algo = 'sha256'),
                          key_sha256 = digest::digest(file = key_file, algo = 'sha256'),
                          records = 500L, status_counts = as.list(table(status)),
                          note = 'Numeric/abstention screen is a review queue, not final accuracy.'),
                     file.path(out_dir, 'screen_manifest.json'),
                     auto_unbox = TRUE, pretty = TRUE)
print(counts, row.names = FALSE)
