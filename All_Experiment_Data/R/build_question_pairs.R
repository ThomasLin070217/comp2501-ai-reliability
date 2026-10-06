#!/usr/bin/env Rscript
# Build explicit matched contrasts for the four RQs from the R-selected rows.
# Only pairs with two scorable final answers enter the comparison CSV.

input <- 'All_Experiment_Data/question_relevant_responses.csv'
output <- 'All_Experiment_Data/question_comparison_pairs.csv'
audit_path <- 'All_Experiment_Data/question_pair_audit.json'
x <- read.csv(input, stringsAsFactors = FALSE, na.strings = '',
              fileEncoding = 'UTF-8', check.names = FALSE)
stopifnot(nrow(x) == 12694L, !anyDuplicated(x$observation_id))

specs <- list(
  c('peer_misleading_main', 'initial_vs_neutral', 'baseline', 'C0', 'RQ1,RQ2'),
  c('peer_misleading_main', 'neutral_vs_wrong_answer', 'C0', 'C1', 'RQ2,RQ3'),
  c('peer_misleading_main', 'neutral_vs_wrong_reason', 'C0', 'C2', 'RQ2,RQ3'),
  c('peer_misleading_main', 'wrong_reason_vs_structured', 'C2', 'C3', 'RQ2,RQ3'),
  c('peer_misleading_main', 'correct_advice_vs_structured', 'C4', 'C5', 'RQ2'),
  c('math_supplement_supplementary', 'initial_vs_neutral', 'baseline', 'C0', 'RQ1,RQ2'),
  c('math_supplement_supplementary', 'neutral_vs_wrong_answer', 'C0', 'C1', 'RQ2,RQ3'),
  c('math_supplement_supplementary', 'neutral_vs_wrong_reason', 'C0', 'C2', 'RQ2,RQ3'),
  c('math_supplement_supplementary', 'wrong_reason_vs_structured', 'C2', 'C3', 'RQ2,RQ3'),
  c('math_supplement_supplementary', 'correct_advice_vs_structured', 'C4', 'C5', 'RQ2'),
  c('natural_crosscheck', 'initial_vs_self', 'N0', 'N1', 'RQ1,RQ2'),
  c('natural_crosscheck', 'self_vs_natural_peer', 'N1', 'N2', 'RQ1,RQ2,RQ3'),
  c('natural_crosscheck', 'natural_peer_vs_structured', 'N2', 'N3', 'RQ2,RQ3'),
  c('followup_validation', 'initial_vs_self', 'N0', 'N1', 'RQ1,RQ2'),
  c('followup_validation', 'self_vs_natural_peer', 'N1', 'N2', 'RQ1,RQ2,RQ3'),
  c('followup_validation', 'natural_peer_vs_structured', 'N2', 'N3', 'RQ2,RQ3'),
  c('followup_validation', 'wrong_advice_vs_structured', 'W0', 'W1', 'RQ2,RQ3'),
  c('followup_validation', 'no_reminder_vs_reminder', 'W1', 'W2', 'RQ2'),
  c('two_model_facts', 'initial_vs_self', 'neutral_initial', 'self_check', 'RQ1,RQ2'),
  c('two_model_facts', 'self_vs_natural_peer', 'self_check', 'A0_AI', 'RQ1,RQ2,RQ3'),
  c('two_model_facts', 'initial_vs_natural_peer', 'neutral_initial', 'A0_AI', 'RQ1'),
  c('two_model_facts', 'neutral_vs_false_premise_initial', 'neutral_initial',
    'misconception_initial', 'RQ4'),
  c('two_model_facts', 'ai_label_vs_human_label', 'A0_AI', 'A0_Human', 'RQ2,RQ4'),
  c('two_model_facts', 'neutral_ai_vs_misconception_ai', 'A0_AI', 'A1_AI', 'RQ4'),
  c('two_model_facts', 'neutral_human_vs_misconception_human', 'A0_Human',
    'A1_Human', 'RQ4'),
  c('two_model_facts', 'misconception_ai_vs_human_label', 'A1_AI', 'A1_Human', 'RQ4'),
  c('two_model_math', 'initial_vs_self', 'neutral_initial', 'self_check', 'RQ1,RQ2'),
  c('two_model_math', 'self_vs_natural_peer', 'self_check', 'A0_AI', 'RQ1,RQ2,RQ3'),
  c('two_model_math', 'initial_vs_natural_peer', 'neutral_initial', 'A0_AI', 'RQ1'),
  c('two_model_math', 'neutral_vs_false_premise_initial', 'neutral_initial',
    'misconception_initial', 'RQ4'),
  c('two_model_math', 'ai_label_vs_human_label', 'A0_AI', 'A0_Human', 'RQ2,RQ4'),
  c('two_model_math', 'neutral_ai_vs_misconception_ai', 'A0_AI', 'A1_AI', 'RQ4'),
  c('two_model_math', 'neutral_human_vs_misconception_human', 'A0_Human',
    'A1_Human', 'RQ4'),
  c('two_model_math', 'misconception_ai_vs_human_label', 'A1_AI', 'A1_Human', 'RQ4'),
  c('human_challenge_followup', 'neutral_vs_false_human_challenge', 'neutral',
    'human_challenge', 'RQ4')
)

stopifnot(!anyDuplicated(x$source_record_id))
lookup_grade <- setNames(x$grade, x$source_record_id)
lookup <- function(ids) {
  ans <- unname(lookup_grade[ids])
  ans[is.na(ids)] <- NA_character_
  ans
}

results <- vector('list', length(specs))
audit <- vector('list', length(specs))
for (i in seq_along(specs)) {
  z <- specs[[i]]
  study <- z[1]; contrast <- z[2]; left_name <- z[3]; right_name <- z[4]
  a <- x[x$experiment == study & x$condition == left_name, , drop = FALSE]
  b <- x[x$experiment == study & x$condition == right_name, , drop = FALSE]
  stopifnot(!anyDuplicated(a$receiver_pair_key),
            !anyDuplicated(b$receiver_pair_key))
  scheduled <- intersect(a$receiver_pair_key, b$receiver_pair_key)
  aa <- a[match(scheduled, a$receiver_pair_key), , drop = FALSE]
  bb <- b[match(scheduled, b$receiver_pair_key), , drop = FALSE]
  valid <- aa$scorable_answer & bb$scorable_answer
  stopifnot(!anyNA(valid))
  aa <- aa[valid, , drop = FALSE]
  bb <- bb[valid, , drop = FALSE]
  p <- data.frame(
    experiment = study, evidence_group = aa$evidence_group,
    research_questions = z[5], comparison_id = contrast,
    domain = aa$domain, question_id = aa$question_id,
    receiving_model = aa$provider, repeat_id = aa$repeat_id,
    receiver_pair_key = aa$receiver_pair_key,
    left_condition = left_name, right_condition = right_name,
    left_observation_id = aa$observation_id,
    right_observation_id = bb$observation_id,
    left_grade = aa$grade, right_grade = bb$grade,
    left_wrong = aa$is_wrong, right_wrong = bb$is_wrong,
    left_abstain = aa$is_abstain, right_abstain = bb$is_abstain,
    left_answer = aa$final_answer, right_answer = bb$final_answer,
    receiver_initial_grade = lookup(bb$baseline_id),
    left_donor_grade = lookup(aa$donor_response_id),
    right_donor_grade = lookup(bb$donor_response_id),
    left_donor_id = aa$donor_response_id,
    right_donor_id = bb$donor_response_id,
    stringsAsFactors = FALSE)
  # The direct-human supplement has an earlier, selected correct initial answer.
  if (study == 'human_challenge_followup')
    stopifnot(all(p$receiver_initial_grade == 'correct'))
  results[[i]] <- p
  audit[[i]] <- list(study = study, comparison = contrast,
                     scheduled_pairs = length(scheduled),
                     scorable_pairs = nrow(p),
                     excluded_pairs = length(scheduled) - nrow(p))
}

pairs <- do.call(rbind, results)
rownames(pairs) <- NULL
stopifnot(!anyDuplicated(paste(pairs$experiment, pairs$comparison_id,
                               pairs$receiver_pair_key, sep = '::')),
          all(pairs$left_grade %in% c('correct', 'incorrect', 'abstain')),
          all(pairs$right_grade %in% c('correct', 'incorrect', 'abstain')),
          sum(pairs$experiment == 'two_model_facts' &
              pairs$comparison_id == 'self_vs_natural_peer') == 394L,
          sum(pairs$experiment == 'two_model_math' &
              pairs$comparison_id == 'self_vs_natural_peer') == 164L,
          sum(pairs$experiment == 'human_challenge_followup') == 78L)

natural_risk <- subset(pairs,
  experiment %in% c('two_model_facts', 'two_model_math') &
  comparison_id == 'self_vs_natural_peer' &
  receiver_initial_grade == 'correct' & right_donor_grade == 'incorrect')
initial_misconception <- subset(pairs,
  comparison_id == 'neutral_vs_false_premise_initial')
initially_correct <- subset(initial_misconception, left_grade == 'correct')
chain_opportunities <- subset(pairs,
  comparison_id == 'neutral_ai_vs_misconception_ai' &
  receiver_initial_grade == 'correct' &
  left_donor_grade == 'correct' & right_donor_grade == 'incorrect')
human_pairs <- subset(pairs, experiment == 'human_challenge_followup')
stopifnot(nrow(natural_risk) == 94L,
          sum(natural_risk$right_wrong) == 1L,
          nrow(initial_misconception) == 159L,
          nrow(initially_correct) == 125L,
          sum(initially_correct$right_wrong) == 7L,
          sum(initially_correct$right_abstain) == 1L,
          nrow(chain_opportunities) == 7L,
          sum(chain_opportunities$right_wrong) == 0L,
          sum(human_pairs$right_wrong) == 4L)
write.csv(pairs, output, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
r <- read.csv(output, stringsAsFactors = FALSE, na.strings = '',
              fileEncoding = 'UTF-8')
stopifnot(nrow(r) == nrow(pairs),
          identical(r$right_observation_id, pairs$right_observation_id))
jsonlite::write_json(list(status = 'passed', rows = nrow(pairs),
  comparisons = audit,
  focused_checks = list(natural_wrong_donor_with_correct_receiver =
    nrow(natural_risk), natural_wrong_donor_final_wrong =
    sum(natural_risk$right_wrong),
    initial_prompt_scorable_pairs = nrow(initial_misconception),
    initial_prompt_neutral_correct = nrow(initially_correct),
    initial_prompt_correct_to_wrong = sum(initially_correct$right_wrong),
    initial_prompt_correct_to_abstain = sum(initially_correct$right_abstain),
    full_chain_opportunities =
    nrow(chain_opportunities), full_chain_final_wrong =
    sum(chain_opportunities$right_wrong),
    direct_human_challenge_pairs = nrow(human_pairs),
    direct_human_challenge_final_wrong = sum(human_pairs$right_wrong)),
  csv_sha256 = digest::digest(file = output, algo = 'sha256')),
  audit_path, pretty = TRUE, auto_unbox = TRUE)
cat('Wrote', nrow(pairs), 'complete matched comparisons to', output, '\n')
