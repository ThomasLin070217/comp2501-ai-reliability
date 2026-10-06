#!/usr/bin/env Rscript

# Adjudicate DeepSeek GSM-Plus v3 initial answers without altering raw records.
# The deterministic numeric screen is checked against every discordant response;
# a fixed 60-item sample of screen-positive replies was read in full.
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(digest))
base <- 'Math_Crosscheck_500/collection_v3_deepseek'
input <- file.path(base, 'derived/semantic_review_queue_500.csv')
out_dir <- file.path(base, 'derived')
d <- read.csv(input, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(d) == 500L, !anyDuplicated(d$eval_id),
          all(d$status == 'ok'), all(d$finish_reason == 'end_turn'),
          identical(sort(d$question_order), 1:500))

discordant <- d$question_order[d$screen_status == 'last_number_differs_key']
stopifnot(length(discordant) == 43L,
          setequal(discordant, c(41,12,72,78,99,20,7,452,355,229,445,105,
                                182,257,177,406,425,162,248,224,124,125,
                                244,386,176,336,285,377,101,467,493,418,
                                427,469,446,305,106,283,116,281,169,455,394)))
stopifnot(identical(sort(d$question_order[d$screen_status == 'prompt_ambiguous']),
                    c(375L,460L)))

# Audit sample is fixed before looking at its content; 60/455 were inspected.
set.seed(20261007)
positive <- d[d$screen_status == 'last_number_matches_key', ]
sampled_order <- positive$question_order[sample(nrow(positive), 60L)]
stopifnot(length(sampled_order) == 60L, !anyDuplicated(sampled_order))

grade <- rep('correct', nrow(d))
grade[d$question_order %in% c(12L,355L)] <- 'incorrect'
grade[d$question_order %in% c(375L,460L)] <- 'unscorable_prompt_ambiguous'
method <- ifelse(d$screen_status == 'last_number_matches_key',
                 'numeric-final-screen; fixed 60/455 spot audit',
                 'full response inspected after screen/key discordance')
method[d$question_order %in% c(375L,460L)] <- 'prompt ambiguity already recorded in MiniMax v3 review'
note <- rep('', nrow(d))
note[d$question_order == 12L] <- paste(
  'Model answered 900 by applying 30% to the first $1000 and 40% above it;',
  'frozen source key is 450. Wording also permits a 30%-all-sales plus 10%-excess reading;',
  'report a post-hoc ambiguity-exclusion sensitivity.')
note[d$question_order == 355L] <-
  'Model answered 240 by counting 100 trees as flowers; only 90 geraniums plus 50 petunias are flowers.'
note[d$question_order == 427L] <-
  'Primary answer is correct 92; later 532.38 is explicitly an alternative compound-growth scenario.'
note[d$question_order %in% c(375L,460L)] <-
  'Question wording has two defensible interpretations; excluded under the existing v3 rubric.'

result <- d[, c('task_id','eval_id','question_order','batch','provider','status',
                 'finish_reason','input_text','model_response','search_calls',
                 'original_reference_answer','reference_answer_used',
                 'last_numeric_candidate','screen_status')]
result$grade <- grade
result$review_method <- method
result$spot_audited <- d$question_order %in% sampled_order
result$grade_evidence <- note
write.csv(result, file.path(out_dir, 'final_scores_500.csv'), row.names = FALSE, na = '')
write.csv(result[result$spot_audited, c('eval_id','question_order','model_response',
                                       'reference_answer_used','grade')],
          file.path(out_dir, 'screen_positive_spot_audit_60.csv'),
          row.names = FALSE, na = '')
write.csv(result[d$screen_status != 'last_number_matches_key', ],
          file.path(out_dir, 'discordance_adjudication_45.csv'),
          row.names = FALSE, na = '')
summary <- as.data.frame(table(grade = result$grade), stringsAsFactors = FALSE)
write.csv(summary, file.path(out_dir, 'final_grade_counts.csv'), row.names = FALSE)
manifest <- list(input_sha256 = digest(file = input, algo = 'sha256'),
                 output_sha256 = digest(file = file.path(out_dir, 'final_scores_500.csv'), algo = 'sha256'),
                 grade_counts = as.list(table(result$grade)),
                 screen_positive = nrow(positive), sampled_positive = length(sampled_order),
                 reviewed_discordances = sum(d$screen_status != 'last_number_matches_key'),
                 post_hoc_ambiguity_sensitivity_order = 12L,
                 note = paste('Numerical screen is not a proof of every explanation.',
                              'The primary grade follows the frozen key; order 12 is a sensitivity exclusion.'))
write_json(manifest, file.path(out_dir, 'adjudication_manifest.json'),
           pretty = TRUE, auto_unbox = TRUE)
print(summary, row.names = FALSE)
