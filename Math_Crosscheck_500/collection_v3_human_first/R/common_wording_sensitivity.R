#!/usr/bin/env Rscript

# A shared post-hoc exclusion list for both providers; primary scores unchanged.
d <- 'Math_Crosscheck_500/collection_v3_human_first/derived'
files <- c(DeepSeek = file.path(d, 'deepseek_first_prompt_pairs_50.csv'),
           MiniMax = file.path(d, 'minimax_first_prompt_pairs_50.csv'))
ambiguous_orders <- c(86L, 160L, 252L)
rows <- lapply(names(files), function(provider) {
  x <- read.csv(files[[provider]], stringsAsFactors = FALSE)
  stopifnot(nrow(x) == 50L, !anyDuplicated(x$eval_id),
            all(ambiguous_orders %in% x$question_order))
  x <- x[!x$question_order %in% ambiguous_orders, ]
  n <- as.integer(x$neutral_grade == 'incorrect')
  t <- as.integer(x$misconception_grade == 'incorrect')
  change <- t - n
  data.frame(provider, view = 'posthoc_common_exclude_orders_86_160_252',
             pairs = nrow(x), neutral_wrong = sum(n),
             false_premise_wrong = sum(t),
             difference_pp = 100 * mean(change),
             neutral_correct_to_wrong = sum(change == 1L),
             neutral_wrong_to_nonwrong = sum(change == -1L),
             wrong_target_adopted = sum(x$wrong_target_adopted),
             exact_discordance_p = if (all(change == 0L)) 1 else
               binom.test(sum(change == 1L), sum(change != 0L), .5)$p.value,
             stringsAsFactors = FALSE)
})
out <- do.call(rbind, rows)
stopifnot(identical(out$pairs, c(47L,47L)))
write.csv(out, file.path(d, 'common_wording_sensitivity_47_pairs.csv'),
          row.names = FALSE)
print(out, row.names = FALSE)
