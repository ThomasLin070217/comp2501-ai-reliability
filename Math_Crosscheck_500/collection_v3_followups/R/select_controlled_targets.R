#!/usr/bin/env Rscript

# Freeze the controlled wrong-peer subset before inspecting any follow-up text.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
base <- 'Math_Crosscheck_500/collection_v3_followups'
mini_file <- 'Math_Crosscheck_500/collection_v3_minimax/derived/final_scores_500.csv'
key_file <- 'Math_Crosscheck_500/question_review_v3/scoring_key_500.csv'
out <- file.path(base, 'protocol/controlled_target_selection_50.csv')
manifest <- file.path(base, 'protocol/controlled_target_selection_manifest.json')
stopifnot(!file.exists(out), !file.exists(manifest))
m <- read.csv(mini_file, stringsAsFactors = FALSE, check.names = FALSE)
k <- read.csv(key_file, stringsAsFactors = FALSE, check.names = FALSE)
k <- k[match(m$eval_id, k$eval_id), ]
stopifnot(nrow(m) == 500L, identical(m$eval_id, k$eval_id),
          !anyDuplicated(m$eval_id))
eligible <- m$grade == 'correct' & m$question_order != 12L
quotas <- c('distraction insertion' = 20L,
            'problem understanding' = 15L,
            'restored source problem' = 15L)
set.seed(25011012L)
picked <- integer()
for (group in names(quotas)) {
  pool <- which(eligible & k$perturbation_type == group)
  stopifnot(length(pool) >= quotas[[group]])
  picked <- c(picked, sample(pool, quotas[[group]]))
}
stopifnot(length(picked) == 50L, !anyDuplicated(picked))
selection <- data.frame(eval_id = m$eval_id[picked],
                        question_order = m$question_order[picked],
                        perturbation_type = k$perturbation_type[picked],
                        original_question = m$input_text[picked],
                        reference_answer_used = m$reference_answer_used[picked],
                        mini_initial_task_id = m$task_id[picked],
                        mini_initial_grade = m$grade[picked],
                        material_status = 'pending_independent_review',
                        stringsAsFactors = FALSE)
selection <- selection[order(selection$question_order), ]
write.csv(selection, out, row.names = FALSE, na = '')
write_json(list(selection_sha256 = digest(file = out, algo = 'sha256'),
                mini_scores_sha256 = digest(file = mini_file, algo = 'sha256'),
                key_sha256 = digest(file = key_file, algo = 'sha256'),
                seed = 25011012L, count = 50L, strata = as.list(quotas),
                selection_time_rule = paste('After independent initials and after two',
                                            'technical pilot responses, before inspecting',
                                            'any follow-up answer text or scoring effects.'),
                note = paste('Selection only; no wrong answer or reasoning is approved.',
                             'Do not run controlled branch until materials are reviewed and frozen.')),
           manifest, pretty = TRUE, auto_unbox = TRUE)
cat('Frozen', nrow(selection), 'controlled-target IDs; stimuli remain pending.\n')
