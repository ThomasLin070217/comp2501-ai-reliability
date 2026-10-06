#!/usr/bin/env Rscript

# R-only preliminary screen of new GSM-Plus v3 branch outcomes.
# Does not assign final correctness: each discordance requires semantic review.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
`%||%` <- function(x, y) if (is.null(x)) y else x
base <- 'Math_Crosscheck_500'
out_dir <- file.path(base, 'v3_review')
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
key_file <- file.path(base, 'collection_v3_deepseek/derived/final_scores_500.csv')
k <- read.csv(key_file, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(k) == 500L, !anyDuplicated(k$eval_id))

last_number <- function(s) {
  tokens <- regmatches(s, gregexpr('(?<![[:alnum:]])[-+]?[0-9][0-9,]*(?:\\.[0-9]+)?',
                                    s, perl = TRUE))[[1]]
  if (!length(tokens)) return('')
  gsub(',', '', tail(tokens, 1L), fixed = TRUE)
}
read_jsonl <- function(p) {
  if (!file.exists(p) || file.info(p)$size == 0) return(list())
  lapply(readLines(p, warn = FALSE), fromJSON, simplifyVector = FALSE)
}
rows <- list()
add <- function(task_id, eval_id, provider, condition, status, text, raw_path,
                peer_origin = '', wrong_target = '') {
  j <- match(eval_id, k$eval_id)
  stopifnot(!is.na(j))
  candidate <- last_number(text)
  key <- as.numeric(k$reference_answer_used[j])
  numeric <- suppressWarnings(as.numeric(candidate))
  screen <- if (status != 'complete_pending_grade' && status != 'ok')
              'technical_incomplete' else if (!nzchar(trimws(text)))
              'empty_response' else if (k$question_order[j] %in% c(375L,460L))
              'prompt_ambiguous' else if (is.na(numeric))
              'no_numeric_candidate' else if (abs(numeric - key) <=
                  max(1e-8, abs(key) * 1e-10))
              'last_number_matches_key' else 'last_number_differs_key'
  rows[[length(rows) + 1L]] <<- data.frame(
    task_id = task_id, eval_id = eval_id, question_order = k$question_order[j],
    provider = provider, condition = condition, peer_origin = peer_origin,
    wrong_target = wrong_target, reference_answer_used = key,
    question = k$input_text[j], status = status, model_response = text,
    last_numeric_candidate = candidate, screen_status = screen,
    final_grade = 'pending_semantic_review', raw_path = raw_path,
    stringsAsFactors = FALSE)
}

# Same-baseline MiniMax self/natural branches.
followup_dir <- file.path(base, 'collection_v3_followups/runs')
finals <- sort(list.files(followup_dir, pattern = '^final\\.json$',
                          recursive = TRUE, full.names = TRUE))
for (p in finals) {
  f <- fromJSON(p, simplifyVector = FALSE)
  add(f$task$task_id, f$task$eval_id, 'minimax', f$task$condition,
      f$status, f$text %||% '', p, f$task$peer_origin)
}

# Scripted wrong-peer branch, when it exists.
controlled_dir <- file.path(base, 'collection_v3_controlled/runs')
controlled <- sort(list.files(controlled_dir, pattern = '^final\\.json$',
                              recursive = TRUE, full.names = TRUE))
for (p in controlled) {
  f <- fromJSON(p, simplifyVector = FALSE)
  add(f$task$task_id, f$task$eval_id, 'minimax', f$task$condition,
      f$status, f$text %||% '', p, f$task$peer_origin, f$task$wrong_target)
}

# Fresh first-prompt neutral/misconception pairs.
for (provider in c('minimax','deepseek')) {
  p <- file.path(base, 'collection_v3_human_first/runs', provider, 'completed.jsonl')
  z <- read_jsonl(p)
  for (f in z) {
    add(f$task_id, f$eval_id, provider, f$condition, f$status,
        f$text %||% '', p, if (f$condition == 'human_misconception')
          'researcher_scripted_human_first_prompt' else 'none',
        f$wrong_target %||% '')
  }
}
if (!length(rows)) stop('No v3 follow-up records present.')
d <- do.call(rbind, rows)
stopifnot(!anyDuplicated(d$task_id))
out <- file.path(out_dir, 'v3_all_conditions_review_queue.csv')
write.csv(d, out, row.names = FALSE, na = '')
summary <- as.data.frame(table(provider = d$provider, condition = d$condition,
                               screen_status = d$screen_status),
                         stringsAsFactors = FALSE)
summary <- summary[summary$Freq > 0, ]
write.csv(summary, file.path(out_dir, 'v3_screen_counts.csv'),
          row.names = FALSE, na = '')
write_json(list(key_sha256 = digest(file = key_file, algo = 'sha256'),
                queue_sha256 = digest(file = out, algo = 'sha256'),
                records = nrow(d),
                note = 'Screen only; final_grade is deliberately pending.'),
           file.path(out_dir, 'v3_review_queue_manifest.json'),
           auto_unbox = TRUE, pretty = TRUE)
print(summary, row.names = FALSE)
