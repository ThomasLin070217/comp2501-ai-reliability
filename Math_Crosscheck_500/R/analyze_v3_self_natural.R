#!/usr/bin/env Rscript

# Paired, R-only GSM-Plus v3 self vs natural cross analysis.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
base <- 'Math_Crosscheck_500'
initial_file <- file.path(base, 'collection_v3_minimax/derived/final_scores_500.csv')
donor_file <- file.path(base, 'collection_v3_deepseek/derived/final_scores_500.csv')
score_file <- file.path(base, 'collection_v3_followups/derived/final_scores_992.csv')
out_dir <- file.path(base, 'collection_v3_followups/analysis')
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
m <- read.csv(initial_file, stringsAsFactors = FALSE, check.names = FALSE)
d <- read.csv(donor_file, stringsAsFactors = FALSE, check.names = FALSE)
f <- read.csv(score_file, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(m) == 500L, nrow(d) == 500L, nrow(f) == 992L,
          !anyDuplicated(m$eval_id), !anyDuplicated(d$eval_id),
          !anyDuplicated(f$task_id),
          all(f$condition %in% c('self_check','natural_crosscheck')))
d <- d[match(m$eval_id, d$eval_id), ]
stopifnot(identical(m$eval_id, d$eval_id),
          identical(m$input_text, d$input_text))
eligible <- m$grade %in% c('correct','incorrect','abstention') &
            d$grade %in% c('correct','incorrect','abstention')
stopifnot(sum(eligible) == 496L)
mm <- m[eligible, ]; dd <- d[eligible, ]
self <- f[f$condition == 'self_check', ]
natural <- f[f$condition == 'natural_crosscheck', ]
stopifnot(nrow(self) == 496L, nrow(natural) == 496L,
          setequal(self$eval_id, mm$eval_id), setequal(natural$eval_id, mm$eval_id))
self <- self[match(mm$eval_id, self$eval_id), ]
natural <- natural[match(mm$eval_id, natural$eval_id), ]
stopifnot(identical(mm$eval_id, self$eval_id),
          identical(mm$eval_id, natural$eval_id))

good <- c('correct','incorrect','abstention')
pair <- data.frame(eval_id = mm$eval_id, question_order = mm$question_order,
                   question = mm$input_text, initial_grade = mm$grade,
                   deepseek_initial_grade = dd$grade,
                   self_grade = self$grade, natural_grade = natural$grade,
                   self_task_id = self$task_id,
                   natural_task_id = natural$task_id,
                   stringsAsFactors = FALSE)
pair$common_scorable <- pair$self_grade %in% good & pair$natural_grade %in% good
write.csv(pair, file.path(out_dir, 'paired_all_496.csv'),
          row.names = FALSE, na = '')
common <- pair[pair$common_scorable, ]
write.csv(common, file.path(out_dir, 'paired_common_scorable.csv'),
          row.names = FALSE, na = '')
if (nrow(common) < 1L) stop('No common scorable questions.')

condition <- data.frame(condition = c('initial','self_check','natural_crosscheck'),
                        n = rep(nrow(common), 3L),
                        correct = c(sum(common$initial_grade == 'correct'),
                                    sum(common$self_grade == 'correct'),
                                    sum(common$natural_grade == 'correct')),
                        incorrect = c(sum(common$initial_grade == 'incorrect'),
                                      sum(common$self_grade == 'incorrect'),
                                      sum(common$natural_grade == 'incorrect')),
                        abstention = c(sum(common$initial_grade == 'abstention'),
                                       sum(common$self_grade == 'abstention'),
                                       sum(common$natural_grade == 'abstention')),
                        stringsAsFactors = FALSE)
condition$error_rate <- condition$incorrect / condition$n
condition$noncorrect_rate <- (condition$incorrect + condition$abstention) / condition$n
stopifnot(all(condition$correct + condition$incorrect + condition$abstention == condition$n))
write.csv(condition, file.path(out_dir, 'condition_counts_common.csv'),
          row.names = FALSE)

set.seed(25011010L)
B <- 5000L
index <- replicate(B, sample.int(nrow(common), nrow(common), replace = TRUE))
indicator <- function(col, value = 'incorrect') as.integer(common[[col]] == value)
effect <- function(from, to, outcome = 'incorrect') {
  a <- indicator(from, outcome); b <- indicator(to, outcome)
  delta <- 100 * mean(b - a)
  draw <- 100 * colMeans(matrix((b - a)[index], nrow = nrow(common)))
  data.frame(comparison = paste0(to,'_minus_',from), outcome = outcome,
             n = nrow(common), from_count = sum(a), to_count = sum(b),
             delta_pp = delta,
             ci_low_pp = unname(quantile(draw, 0.025, type = 1)),
             ci_high_pp = unname(quantile(draw, 0.975, type = 1)),
             corrected_or_eliminated = sum(a == 1L & b == 0L),
             new_errors = sum(a == 0L & b == 1L),
             stringsAsFactors = FALSE)
}
effects <- do.call(rbind, list(effect('initial_grade','self_grade'),
                               effect('initial_grade','natural_grade'),
                               effect('self_grade','natural_grade')))
write.csv(effects, file.path(out_dir, 'paired_error_effects.csv'),
          row.names = FALSE)

transition <- function(a, b, label) {
  z <- as.data.frame(table(from = factor(common[[a]], levels = good),
                           to = factor(common[[b]], levels = good)),
                     stringsAsFactors = FALSE)
  z$comparison <- label
  z[z$Freq > 0L, c('comparison','from','to','Freq')]
}
transitions <- rbind(transition('initial_grade','self_grade','initial_to_self'),
                     transition('initial_grade','natural_grade','initial_to_natural'),
                     transition('self_grade','natural_grade','self_to_natural'))
write.csv(transitions, file.path(out_dir, 'transitions_common.csv'),
          row.names = FALSE)

subgroups <- list()
for (name in c('mini_wrong_donor_correct','mini_correct_donor_wrong',
               'both_initially_wrong','both_initially_correct')) {
  idx <- switch(name,
    mini_wrong_donor_correct = common$initial_grade == 'incorrect' &
      common$deepseek_initial_grade == 'correct',
    mini_correct_donor_wrong = common$initial_grade == 'correct' &
      common$deepseek_initial_grade == 'incorrect',
    both_initially_wrong = common$initial_grade == 'incorrect' &
      common$deepseek_initial_grade == 'incorrect',
    both_initially_correct = common$initial_grade == 'correct' &
      common$deepseek_initial_grade == 'correct')
  x <- common[idx, ]
  subgroups[[name]] <- data.frame(subgroup = name, n = nrow(x),
    self_correct = sum(x$self_grade == 'correct'),
    self_wrong = sum(x$self_grade == 'incorrect'),
    self_abstain = sum(x$self_grade == 'abstention'),
    natural_correct = sum(x$natural_grade == 'correct'),
    natural_wrong = sum(x$natural_grade == 'incorrect'),
    natural_abstain = sum(x$natural_grade == 'abstention'),
    stringsAsFactors = FALSE)
}
write.csv(do.call(rbind, subgroups),
          file.path(out_dir, 'donor_subgroups_common.csv'),
          row.names = FALSE)
wrong_donor <- common[common$initial_grade == 'correct' &
                      common$deepseek_initial_grade == 'incorrect', ]
write.csv(wrong_donor, file.path(out_dir, 'actual_wrong_peer_cases.csv'),
          row.names = FALSE, na = '')
write_json(list(initial_sha256 = digest(file = initial_file, algo = 'sha256'),
                donor_sha256 = digest(file = donor_file, algo = 'sha256'),
                followup_scores_sha256 = digest(file = score_file, algo = 'sha256'),
                planned_matched = 496L, common_scorable = nrow(common),
                bootstrap_draws = B, bootstrap_seed = 25011010L,
                note = paste('Question-level paired bootstrap on selected GSM-Plus bank.',
                             'A confidence interval does not cure reference ambiguity or',
                             'make the sample representative of all AI use.')),
           file.path(out_dir, 'analysis_manifest.json'),
           auto_unbox = TRUE, pretty = TRUE)
print(condition, row.names = FALSE)
print(effects, row.names = FALSE)
