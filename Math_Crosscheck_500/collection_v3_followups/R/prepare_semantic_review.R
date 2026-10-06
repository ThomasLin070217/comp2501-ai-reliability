#!/usr/bin/env Rscript

# Create a deterministic review handoff for all v3 self/natural answers.
# No correctness label is assigned by this script.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
base <- 'Math_Crosscheck_500/collection_v3_followups'
manifest_file <- file.path(base, 'protocol/run_manifest.json')
initial_file <- 'Math_Crosscheck_500/collection_v3_minimax/derived/final_scores_500.csv'
key_file <- 'Math_Crosscheck_500/collection_v3_deepseek/derived/final_scores_500.csv'
out_dir <- file.path(base, 'derived')
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
plan <- fromJSON(manifest_file, simplifyVector = FALSE)
mini <- read.csv(initial_file, stringsAsFactors = FALSE, check.names = FALSE)
key <- read.csv(key_file, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(length(plan$jobs) == 992L, nrow(mini) == 500L, nrow(key) == 500L)
last_number <- function(s) {
  z <- regmatches(s, gregexpr('(?<![[:alnum:]])[-+]?[0-9][0-9,]*(?:\\.[0-9]+)?',
                             s, perl = TRUE))[[1]]
  if (!length(z)) return('')
  gsub(',', '', tail(z, 1L), fixed = TRUE)
}
rows <- vector('list', length(plan$jobs))
for (i in seq_along(plan$jobs)) {
  t <- plan$jobs[[i]]$task
  p <- file.path(base, 'runs', sprintf('task_%04d/final.json', i))
  if (!file.exists(p)) stop('Missing final branch: ', p)
  f <- fromJSON(p, simplifyVector = FALSE)
  stopifnot(identical(f$task$task_id, t$task_id),
            identical(f$task$eval_id, t$eval_id))
  j <- match(t$eval_id, key$eval_id)
  h <- match(t$eval_id, mini$eval_id)
  stopifnot(!is.na(j), !is.na(h),
            identical(mini$input_text[h], key$input_text[j]))
  text <- f$text
  candidate <- last_number(text)
  reference <- as.numeric(key$reference_answer_used[j])
  parsed <- suppressWarnings(as.numeric(candidate))
  screen <- if (f$status != 'complete_pending_grade') 'technical_incomplete'
            else if (!nzchar(trimws(text))) 'empty_response'
            else if (is.na(parsed)) 'no_numeric_candidate'
            else if (abs(parsed - reference) <= max(1e-8,abs(reference)*1e-10))
              'last_number_matches_key' else 'last_number_differs_key'
  # A matching last number can still be rejected in the prose.
  tail_text <- substr(text, max(1L, nchar(text) - 350L), nchar(text))
  negative_key <- grepl(paste0('(?i)\\b(?:not|rather than|instead of)\\s+\\$?',
                               gsub('\\.', '\\\\.', as.character(reference)), '\\b'),
                        tail_text, perl = TRUE)
  rows[[i]] <- data.frame(task_id = t$task_id, eval_id = t$eval_id,
    question_order = as.integer(t$question_order), condition = t$condition,
    initial_grade = mini$grade[h], donor_grade = key$grade[j],
    reference_answer_used = reference, status = f$status,
    screen_status = screen, last_numeric_candidate = candidate,
    possible_positive_conflict = negative_key,
    model_response = text, raw_path = p, stringsAsFactors = FALSE)
}
d <- do.call(rbind, rows)
stopifnot(nrow(d) == 992L, !anyDuplicated(d$task_id),
          all(table(d$condition) == 496L))
write.csv(d, file.path(out_dir, 'screen_queue_992.csv'),
          row.names = FALSE, na = '')

set.seed(25011017L)
sampled <- character()
for (condition in c('self_check','natural_crosscheck')) {
  x <- d[d$condition == condition &
         d$screen_status == 'last_number_matches_key', ]
  stopifnot(nrow(x) >= 60L)
  sampled <- c(sampled, sample(x$task_id, 60L))
}
required <- d$screen_status != 'last_number_matches_key' |
            d$possible_positive_conflict | d$task_id %in% sampled
review <- d[required, ]
review$review_reason <- ifelse(review$screen_status != 'last_number_matches_key',
  review$screen_status, ifelse(review$possible_positive_conflict,
    'positive_screen_with_negative_key_phrase', 'fixed_positive_spot_audit'))
review$final_grade <- 'pending'
review$assessed_answer <- ''
review$answer_explanation_conflict <- FALSE
review$grade_evidence <- ''
review$reviewer <- ''
review_file <- file.path(out_dir, 'review_required.csv')
write.csv(review, review_file, row.names = FALSE, na = '')
write_json(list(manifest_sha256 = digest(file = manifest_file, algo = 'sha256'),
                initial_sha256 = digest(file = initial_file, algo = 'sha256'),
                donor_score_sha256 = digest(file = key_file, algo = 'sha256'),
                screen_sha256 = digest(file = file.path(out_dir, 'screen_queue_992.csv'), algo = 'sha256'),
                review_sha256 = digest(file = review_file, algo = 'sha256'),
                total = nrow(d), review_required = nrow(review),
                fixed_positive_sample_per_condition = 60L,
                note = 'Screen and audit selection only. A final grade requires review decisions.'),
           file.path(out_dir, 'review_preparation_manifest.json'),
           auto_unbox = TRUE, pretty = TRUE)
print(as.data.frame(table(condition = d$condition,
                          screen_status = d$screen_status)), row.names = FALSE)
cat('Manual review required:', nrow(review), '\n')
