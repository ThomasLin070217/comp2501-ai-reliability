#!/usr/bin/env Rscript

# Read-only R audit of the later four-cell fact rescue. The rescue's Python
# assembly is historical provenance; this script independently checks its
# overlay, denominators and hashes without rewriting it.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
base <- 'Initial_Response_Accuracy_Evaluation/processed'
old_file <- file.path(base, 'fact_reopened_2026-10-07/fact_reopened_responses_1000.csv')
new_dir <- file.path(base, 'fact_last_four_recovered_2026-10-07')
new_file <- file.path(new_dir, 'fact_responses_1000.csv')
review_file <- file.path(new_dir, 'last_four_review.csv')
manifest_file <- file.path(new_dir, 'manifest.json')
out_dir <- 'Night_Audit_2026-10-06/derived/fact_last_four'
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

old <- read.csv(old_file, stringsAsFactors = FALSE, check.names = FALSE,
                na.strings = character())
new <- read.csv(new_file, stringsAsFactors = FALSE, check.names = FALSE,
                na.strings = character())
review <- read.csv(review_file, stringsAsFactors = FALSE, check.names = FALSE,
                   na.strings = character())
manifest <- fromJSON(manifest_file, simplifyVector = FALSE)
stopifnot(nrow(old) == 1000L, nrow(new) == 1000L,
          !anyDuplicated(old$task_id), !anyDuplicated(new$task_id),
          !anyDuplicated(review$task_id), nrow(review) == 4L,
          identical(old$task_id, new$task_id),
          all(names(old) %in% names(new)))

hashes <- manifest$source_and_output_sha256
for (p in names(hashes)) {
  stopifnot(file.exists(p), identical(digest(file = p, algo = 'sha256'), hashes[[p]]))
}
stopifnot(setequal(review$final_sha256,
                   unlist(hashes[grepl('/tasks/.*/final\\.json$', names(hashes))],
                            use.names = FALSE)))

# All baseline metadata and prior grades must survive. The only replaced
# columns are the selected answer/grade/source for exactly the four rescues.
fixed <- setdiff(names(old), c('chosen_source', 'chosen_grade', 'chosen_answer_text'))
for (col in fixed) stopifnot(identical(old[[col]], new[[col]]))
stopifnot(identical(old$chosen_source, new$pre_last_four_source),
          identical(old$chosen_grade, new$pre_last_four_grade),
          identical(old$chosen_answer_text, new$pre_last_four_answer_text))
changed <- which(old$chosen_source != new$chosen_source |
                 old$chosen_grade != new$chosen_grade |
                 old$chosen_answer_text != new$chosen_answer_text)
stopifnot(length(changed) == 4L,
          setequal(new$task_id[changed], review$task_id),
          all(old$chosen_grade[changed] == 'technical_incomplete'))
j <- match(new$task_id[changed], review$task_id)
stopifnot(identical(new$chosen_grade[changed], review$grade[j]),
          identical(new$chosen_source[changed], review$source[j]),
          identical(new$chosen_answer_text[changed], review$answer_text[j]),
          identical(new$reference_answer[changed], review$reference_answer[j]))

scoreable <- c('correct', 'incorrect', 'abstain')
count_view <- function(d, version) {
  do.call(rbind, lapply(c('deepseek', 'minimax'), function(provider) {
    x <- d[d$provider == provider, ]
    stopifnot(nrow(x) == 500L)
    z <- table(factor(x$chosen_grade,
                      levels = c(scoreable, 'technical_incomplete', 'unscorable')))
    data.frame(version = version, provider = provider,
               correct = unname(z['correct']), incorrect = unname(z['incorrect']),
               abstain = unname(z['abstain']),
               technical_incomplete = unname(z['technical_incomplete']),
               unscorable = unname(z['unscorable']),
               stringsAsFactors = FALSE)
  }))
}
counts <- rbind(count_view(old, 'prior_496'), count_view(new, 'supplemented_500'))
counts$scoreable <- counts$correct + counts$incorrect + counts$abstain
counts$error_rate <- counts$incorrect / counts$scoreable
stopifnot(identical(as.integer(counts$scoreable), c(500L, 496L, 500L, 500L)),
          identical(as.integer(counts$incorrect), c(44L, 89L, 44L, 90L)),
          identical(as.integer(counts$abstain), c(33L, 39L, 33L, 42L)),
          all(rowSums(counts[, c('scoreable', 'technical_incomplete', 'unscorable')]) == 500L))
write.csv(counts, file.path(out_dir, 'source_separated_counts.csv'), row.names = FALSE)
write.csv(data.frame(task_id = new$task_id[changed],
                     old_grade = old$chosen_grade[changed],
                     new_grade = new$chosen_grade[changed],
                     new_source = new$chosen_source[changed],
                     stringsAsFactors = FALSE),
          file.path(out_dir, 'four_cell_transitions.csv'), row.names = FALSE)
write_json(list(old_sha256 = digest(file = old_file, algo = 'sha256'),
                new_sha256 = digest(file = new_file, algo = 'sha256'),
                manifest_sha256 = digest(file = manifest_file, algo = 'sha256'),
                review_sha256 = digest(file = review_file, algo = 'sha256'),
                verified_manifest_file_hashes = length(hashes),
                unchanged_cells = nrow(new) - length(changed),
                changed_cells = length(changed),
                comparability = paste('Supplemented MiniMax 500 is mixed-protocol:',
                                      'three cells disabled native search and one',
                                      'also changed the user prompt. Retain prior 496 view.'),
                limitation = 'Four provided fact reference keys were not independently re-researched here.'),
           file.path(out_dir, 'audit.json'), auto_unbox = TRUE, pretty = TRUE)
print(counts, row.names = FALSE)
