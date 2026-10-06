#!/usr/bin/env Rscript

# Verify the preselected positive-screen audit and conflict flags after grading.
suppressPackageStartupMessages({library(digest); library(jsonlite)})
base <- 'Math_Crosscheck_500/collection_v3_followups'
queue_file <- file.path(base, 'derived/review_required.csv')
decision_file <- file.path(base, 'derived/manual_review_decisions.csv')
out <- file.path(base, 'analysis')
q <- read.csv(queue_file, stringsAsFactors = FALSE)
d <- read.csv(decision_file, stringsAsFactors = FALSE)
stopifnot(nrow(q) == 255L, nrow(d) == 255L,
          !anyDuplicated(q$task_id), !anyDuplicated(d$task_id),
          setequal(q$task_id, d$task_id))
y <- merge(q[, c('task_id','condition','question_order','review_reason')],
           d, by = 'task_id', all.x = TRUE, sort = FALSE)
stopifnot(nrow(y) == 255L, !anyNA(y$final_grade))
audit <- y[y$review_reason == 'fixed_positive_spot_audit', ]
stopifnot(nrow(audit) == 120L,
          identical(sort(as.integer(table(audit$condition))), c(60L, 60L)))
counts <- aggregate(rep(1L, nrow(y)),
                    by = list(review_reason = y$review_reason,
                              final_grade = y$final_grade), FUN = sum)
names(counts)[[3]] <- 'n'
write.csv(counts, file.path(out, 'review_reason_grade_counts.csv'), row.names = FALSE)
conflicts <- y[y$answer_explanation_conflict, c('task_id','question_order',
              'condition','final_grade','grade_evidence')]
write.csv(conflicts, file.path(out, 'answer_explanation_conflicts.csv'),
          row.names = FALSE)
write_json(list(queue_sha256 = digest(file = queue_file, algo = 'sha256'),
                decision_sha256 = digest(file = decision_file, algo = 'sha256'),
                required_review = nrow(y), positive_screen_audit = nrow(audit),
                positive_screen_audit_incorrect = sum(audit$final_grade == 'incorrect'),
                flagged_conflicts = nrow(conflicts),
                note = paste('Zero detected errors in the fixed audit does not prove',
                             'all unreviewed positive screens are correct.')),
           file.path(out, 'semantic_audit_manifest.json'),
           auto_unbox = TRUE, pretty = TRUE)
print(counts, row.names = FALSE)
