#!/usr/bin/env Rscript
# Recompute the current two-model study's natural matched comparison from
# selected response-level semantic grades. This leaves the frozen analyses intact.
library(jsonlite)

root <- 'Two_Model_Collection'
paths <- list(
  facts = file.path(root, 'facts/recovery/derived/reports/semantic_sensitivity_records.csv'),
  math = file.path(root, 'math/recovery/derived/reports/semantic_final_responses.csv')
)
expected <- list(
  facts = c(responses = 1591, correct = 1274, incorrect = 215, abstain = 101,
            unscorable = 1, pairs = 394, questions = 100,
            self = 0.2325, cross = 0.05),
  math = c(responses = 732, correct = 677, incorrect = 50, abstain = 0,
           unscorable = 5, pairs = 164, questions = 41,
           self = 0.103658536585366, cross = 0.0548780487804878)
)

audit_domain <- function(domain) {
  x <- read.csv(paths[[domain]], stringsAsFactors = FALSE)
  grade_col <- if (domain == 'facts') 'semantic_grade' else 'final_semantic_grade'
  x$final_label <- x[[grade_col]]
  stopifnot(!anyDuplicated(x$id), all(x$final_label %in%
              c('correct', 'incorrect', 'abstain', 'unscorable')))
  counts <- table(factor(x$final_label,
                         levels = c('correct', 'incorrect', 'abstain', 'unscorable')))
  e <- expected[[domain]]
  stopifnot(nrow(x) == e[['responses']],
            identical(as.integer(counts), as.integer(e[names(counts)])))

  eligible <- x[x$condition %in% c('self_check', 'A0_AI') &
                  x$final_label != 'unscorable',
                c('id', 'question_id', 'provider', 'repeat_id', 'condition',
                  'baseline_id', 'final_label')]
  self <- eligible[eligible$condition == 'self_check', ]
  cross <- eligible[eligible$condition == 'A0_AI', ]
  key <- c('question_id', 'provider', 'repeat_id')
  p <- merge(self, cross, by = key, suffixes = c('_self', '_cross'))
  stopifnot(nrow(p) == e[['pairs']],
            length(unique(p$question_id)) == e[['questions']],
            all(p$baseline_id_self == p$baseline_id_cross))
  p$self_error <- as.integer(p$final_label_self == 'incorrect')
  p$cross_error <- as.integer(p$final_label_cross == 'incorrect')

  # Mean repeats within question/model, questions within model, then models equally.
  question_means <- aggregate(p[, c('self_error', 'cross_error')],
                              by = p[c('provider', 'question_id')], FUN = mean)
  model_means <- aggregate(question_means[, c('self_error', 'cross_error')],
                           by = question_means['provider'], FUN = mean)
  stopifnot(nrow(model_means) == 2,
            all(sort(model_means$provider) == c('deepseek', 'minimax')))
  overall <- colMeans(model_means[, c('self_error', 'cross_error')])
  stopifnot(isTRUE(all.equal(unname(overall[['self_error']]),
                             unname(e[['self']]), tolerance = 1e-12)),
            isTRUE(all.equal(unname(overall[['cross_error']]),
                             unname(e[['cross']]), tolerance = 1e-12)))
  list(domain = domain, responses = nrow(x), grade_counts = as.list(counts),
       matched_pairs = nrow(p), independent_questions = length(unique(p$question_id)),
       receiving_model_means = lapply(seq_len(nrow(model_means)), function(i)
         list(model = model_means$provider[i], self_error = model_means$self_error[i],
              cross_error = model_means$cross_error[i])),
       equal_model_means = list(self_error = unname(overall[['self_error']]),
                                cross_error = unname(overall[['cross_error']]),
                                difference = unname(overall[['cross_error']] - overall[['self_error']])))
}

results <- lapply(names(paths), audit_domain)
names(results) <- names(paths)
followup <- read.csv('Human_Challenge_Followup/reports/graded.csv',
                     stringsAsFactors = FALSE)
followup_audit <- fromJSON('Human_Challenge_Followup/reports/full_audit.json',
                           simplifyVector = TRUE)
stopifnot(nrow(followup) == 156, !anyDuplicated(followup$id),
          followup_audit$status == 'passed',
          followup_audit$final_grades_agree == 156,
          followup_audit$correct_baselines_independent == 78)
out <- list(status = 'passed', scope = paste(
  'Current two-model completed-data semantic overlay and separately designed',
  'human-challenge follow-up; historical pilot cohorts are not pooled.'),
  two_model = results, two_model_selected_responses = sum(vapply(results,
    function(z) z$responses, numeric(1))),
  two_model_semantically_scorable = sum(vapply(results,
    function(z) z$responses - z$grade_counts$unscorable, numeric(1))),
  human_challenge_responses = nrow(followup),
  human_challenge_full_final_grade_agreement = followup_audit$final_grades_agree)
write_json(out, 'docs/cross_experiment_audit_2026-10-05.json',
           auto_unbox = TRUE, pretty = TRUE)
cat('Cross-experiment audit passed:', out$two_model_selected_responses,
    'two-model selected responses and', out$human_challenge_responses,
    'human-challenge follow-ups.\n')
