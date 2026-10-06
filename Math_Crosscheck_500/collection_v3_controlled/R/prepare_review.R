#!/usr/bin/env Rscript

# Make a full-text, one-row-per-question review queue after controlled collection.
# No automatic candidate is ever treated as a semantic grade.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
base <- 'Math_Crosscheck_500/collection_v3_controlled'
manifest_file <- file.path(base, 'protocol/run_manifest.json')
initial_file <- 'Math_Crosscheck_500/collection_v3_minimax/derived/final_scores_500.csv'
pair_file <- 'Math_Crosscheck_500/collection_v3_followups/analysis/paired_all_496.csv'
manifest <- fromJSON(manifest_file, simplifyVector = FALSE)
initial <- read.csv(initial_file, stringsAsFactors = FALSE)
pair <- read.csv(pair_file, stringsAsFactors = FALSE)
one <- function(x) if (is.null(x) || length(x) == 0L) '' else as.character(x[[1L]])
stopifnot(length(manifest$jobs) == 50L, !anyDuplicated(initial$eval_id),
          !anyDuplicated(pair$eval_id))
rows <- lapply(seq_along(manifest$jobs), function(i) {
  t <- manifest$jobs[[i]]$task
  path <- file.path(base, 'runs', sprintf('task_%04d/final.json', i))
  if (!file.exists(path)) stop('Missing controlled final: ', path)
  f <- fromJSON(path, simplifyVector = FALSE)
  stopifnot(identical(f$task$task_id, t$task_id),
            identical(f$task$eval_id, t$eval_id))
  k <- match(t$eval_id, initial$eval_id)
  j <- match(t$eval_id, pair$eval_id)
  stopifnot(!is.na(k), !is.na(j),
            initial$grade[[k]] == 'correct',
            pair$initial_grade[[j]] == 'correct',
            pair$self_grade[[j]] == 'correct',
            as.integer(t$question_order) == initial$question_order[[k]],
            identical(initial$input_text[[k]], pair$question[[j]]))
  data.frame(task_id = t$task_id, eval_id = t$eval_id,
             question_order = as.integer(t$question_order),
             question = initial$input_text[[k]],
             reference_answer_used = as.character(initial$reference_answer_used[[k]]),
             scripted_wrong_target = as.character(t$wrong_target),
             same_question_self_grade = pair$self_grade[[j]],
             collector_status = one(f$status),
             returned_model = one(f$returned_model),
             stop_reason = one(f$stop_reason),
             model_response = one(f$text),
             final_json_sha256 = digest(file = path, algo = 'sha256'),
             review_grade = '', assessed_answer = '',
             wrong_target_adopted = '', answer_explanation_conflict = '',
             grade_evidence = '', reviewer = '',
             stringsAsFactors = FALSE)
})
out <- do.call(rbind, rows)
stopifnot(nrow(out) == 50L, !anyDuplicated(out$task_id),
          !anyDuplicated(out$eval_id),
          all(out$returned_model[out$collector_status == 'complete_pending_grade'] ==
              'MiniMax-M3'))
dir.create(file.path(base, 'derived'), recursive = TRUE, showWarnings = FALSE)
file <- file.path(base, 'derived/full_text_review_queue_50.csv')
write.csv(out, file, row.names = FALSE, na = '')
write_json(list(manifest_sha256 = digest(file = manifest_file, algo = 'sha256'),
                initial_sha256 = digest(file = initial_file, algo = 'sha256'),
                paired_self_sha256 = digest(file = pair_file, algo = 'sha256'),
                queue_sha256 = digest(file = file, algo = 'sha256'),
                rows = nrow(out),
                technical = sum(out$collector_status != 'complete_pending_grade'),
                note = 'All 50 responses require full-text semantic review.'),
           file.path(base, 'derived/review_queue_manifest.json'),
           pretty = TRUE, auto_unbox = TRUE)
cat('Prepared 50 controlled full-text rows; semantic grades remain blank.\n')
