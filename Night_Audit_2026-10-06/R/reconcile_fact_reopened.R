#!/usr/bin/env Rscript

# Read-only reconciliation of the 6 Oct frozen and 7 Oct reopened fact views.
# Does not alter either source snapshot or re-grade any model answer.
suppressPackageStartupMessages({
  library(jsonlite)
  library(digest)
})

old_path <- 'Initial_Response_Accuracy_Evaluation/processed/fact_frozen_2026-10-06/fact_frozen_responses_1000.csv'
new_dir <- 'Initial_Response_Accuracy_Evaluation/processed/fact_reopened_2026-10-07'
new_path <- file.path(new_dir, 'fact_reopened_responses_1000.csv')
manifest_path <- file.path(new_dir, 'reopened_manifest.json')
out_dir <- 'Night_Audit_2026-10-06/derived/fact_reopened'
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

old <- read.csv(old_path, stringsAsFactors = FALSE, check.names = FALSE)
new <- read.csv(new_path, stringsAsFactors = FALSE, check.names = FALSE)
manifest <- fromJSON(manifest_path, simplifyVector = FALSE)
stopifnot(nrow(old) == 1000L, nrow(new) == 1000L,
          !anyDuplicated(old$task_id), !anyDuplicated(new$task_id),
          setequal(old$task_id, new$task_id),
          length(unique(old$eval_id)) == 500L,
          length(unique(new$eval_id)) == 500L)
new <- new[match(old$task_id, new$task_id), , drop = FALSE]
stopifnot(identical(old$task_id, new$task_id),
          identical(old$eval_id, new$eval_id),
          identical(old$provider, new$provider),
          identical(old$question_text, new$question_text),
          identical(old$reference_answer, new$reference_answer),
          identical(old$chosen_grade, new$frozen_grade),
          identical(old$chosen_answer_text, new$frozen_answer_text),
          identical(old$chosen_source, new$frozen_source))

recorded <- manifest$source_and_output_sha256
paths <- names(recorded)
stopifnot(length(paths) > 0L, all(file.exists(paths)))
hashes <- vapply(paths, function(p) digest(file = p, algo = 'sha256'), character(1))
expected <- vapply(recorded, as.character, character(1))
stopifnot(identical(unname(hashes), unname(expected)))

grade_levels <- c('correct', 'incorrect', 'abstain',
                  'unscorable', 'technical_incomplete')
stopifnot(all(old$chosen_grade %in% grade_levels),
          all(new$chosen_grade %in% grade_levels))
old_scored <- old$chosen_grade %in% grade_levels[1:3]
new_scored <- new$chosen_grade %in% grade_levels[1:3]
stopifnot(sum(old_scored) == 970L, sum(new_scored) == 996L,
          all(new$chosen_grade[old_scored] == old$chosen_grade[old_scored]),
          all(new$chosen_answer_text[old_scored] == old$chosen_answer_text[old_scored]))
changed <- which(old$chosen_grade != new$chosen_grade |
                 old$chosen_answer_text != new$chosen_answer_text)
newly_scoreable <- which(!old_scored & new_scored)
stopifnot(length(changed) == 30L, length(newly_scoreable) == 26L,
          all(!old_scored[changed]),
          all(newly_scoreable %in% changed))
stopifnot(all(new$chosen_source[changed] %in%
                c('hku_reopened_pass1', 'hku_reopened_pass2_4096')))
stopifnot(sum(new$provider == 'deepseek') == 500L,
          sum(new$provider == 'minimax') == 500L,
          sum(new$provider == 'minimax' & !new_scored) == 4L)

summary <- as.data.frame(table(provider = new$provider,
                               grade = new$chosen_grade),
                         stringsAsFactors = FALSE)
summary <- summary[summary$Freq > 0L, , drop = FALSE]
coverage <- aggregate(Freq ~ provider, summary[
  summary$grade %in% grade_levels[1:3], , drop = FALSE], sum)
names(coverage)[2] <- 'scoreable_n'
summary <- merge(summary, coverage, by = 'provider', all.x = TRUE)
summary$error_rate <- ifelse(summary$grade == 'incorrect',
                             summary$Freq / summary$scoreable_n, NA_real_)
write.csv(summary, file.path(out_dir, 'score_summary.csv'),
          row.names = FALSE, na = '')

transitions <- as.data.frame(table(provider = new$provider,
                                   frozen_grade = old$chosen_grade,
                                   reopened_grade = new$chosen_grade),
                             stringsAsFactors = FALSE)
transitions <- transitions[transitions$Freq > 0L, , drop = FALSE]
write.csv(transitions, file.path(out_dir, 'grade_transitions.csv'),
          row.names = FALSE)
sources <- as.data.frame(table(provider = new$provider,
                               selected_source = new$chosen_source,
                               grade = new$chosen_grade),
                         stringsAsFactors = FALSE)
sources <- sources[sources$Freq > 0L, , drop = FALSE]
write.csv(sources, file.path(out_dir, 'selected_sources.csv'),
          row.names = FALSE)

write_json(list(
  audit_kind = 'read_only_reconciliation_no_regrading',
  frozen_sha256 = digest(file = old_path, algo = 'sha256'),
  reopened_sha256 = digest(file = new_path, algo = 'sha256'),
  source_manifest_sha256 = digest(file = manifest_path, algo = 'sha256'),
  manifest_referenced_files_verified = length(paths),
  cells = nrow(new),
  unique_questions = length(unique(new$eval_id)),
  frozen_scoreable = sum(old_scored),
  reopened_scoreable = sum(new_scored),
  reopened_task_cells = length(changed),
  newly_scoreable = length(newly_scoreable),
  remaining_minimax_technical = sum(new$provider == 'minimax' & !new_scored),
  selected_reopened_task_ids = new$task_id[changed],
  selected_newly_scoreable_task_ids = new$task_id[newly_scoreable],
  caveat = paste('Preserves original semantic grades and route provenance.',
                'Does not independently recheck every fact answer or reference key.',
                'The reopened view contains earlier official-route supplements as well as HKU-route recoveries.')
), file.path(out_dir, 'audit.json'), pretty = TRUE, auto_unbox = TRUE)

print(summary, row.names = FALSE)
cat('Reopened task cells:', length(changed),
    '; newly scoreable:', length(newly_scoreable), '\n')
