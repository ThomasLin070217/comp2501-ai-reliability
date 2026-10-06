#!/usr/bin/env Rscript

# Post-hoc wording sensitivity; never overwrites the frozen-key primary results.
suppressPackageStartupMessages({library(digest); library(jsonlite)})
root <- 'Math_Crosscheck_500/collection_v3_followups/analysis'
input <- file.path(root, 'paired_common_scorable.csv')
x <- read.csv(input, stringsAsFactors = FALSE)
stopifnot(nrow(x) == 495L, !anyDuplicated(x$eval_id))
cases <- list(
  frozen_key_all = integer(0),
  omit_rate_interpretation_12 = 12L,
  omit_four_wording_cases = c(12L, 293L, 360L, 383L)
)
rows <- lapply(names(cases), function(name) {
  excluded <- cases[[name]]
  stopifnot(all(excluded %in% x$question_order))
  y <- x[!x$question_order %in% excluded, ]
  n <- nrow(y)
  a <- as.integer(y$self_grade == 'incorrect')
  b <- as.integer(y$natural_grade == 'incorrect')
  set.seed(25011010L)
  index <- replicate(5000L, sample.int(n, n, replace = TRUE))
  draw <- 100 * colMeans(matrix((b - a)[index], nrow = n))
  data.frame(scenario = name, n = n,
             omitted_question_orders = paste(excluded, collapse = ';'),
             initial_wrong = sum(y$initial_grade == 'incorrect'),
             self_wrong = sum(a), natural_wrong = sum(b),
             self_rate = mean(a), natural_rate = mean(b),
             cross_minus_self_pp = 100 * mean(b - a),
             ci_low_pp = unname(quantile(draw, .025, type = 1)),
             ci_high_pp = unname(quantile(draw, .975, type = 1)),
             corrected_or_eliminated = sum(a == 1L & b == 0L),
             new_errors = sum(a == 0L & b == 1L))
})
out <- do.call(rbind, rows)
stopifnot(out$n[[1]] == 495L, out$self_wrong[[1]] == 9L,
          out$natural_wrong[[1]] == 4L)
write.csv(out, file.path(root, 'posthoc_wording_sensitivity.csv'), row.names = FALSE)
write_json(list(input_sha256 = digest(file = input, algo = 'sha256'),
                bootstrap_draws = 5000L, seed = 25011010L,
                status = 'post_hoc_non_preregistered',
                note = paste('These exclusions flag plausible alternative readings,',
                             'not corrections to the frozen answer key.')),
           file.path(root, 'posthoc_wording_sensitivity_manifest.json'),
           pretty = TRUE, auto_unbox = TRUE)
print(out, row.names = FALSE)
