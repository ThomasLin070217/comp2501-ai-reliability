suppressPackageStartupMessages({library(jsonlite);library(digest)})
source('Fact_Prompt_Design/R/prompts.R')
root<-'Fact_Prompt_Design/generated'
b<-fromJSON(file.path(root,'model_prompts.json'),simplifyVector=FALSE)
refs<-fromJSON(file.path(root,'researcher_reference.json'),simplifyVector=FALSE)
reviews<-fromJSON(file.path(root,'item_review.json'),simplifyVector=FALSE)
original<-Filter(function(x)x$domain=='facts',lapply(readLines('Online_Replication/protocol/questions.jsonl'),function(z)fromJSON(z,simplifyVector=FALSE)))
byid<-setNames(original,vapply(original,function(x)x$question_id,''))
excluded<-lapply(readLines('Online_Replication/protocol/historical_reference_concerns.jsonl'),function(z)fromJSON(z,simplifyVector=FALSE))
checks<-list()
check<-function(name,ok){checks[[name]]<<-isTRUE(ok);if(!isTRUE(ok))stop(name)}
ids<-vapply(b$questions,function(x)x$question_id,'')
check('100_unique_original_fact_questions',length(ids)==100&&!anyDuplicated(ids)&&setequal(ids,names(byid)))
check('historical_reference_concerns_not_reintroduced',!any(ids%in%vapply(excluded,function(x)x$question_id,'')))
check('700_condition_designs',sum(vapply(b$questions,function(x)length(x$prompts),0))==700)
check('shared_system_identical',all(vapply(b$questions,function(x)identical(x$system,fact_system),TRUE)))
check('no_forced_or_forbidden_search',!grepl('search|external tools|browse|internet|verify online',fact_system,ignore.case=TRUE))
check('no_reference_fields_in_model_bundle',all(vapply(b$questions,function(x)!any(c('gold','reference_answer','source_urls','reference_parts','caution')%in%names(x)),TRUE)))
check('mechanism_activation_not_assumed',identical(b$mechanism_subset_selected,FALSE)&&all(vapply(b$questions,function(x)is.null(x$mechanism_selected),TRUE)))
strip_header<-function(x)sub('^[^\n]*\n','',x)
fmt_parts<-function(parts){p<-as.integer(unlist(parts));switch(as.character(length(p)),`1`=as.character(p[1]),`2`=paste(month.name[p[2]],p[1]),`3`=paste0(month.name[p[2]],' ',p[3],', ',p[1]))}
for(i in seq_along(b$questions)) {
 x<-b$questions[[i]];q<-byid[[x$question_id]];r<-refs[[i]];a<-reviews[[i]];p<-x$prompts
 stopifnot(identical(r$question_id,x$question_id),identical(a$question_id,x$question_id))
 stopifnot(identical(p$neutral_initial,q$question),identical(p$self_check,review_suffix))
 stopifnot(identical(r$assigned_wrong_answer,fmt_parts(q$false_parts)),!identical(q$false_parts,q$gold_parts))
 stopifnot(identical(p$misconception_initial,misconception_prompt(q$question,q$false_target,a$final_reason)))
 stopifnot(identical(strip_header(p$A0_AI),strip_header(p$A0_Human)),identical(strip_header(p$A1_AI),strip_header(p$A1_Human)))
 stopifnot(grepl('{{A0_ACTUAL_ANSWER}}',p$A0_AI,fixed=TRUE),grepl('{{A1_ACTUAL_ANSWER}}',p$A1_AI,fixed=TRUE))
 stopifnot(!grepl('{{',p$misconception_initial,fixed=TRUE),length(r$source_urls)>0)
 # Only test the added rationale; the original question may legitimately contain dates.
 stopifnot(!grepl(fmt_parts(q$gold_parts),a$final_reason,fixed=TRUE))
 stopifnot(!grepl('materials provided|information provided|provided date|stated release timeline|question.s context',a$final_reason,ignore.case=TRUE))
}
check('all_100_stems_targets_templates_sources_and_added_reason_leakage_checks',TRUE)
# Synthetic unit fixtures ONLY; never written as model responses or counted as data.
donors<-list(list(answer='TEST-ANSWER',abstain=FALSE,reason='TEST ONLY: uncertain reasoning\nURL: https://example.invalid/test'),
 list(answer='',abstain=TRUE,reason='TEST ONLY: I cannot determine an answer.'))
for(d in donors){ai<-peer_prompt(d,'ai');hu<-peer_prompt(d,'human');stopifnot(identical(strip_header(ai),strip_header(hu)),grepl(d$reason,ai,fixed=TRUE))}
check('actual_fields_uncertainty_newlines_and_abstention_preserved',TRUE)
fails<-function(f)inherits(tryCatch(f(),error=function(e)e),'error')
check('string_boolean_rejected',fails(function()peer_prompt(list(answer='TEST',abstain='false',reason='TEST'),'ai')))
check('abstain_answer_conflict_not_silently_rewritten',fails(function()peer_prompt(list(answer='TEST',abstain=TRUE,reason='TEST'),'ai')))
check('empty_nonabstaining_answer_rejected',fails(function()peer_prompt(list(answer='',abstain=FALSE,reason='TEST'),'ai')))
check('missing_reason_rejected',fails(function()peer_prompt(list(answer='TEST',abstain=FALSE),'ai')))
h<-list(list(role='user',content='TEST QUESTION'),list(role='assistant',tool_calls=list(list(id='TEST_SEARCH'))),
 list(role='tool',tool_call_id='TEST_SEARCH',content='TEST RESULT'),list(role='assistant',content='TEST B0'))
self<-branch_history(h,review_suffix);ai<-branch_history(h,peer_prompt(donors[[1]],'ai'));hu<-branch_history(h,peer_prompt(donors[[1]],'human'))
check('parallel_branches_keep_identical_initial_and_tool_history',all(vapply(list(self,ai,hu),function(z)identical(z[seq_along(h)],h)&&length(z)==length(h)+1L,TRUE)))
self[[1]]$content<-'MUTATED FIXTURE'
check('branch_mutation_does_not_change_other_branches',identical(h[[1]]$content,'TEST QUESTION')&&identical(ai[[1]]$content,'TEST QUESTION'))
check('unfilled_peer_placeholder_cannot_become_followup',fails(function()branch_history(h,peer_template('A0','ai'))))
check('no_paid_collection_or_model_result_claim',isTRUE(b$no_model_calls)&&identical(b$status,'design_reviewed_not_collection_frozen'))
jsonlite::write_json(list(status='pass',checks=checks,check_groups=length(checks),questions_checked=100,
 synthetic_fixtures_not_experimental_data=TRUE,model_calls=0,semantic_review_file='item_review.json',
 limitation='Prompt/schema review is not a new source-by-source adjudication of all historical references.'),
 file.path(root,'checks.json'),auto_unbox=TRUE,pretty=TRUE)
cat(length(checks),'check groups passed; 100 item-level checks passed. No model calls.\n')
