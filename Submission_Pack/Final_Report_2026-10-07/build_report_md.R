#!/usr/bin/env Rscript

# Validate the source tables in R and lay out the English synthesis for Pandoc.
# Pandoc/tectonic only typeset this R-validated Markdown; no statistics run there.
suppressPackageStartupMessages(library(jsonlite))
public_inventory <- 'Night_Audit_2026-10-06/derived/current_evidence_inventory.csv'
math_pairs <- 'Math_Crosscheck_500/collection_v3_followups/analysis/paired_common_scorable.csv'
deepseek <- 'Math_Crosscheck_500/collection_v3_human_first/derived/deepseek_first_prompt_pairs_50.csv'
minimax <- 'Math_Crosscheck_500/collection_v3_human_first/derived/minimax_first_prompt_pairs_50.csv'
controlled <- 'Math_Crosscheck_500/collection_v3_controlled/derived/controlled_scores_50.csv'
private_summary <- Sys.getenv('COMP2501_PRIVATE_MATH_SUMMARY',
  '../Math_Benchmark_500_Private_2026-10-06/final_results_2026-10-07/r_release_v2/final_summary_v1.json')
i <- read.csv(public_inventory, stringsAsFactors = FALSE)
m <- read.csv(math_pairs, stringsAsFactors = FALSE)
d <- read.csv(deepseek, stringsAsFactors = FALSE)
h <- read.csv(minimax, stringsAsFactors = FALSE)
c50 <- read.csv(controlled, stringsAsFactors = FALSE)
p <- fromJSON(private_summary)
latest_m3m4 <- fromJSON('../Math_Benchmark_500_Private_2026-10-06/natural_crosscheck_2026-10-07/analysis/m3_m4_latest_summary.json')
latest_cross <- fromJSON('../Math_Benchmark_500_Private_2026-10-06/natural_crosscheck_2026-10-07/analysis/conditional_crosscheck_summary_v1.json')
stopifnot(nrow(i) == 15L, nrow(m) == 495L,
          sum(m$initial_grade == 'incorrect') == 17L,
          sum(m$self_grade == 'incorrect') == 9L,
          sum(m$natural_grade == 'incorrect') == 4L,
          nrow(d) == 50L, nrow(h) == 50L, nrow(c50) == 50L,
          sum(d$neutral_grade == 'incorrect') == 0L,
          sum(d$misconception_grade == 'incorrect') == 3L,
          sum(h$neutral_grade == 'incorrect') == 1L,
          sum(h$misconception_grade == 'incorrect') == 5L,
          sum(c50$review_grade == 'incorrect') == 0L,
          p$M1$scoreable$scoreable == 493L,
          p$M1$grades$incorrect == 70L,
          p$M2$main$scoreable$scoreable == 488L,
          p$M2$main$scoreable$errors == 42L,
          p$M3$scoreable$scoreable == 69L,
          p$M3$grades$incorrect == 1L,
          p$M4$main$scoreable$scoreable == 68L,
          p$M4$main$scoreable$errors == 11L,
          latest_m3m4$m3$correct == 69L,
          latest_m3m4$m3$incorrect == 0L,
          latest_m3m4$m4$incorrect == 10L,
          latest_m3m4$m4_wrong_target_adopted == 10L,
          latest_cross$m2_c1_paired_n == 63L,
          latest_cross$m2_correct_on_pair == 31L,
          latest_cross$c1_correct_on_pair == 55L)

source <- 'docs/comp2501-evidence-synthesis-2026-10-07.md'
x <- readLines(source, warn = FALSE)
stopifnot(grepl('^# Can We Trust AI More After Cross-Checking\\?', x[1L]),
          any(grepl('^## Related work', x)))
x <- x[-seq_len(4L)]
github <- 'https://github.com/ThomasLin070217/comp2501-ai-reliability/blob/main/'
x <- gsub(']\\(\\.\\./', paste0('](', github), x)
x <- gsub(']\\(gsmplus-v3-results-card-2026-10-07.md\\)',
          paste0('](', github, 'docs/gsmplus-v3-results-card-2026-10-07.md)'), x)
insert_before <- function(lines, heading, addition) {
  where <- which(grepl(heading, lines))
  stopifnot(length(where) == 1L)
  append(lines, addition, after = where - 1L)
}
x <- insert_before(x, '^### 2\\. Which double-checking method', c(
  '',
  '![](../../Math_Crosscheck_500/collection_v3_followups/analysis/figures/v3_wrong_answer_rates.png)',
  '',
  '*Figure 1. The correct answer and an explicit abstention are both nonwrong; these 495 matched questions have no explicit abstentions.*',
  ''))
x <- insert_before(x, '^## Presentation-safe conclusion', c(
  '',
  '![](../../Math_Crosscheck_500/collection_v3_human_first/analysis/figures/first_prompt_wrong_answer_rates.png)',
  '',
  '*Figure 2. Each model received 50 neutral and 50 false-premise independent first prompts on the same selected questions. The bars show descriptive rates, not a universal effect.*',
  ''))

header <- c('---',
  'title: "Can We Trust AI More After Cross-Checking?"',
  'subtitle: "COMP2501 evidence report"',
  'author: "LINYUNIAN and PAN ZHENGYU"',
  'date: "7 October 2026"',
  'geometry: margin=0.62in',
  'fontsize: 10pt',
  'colorlinks: true',
  'urlcolor: blue',
  '---', '',
  '> This report is a presentation companion. The course handout requires an in-class presentation and proposal; it does not separately require this PDF. Public source rows and R scripts are linked below. The revised 500-question mathematics bank contains user-local material, so only its R-audited aggregate results are included.', '')
out <- 'Submission_Pack/Final_Report_2026-10-07/report.md'
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
writeLines(c(header, x), out, useBytes = TRUE)
cat(sprintf('Wrote %s after R validation of public/private source counts.\n', out))
