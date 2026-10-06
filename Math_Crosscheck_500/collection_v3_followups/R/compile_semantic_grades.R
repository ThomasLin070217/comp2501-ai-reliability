#!/usr/bin/env Rscript

# Compile reviewed numeric screens into final R grades. Refuses pending rows.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
base <- 'Math_Crosscheck_500/collection_v3_followups'
dir <- file.path(base, 'derived')
screen_file <- file.path(dir, 'screen_queue_992.csv')
required_file <- file.path(dir, 'review_required.csv')
decision_file <- file.path(dir, 'manual_review_decisions.csv')
screen <- read.csv(screen_file, stringsAsFactors = FALSE, check.names = FALSE)
required <- read.csv(required_file, stringsAsFactors = FALSE, check.names = FALSE)
decisions <- read.csv(decision_file, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(screen) == 992L, !anyDuplicated(screen$task_id),
          !anyDuplicated(required$task_id), !anyDuplicated(decisions$task_id),
          setequal(required$task_id, decisions$task_id),
          all(required$task_id %in% screen$task_id),
          all(decisions$final_grade %in% c('correct','incorrect','abstention',
                                           'unscorable_response','technical_incomplete')),
          all(nzchar(decisions$grade_evidence)),
          all(nzchar(decisions$reviewer)))
decisions <- decisions[match(required$task_id, decisions$task_id), ]
stopifnot(identical(required$task_id, decisions$task_id))

out <- screen
out$grade <- ifelse(out$screen_status == 'last_number_matches_key',
                    'correct', 'pending')
out$assessed_answer <- ifelse(out$grade == 'correct',
                              as.character(out$reference_answer_used), '')
out$answer_explanation_conflict <- FALSE
out$grade_evidence <- ifelse(out$grade == 'correct',
  'Numerical screen matched key; checked by fixed positive audit sample and flagged-conflict review.', '')
out$reviewer <- ifelse(out$grade == 'correct', 'Codex-assisted R screen', '')
i <- match(decisions$task_id, out$task_id)
stopifnot(all(!is.na(i)))
out$grade[i] <- decisions$final_grade
out$assessed_answer[i] <- decisions$assessed_answer
out$answer_explanation_conflict[i] <- decisions$answer_explanation_conflict
out$grade_evidence[i] <- decisions$grade_evidence
out$reviewer[i] <- decisions$reviewer
out$reviewed_required <- out$task_id %in% required$task_id
stopifnot(!any(out$grade == 'pending'),
          all(out$grade %in% c('correct','incorrect','abstention',
                               'unscorable_response','technical_incomplete')),
          all(nzchar(out$grade_evidence)))
numeric_grade <- out$grade %in% c('correct','incorrect')
observed <- suppressWarnings(as.numeric(out$assessed_answer[numeric_grade]))
stopifnot(all(is.finite(observed)))
key <- out$reference_answer_used[numeric_grade]
equiv <- abs(observed - key) <= pmax(1e-8, abs(key) * 1e-10)
stopifnot(all(equiv == (out$grade[numeric_grade] == 'correct')))

final_file <- file.path(dir, 'final_scores_992.csv')
write.csv(out, final_file, row.names = FALSE, na = '')
counts <- as.data.frame(table(condition = out$condition, grade = out$grade),
                        stringsAsFactors = FALSE)
counts <- counts[counts$Freq > 0L, ]
write.csv(counts, file.path(dir, 'final_grade_counts.csv'),
          row.names = FALSE)
write_json(list(screen_sha256 = digest(file = screen_file, algo = 'sha256'),
                required_sha256 = digest(file = required_file, algo = 'sha256'),
                decision_sha256 = digest(file = decision_file, algo = 'sha256'),
                final_sha256 = digest(file = final_file, algo = 'sha256'),
                rows = nrow(out), reviewed_required = sum(out$reviewed_required),
                note = paste('Correct/incorrect use final answer, with reason conflicts flagged.',
                             'Unscorable/technical are not active abstentions.')),
           file.path(dir, 'final_grade_audit.json'),
           auto_unbox = TRUE, pretty = TRUE)
print(counts, row.names = FALSE)
