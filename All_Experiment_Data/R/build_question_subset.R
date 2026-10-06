#!/usr/bin/env Rscript
# Select answer records relevant to the four current research questions.
# The source inventory and every original grade remain unchanged.

source_path <- 'All_Experiment_Data/all_experiment_responses.csv'
output_path <- 'All_Experiment_Data/question_relevant_responses.csv'
audit_path <- 'All_Experiment_Data/question_selection_audit.json'

d <- read.csv(source_path, stringsAsFactors = FALSE, na.strings = '',
              fileEncoding = 'UTF-8', check.names = FALSE)
studies <- c('peer_misleading_main', 'math_supplement_supplementary',
             'natural_crosscheck', 'followup_validation',
             'two_model_facts', 'two_model_math', 'human_challenge_followup')
s <- d[d$experiment %in% studies, , drop = FALSE]
stopifnot(nrow(d) == 14095L, nrow(s) == 12694L,
          !anyDuplicated(s$observation_id),
          all(s$experiment %in% studies))

e <- s$experiment
cnd <- s$condition
controlled <- e %in% c('peer_misleading_main', 'math_supplement_supplementary')
natural <- e %in% c('natural_crosscheck', 'followup_validation')
two <- e %in% c('two_model_facts', 'two_model_math')
human <- e == 'human_challenge_followup'

s$rq1_double_check <-
  (controlled & cnd %in% c('baseline', 'C0')) |
  (natural & cnd %in% c('N0', 'N1', 'N2', 'N3')) |
  (two & cnd %in% c('neutral_initial', 'self_check', 'A0_AI'))
s$rq2_method_comparison <-
  controlled | natural |
  (two & cnd %in% c('neutral_initial', 'self_check', 'A0_AI', 'A0_Human'))
s$rq3_wrong_peer_risk <-
  (controlled & cnd %in% c('baseline', 'C0', 'C1', 'C2', 'C3')) |
  natural | two
s$rq4_human_misconception <- two | human

stopifnot(all(s$rq1_double_check | s$rq2_method_comparison |
              s$rq3_wrong_peer_risk | s$rq4_human_misconception))

role <- rep(NA_character_, nrow(s))
role[cnd %in% c('baseline', 'N0', 'neutral_initial')] <- 'independent_answer'
role[cnd %in% c('C0', 'N1', 'self_check', 'neutral')] <- 'neutral_self_recheck'
role[cnd == 'N2' | cnd == 'A0_AI'] <- 'natural_cross_model_recheck'
role[cnd == 'N3'] <- 'structured_natural_cross_model_recheck'
role[cnd == 'C1'] <- 'scripted_wrong_answer'
role[cnd == 'C2'] <- 'scripted_wrong_answer_and_reason'
role[cnd == 'C3'] <- 'structured_scripted_wrong_advice'
role[cnd == 'C4'] <- 'scripted_correct_answer_and_reason'
role[cnd == 'C5'] <- 'structured_scripted_correct_advice'
role[cnd == 'W0'] <- 'scripted_wrong_advice_recheck'
role[cnd == 'W1'] <- 'structured_wrong_advice_no_extra_abstention_reminder'
role[cnd == 'W2'] <- 'structured_wrong_advice_with_abstention_reminder'
role[cnd == 'misconception_initial'] <- 'upstream_model_given_false_human_premise'
role[cnd == 'A0_Human'] <- 'natural_peer_answer_labeled_human'
role[cnd == 'A1_AI'] <- 'misconception_exposed_peer_answer_labeled_ai'
role[cnd == 'A1_Human'] <- 'misconception_exposed_peer_answer_labeled_human'
role[cnd == 'human_challenge'] <- 'correct_baseline_then_scripted_false_human_challenge'
stopifnot(!anyNA(role))
s$condition_role <- role

evidence <- rep(NA_character_, nrow(s))
evidence[e == 'peer_misleading_main'] <- 'earlier_formal_controlled_facts'
evidence[e == 'math_supplement_supplementary'] <- 'earlier_partial_math_supplement'
evidence[e == 'natural_crosscheck'] <- 'earlier_small_natural_crosscheck'
evidence[e == 'followup_validation'] <- 'earlier_expanded_validation'
evidence[two] <- 'latest_two_model_completed_data_sensitivity'
evidence[human] <- 'latest_scripted_human_challenge_supplement'
stopifnot(!anyNA(evidence))
s$evidence_group <- evidence

component <- rep('not_rq4', nrow(s))
component[two & cnd %in% c('neutral_initial', 'misconception_initial')] <-
  'model_a_initial_prompt_comparison'
component[two & cnd %in% c('A0_AI', 'A0_Human', 'A1_AI', 'A1_Human')] <-
  'downstream_model_b_exploratory_extension'
component[two & cnd == 'self_check'] <- 'model_a_context_only'
component[human] <- 'same_model_correct_answer_then_false_human_challenge'
s$rq4_component <- component

# Pair key groups parallel branches for the same receiver. Donor links are
# retained separately because the donor is another model, not a paired arm.
rep_id <- ifelse(is.na(s$repeat_id), 'single', as.character(s$repeat_id))
s$receiver_pair_key <- paste(s$experiment, s$question_id, s$provider,
                             rep_id, sep = '::')
s$receiver_pair_key[human] <- paste(s$experiment[human],
                                     s$baseline_id[human], sep = '::')
s$scorable_answer <- s$response_status == 'ok' &
  s$grade %in% c('correct', 'incorrect', 'abstain')

# The four RQs overlap; one source response remains one row in the CSV.
stopifnot(sum(two) == 2332L, sum(human) == 156L,
          sum(s$response_status == 'not_requested') == 136L,
          all(s$scorable_answer[human]),
          !anyDuplicated(s$observation_id))

write.csv(s, output_path, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
r <- read.csv(output_path, stringsAsFactors = FALSE, na.strings = '',
              fileEncoding = 'UTF-8', check.names = FALSE)
stopifnot(nrow(r) == nrow(s),
          identical(r$observation_id, s$observation_id),
          identical(ifelse(is.na(r$response_text), '', r$response_text),
                    ifelse(is.na(s$response_text), '', s$response_text)))

by_study <- as.list(table(s$experiment))
rq_rows <- list(rq1 = sum(s$rq1_double_check),
                rq2 = sum(s$rq2_method_comparison),
                rq3 = sum(s$rq3_wrong_peer_risk),
                rq4 = sum(s$rq4_human_misconception))
jsonlite::write_json(list(status = 'passed', source_rows = nrow(d),
  selected_rows = nrow(s), excluded_rows = nrow(d) - nrow(s),
  unique_ids = length(unique(s$observation_id)),
  scorable_responses = sum(s$scorable_answer),
  not_requested = sum(s$response_status == 'not_requested'),
  by_study = by_study, rq_membership_rows = rq_rows,
  output_sha256 = digest::digest(file = output_path, algo = 'sha256')),
  audit_path, pretty = TRUE, auto_unbox = TRUE)
cat('Selected', nrow(s), 'unique rows; wrote', output_path, '\n')
print(data.frame(research_question = names(rq_rows),
                 membership_rows = unlist(rq_rows)), row.names = FALSE)
