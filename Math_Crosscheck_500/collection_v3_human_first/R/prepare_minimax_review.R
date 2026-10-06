#!/usr/bin/env Rscript

# Full-text MiniMax first-prompt review queue, with no automatic semantic grades.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
base <- 'Math_Crosscheck_500/collection_v3_human_first'
tasks_file <- file.path(base, 'protocol/tasks_200.csv')
raw_file <- file.path(base, 'runs/minimax/completed.jsonl')
initial_file <- 'Math_Crosscheck_500/collection_v3_minimax/derived/final_scores_500.csv'
tasks <- read.csv(tasks_file, stringsAsFactors = FALSE)
tasks <- tasks[tasks$provider == 'minimax', ]
initial <- read.csv(initial_file, stringsAsFactors = FALSE)
if (!file.exists(raw_file)) stop('MiniMax completed records not collected yet.')
raw <- lapply(readLines(raw_file, warn = FALSE), fromJSON, simplifyVector = FALSE)
stopifnot(nrow(tasks) == 100L, length(raw) == 100L,
          !anyDuplicated(tasks$task_id),
          !anyDuplicated(vapply(raw, function(x) x$task_id, character(1))),
          !anyDuplicated(initial$eval_id))
ids <- vapply(raw, function(x) x$task_id, character(1))
stopifnot(setequal(ids, tasks$task_id))
raw <- raw[match(tasks$task_id, ids)]
k <- initial[match(tasks$eval_id, initial$eval_id), ]
stopifnot(identical(tasks$eval_id, k$eval_id),
          all(tasks$original_question == k$input_text),
          all(k$grade == 'correct'),
          all(vapply(raw, function(x) identical(x$model, 'MiniMax-M3'), logical(1))))
scalar <- function(x) if (is.null(x) || length(x) == 0L) '' else as.character(x[[1L]])
scalar_int <- function(x) if (is.null(x) || length(x) == 0L) 0L else as.integer(x[[1L]])
out <- data.frame(task_id = tasks$task_id, eval_id = tasks$eval_id,
                  question_order = tasks$question_order,
                  condition = tasks$condition,
                  original_question = tasks$original_question,
                  reference_answer_used = as.character(k$reference_answer_used),
                  scripted_wrong_target = as.character(tasks$wrong_target),
                  collector_status = vapply(raw, function(x) scalar(x$status), character(1)),
                  finish_reason = vapply(raw, function(x) scalar(x$finish_reason), character(1)),
                  model_response = vapply(raw, function(x) scalar(x$text), character(1)),
                  search_calls = vapply(raw, function(x) scalar_int(x$search_calls), integer(1)),
                  review_grade = '', assessed_answer = '',
                  wrong_target_adopted = '', answer_explanation_conflict = '',
                  grade_evidence = '', reviewer = '',
                  stringsAsFactors = FALSE)
stopifnot(sum(out$condition == 'neutral') == 50L,
          sum(out$condition == 'human_misconception') == 50L,
          all(table(out$eval_id) == 2L))
out_dir <- file.path(base, 'derived')
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
file <- file.path(out_dir, 'minimax_full_text_review_queue_100.csv')
write.csv(out, file, row.names = FALSE, na = '')
write_json(list(tasks_sha256 = digest(file = tasks_file, algo = 'sha256'),
                completed_sha256 = digest(file = raw_file, algo = 'sha256'),
                initial_sha256 = digest(file = initial_file, algo = 'sha256'),
                queue_sha256 = digest(file = file, algo = 'sha256'),
                rows = nrow(out),
                technical = sum(out$collector_status != 'ok'),
                note = 'Review all 100 full replies; blank grades are intentional.'),
           file.path(out_dir, 'minimax_review_queue_manifest.json'),
           pretty = TRUE, auto_unbox = TRUE)
cat('Prepared 100 MiniMax first-prompt review rows; semantic grades remain blank.\n')
