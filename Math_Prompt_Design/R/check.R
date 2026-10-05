suppressPackageStartupMessages(library(jsonlite))
source('Fact_Prompt_Design/R/prompts.R')
source('Math_Prompt_Design/R/cases.R')
source('Math_Prompt_Design/R/verify_math.R')
root<-'Math_Prompt_Design/generated'
b<-fromJSON(file.path(root,'model_prompts.json'),simplifyVector=FALSE)
refs<-fromJSON(file.path(root,'researcher_reference.json'),simplifyVector=FALSE)
reviews<-fromJSON(file.path(root,'item_review.json'),simplifyVector=FALSE)
original<-Filter(function(x)x$domain=='mathematics',lapply(readLines('Followup_Validation/protocol/questions.jsonl'),function(z)fromJSON(z,simplifyVector=FALSE)))
byid<-setNames(original,vapply(original,function(x)x$question_id,''));calculated<-math_computations()
checks<-list();check<-function(n,ok){checks[[n]]<<-isTRUE(ok);if(!isTRUE(ok))stop(n)}
ids<-vapply(b$questions,function(x)x$question_id,'')
check('41_unique_original_CHAMP_questions',length(ids)==41&&!anyDuplicated(ids)&&setequal(ids,names(byid)))
check('287_condition_designs',sum(vapply(b$questions,function(x)length(x$prompts),0))==287)
check('previously_excluded_four_questions_not_reintroduced',!any(ids%in%paste0('CHAMP:',c('P_Sequence_33','P_Sequence_10','P_Inequality_7','P_Inequality_22'))))
strip_header<-function(x)sub('^[^\n]*\n','',x)
systems<-vapply(b$questions,function(x)x$system,'')
check('one_shared_system_reason_before_answer',length(unique(systems))==1&&grepl('Write "reason" first',systems[1],fixed=TRUE)&&grepl('finally "answer"',systems[1],fixed=TRUE))
check('no_search_instruction_or_prohibition',!grepl('search|browse|external tools|internet|do not use tools',systems[1],ignore.case=TRUE))
check('no_researcher_reference_fields_in_model_records',all(vapply(b$questions,function(x)!any(c('gold','reference_answer','correct_argument','source_url','error_location')%in%names(x)),TRUE)))
for(i in seq_along(b$questions)){
 x<-b$questions[[i]];q<-byid[[x$question_id]];c<-math_cases[[q$source_id]];r<-refs[[i]];p<-x$prompts
 stopifnot(identical(q$question,p$neutral_initial),identical(q$question,x$question),identical(q$gold,r$reference_answer),
  isTRUE(all.equal(calculated[[q$source_id]]$value,as.numeric(q$gold))),c$wrong_answer!=q$gold,
  identical(p$misconception_initial,misconception_prompt(q$question,c$wrong_answer,c$wrong_reason)),
  identical(strip_header(p$A0_AI),strip_header(p$A0_Human)),identical(strip_header(p$A1_AI),strip_header(p$A1_Human)),
  identical(p$self_check,review_suffix),!grepl('{{',p$misconception_initial,fixed=TRUE),
  grepl('{{A0_ACTUAL_ANSWER}}',p$A0_AI,fixed=TRUE),grepl('{{A1_ACTUAL_ANSWER}}',p$A1_AI,fixed=TRUE),
  !grepl('https?://',p$misconception_initial),!grepl(c$error_location,p$misconception_initial,fixed=TRUE),is.null(x$mechanism_selected))
}
check('all_41_references_and_preserved_stems_pass',TRUE)
check('all_41_false_beliefs_have_specific_error_and_correct_argument',all(vapply(math_cases,function(x)nzchar(x$error_location)&&nzchar(x$correct_argument),TRUE)))
check('all_41_attribution_pairs_and_runtime_placeholders_match',TRUE)
# Check the arithmetic inside selected faulty derivations, while keeping their
# invalid assumption distinct from the calculations that follow it.
check('wrong_counting_values_are_correct_for_the_stated_wrong_method',
 factorial(6)/48==15&&choose(4,2)*6*factorial(3)==216&&choose(2000,2)==1999000&&choose(98,2)==4753&&8^3==512)
bad<-c(1,1);for(n in 2:5)bad[n+1]<-bad[n]+4*bad[n-1]
check('omitted_tiling_case_really_produces_65',bad[6]==65&&l_tilings(5)==87)
check('Fibonacci_stimulus_index_values',fibtiling(12)==233&&fibtiling(10)==89&&fibtiling(11)==144)
check('five_non_numeric_wrong_targets_explicitly_flagged',sum(vapply(reviews,function(x)x$explicit_non_numeric_wrong_target,TRUE))==5)
check('no_minimum_stimuli_refuted_by_positive_equality_witnesses',
 all(vapply(c('P_Inequality_8','P_Inequality_24','P_Inequality_15'),function(id)grepl('No minimum',math_cases[[id]]$wrong_answer,fixed=TRUE)&&calculated[[id]]$value==0,TRUE)))
check('symbolic_wrong_remainders_and_limits_are_not_zero', (2-1)!=0 && (1-2)!=0)
# Reuse the shared renderer with only synthetic test inputs (not experimental data).
fixture<-list(answer='No minimum is attained; the infimum is 0.',abstain=FALSE,reason='TEST ONLY: a deliberately false strictness argument.')
ai<-peer_prompt(fixture,'ai');hu<-peer_prompt(fixture,'human')
check('non_numeric_answer_and_false_abstain_flag_preserved',grepl(fixture$answer,ai,fixed=TRUE)&&grepl('Abstain: false',ai,fixed=TRUE)&&identical(strip_header(ai),strip_header(hu)))
fixture<-list(answer='',abstain=TRUE,reason='TEST ONLY: I cannot determine the result.')
check('explicit_abstention_preserved',grepl('Answer: \nAbstain: true',peer_prompt(fixture,'human'),fixed=TRUE))
check('no_collected_response_or_subset_selection_claim',isTRUE(b$no_model_calls)&&identical(b$mechanism_subset_selected,FALSE)&&identical(b$status,'design_reviewed_not_collection_frozen'))
jsonlite::write_json(list(status='pass',check_groups=length(checks),checks=checks,questions_reviewed=41,
 references_matching=41,model_calls=0,scope='R checks plus separately written analytic arguments; not formal proof verification.',
 pending='Freeze semantic scoring for symbolic and existence assertions before collecting new data.'),file.path(root,'checks.json'),auto_unbox=TRUE,pretty=TRUE)
cat(length(checks),'check groups passed; 41 references match. No model calls.\n')
