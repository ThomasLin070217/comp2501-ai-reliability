#!/usr/bin/env Rscript

# Paired uncertainty for the already adjudicated DeepSeek fresh-first-prompt arm.
# Describes this selected 50-question set; it does not generalize to all math.
suppressPackageStartupMessages(library(digest))
base <- 'Math_Crosscheck_500/collection_v3_human_first'
input <- file.path(base, 'derived/deepseek_first_prompt_pairs_50.csv')
out <- file.path(base, 'derived/deepseek_first_prompt_paired_uncertainty.csv')
d <- read.csv(input, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(d) == 50L, !anyDuplicated(d$eval_id),
          all(d$neutral_grade %in% c('correct', 'incorrect', 'abstention')),
          all(d$misconception_grade %in% c('correct', 'incorrect', 'abstention')),
          all(!is.na(d$posthoc_question_ambiguity)))

summarize <- function(x, label) {
  n <- nrow(x)
  n_wrong <- x$neutral_grade == 'incorrect'
  m_wrong <- x$misconception_grade == 'incorrect'
  induced <- sum(!n_wrong & m_wrong)
  reversed <- sum(n_wrong & !m_wrong)
  difference <- mean(as.integer(m_wrong) - as.integer(n_wrong))
  set.seed(25011018L)
  boot <- replicate(10000L, {
    i <- sample.int(n, n, replace = TRUE)
    mean(as.integer(m_wrong[i]) - as.integer(n_wrong[i]))
  })
  p_exact <- if (induced + reversed > 0L) {
    binom.test(induced, induced + reversed, p = 0.5)$p.value
  } else 1
  data.frame(
    analysis = label, pairs = n,
    neutral_wrong = sum(n_wrong), misconception_wrong = sum(m_wrong),
    induced_wrong = induced, reversed_wrong = reversed,
    neutral_abstain = sum(x$neutral_grade == 'abstention'),
    misconception_abstain = sum(x$misconception_grade == 'abstention'),
    paired_error_difference = difference,
    question_bootstrap_low = unname(quantile(boot, 0.025)),
    question_bootstrap_high = unname(quantile(boot, 0.975)),
    discordance_exact_two_sided_p = p_exact,
    source_sha256 = digest(file = input, algo = 'sha256'),
    note = paste('Previously-correct selected set; one fresh completion per condition.',
                 'Post-hoc ambiguity exclusion is sensitivity only.',
                 'Bootstrap interval describes question resampling within this selected set.'),
    stringsAsFactors = FALSE)
}

result <- rbind(summarize(d, 'frozen_key_all_50'),
                summarize(d[!d$posthoc_question_ambiguity, , drop = FALSE],
                          'posthoc_exclude_ambiguity_48'))
stopifnot(result$pairs[1] == 50L, result$pairs[2] == 48L,
          result$neutral_wrong[1] == 0L,
          result$misconception_wrong[1] == 3L,
          result$neutral_wrong[2] == 0L,
          result$misconception_wrong[2] == 2L)
write.csv(result, out, row.names = FALSE)
print(result[, 1:12], row.names = FALSE)
