source('Two_Model_Collection/facts/protocol/scoring.R')
source('Fact_Prompt_Design/R/prompts.R')
root<-'Two_Model_Collection/facts'
tasks<-read.csv(file.path(root,'protocol/tasks.csv'),stringsAsFactors=FALSE)
qs<-indexed(read_jsonl(file.path(root,'protocol/questions.jsonl')),'question_id')
bank<-read_json(file.path(root,'protocol/prompts.json'))
sub<-read.csv(file.path(root,'protocol/mechanism_subset.csv'),stringsAsFactors=FALSE)
checks<-list()
check<-function(name,ok){stopifnot(isTRUE(ok));checks[[name]]<<-TRUE}
check('1600_unique_tasks',nrow(tasks)==1600L&&!anyDuplicated(tasks$id))
check('100_questions',length(qs)==100L)
check('25_mechanism_questions',nrow(sub)==25L&&!anyDuplicated(sub$question_id))
check('proportional_granularity',identical(as.integer(table(sub$granularity)),c(9L,3L,13L)))
check('two_models_two_repetitions',setequal(tasks$provider,c('minimax','deepseek'))&&setequal(tasks$repeat_id,1:2))
check('correct_condition_counts',all(table(tasks$condition)[c('neutral_initial','self_check','A0_AI')]==400L)&&all(table(tasks$condition)[c('misconception_initial','A0_Human','A1_AI','A1_Human')]==100L))
for(i in seq_len(nrow(tasks))){
 t<-tasks[i,]
 for(k in c('baseline_id','donor_id'))if(nzchar(t[[k]])){
  j<-match(t[[k]],tasks$id);stopifnot(!is.na(j),tasks$stage[j]<t$stage,
   tasks$question_id[j]==t$question_id,tasks$repeat_id[j]==t$repeat_id)
  if(k=='baseline_id')stopifnot(tasks$provider[j]==t$provider,tasks$condition[j]=='neutral_initial')
  else stopifnot(tasks$provider[j]!=t$provider,tasks$provider[j]==t$donor)
 }
}
check('all_dependencies_isolated_and_precede_branch',TRUE)
fixture<-list(answer='1931',abstain=FALSE,reason='Synthetic review fixture; this is not a model response.')
check('AI_Human_only_header_differs',identical(sub('^[^\n]*\n','',peer_prompt(fixture,'ai')),sub('^[^\n]*\n','',peer_prompt(fixture,'human'))))
for(b in bank$questions){
 q<-qs[[b$question_id]];stopifnot(identical(b$question,q$question),identical(b$system,fact_system),identical(b$prompts$neutral_initial,q$question))
 gold<-list(answer=q$gold,abstain=FALSE,reason='Synthetic reference-format check.')
 wrong<-list(answer=q$false_target,abstain=FALSE,reason='Synthetic assigned-wrong-format check.')
 stopifnot(fact_grade(mjson(gold),q)=='correct',fact_grade(mjson(wrong),q)=='incorrect')
}
check('100_original_questions_system_and_reference_scores',TRUE)
q<-qs[[1]]
check('explicit_abstention_retained',fact_grade(mjson(list(answer='',abstain=TRUE,reason='Cannot determine.')),q)=='abstain')
check('empty_and_malformed_not_abstention',all(vapply(c('', '{}','not JSON'),function(t)fact_grade(t,q)=='unscorable',TRUE)))
check('abstention_with_answer_unscorable',fact_grade(mjson(list(answer=q$gold,abstain=TRUE,reason='Conflict.')),q)=='unscorable')
check('truncation_not_scored',fact_grade(mjson(list(answer=q$gold,abstain=FALSE,reason='Fixture.')),q,'truncated')=='unscorable')
check('invalid_calendar_date_not_accepted',is.null(vdate('2023-02-29')))
check('prompt_copy_matches_reviewed_source',identical(file_sha(file.path(root,'protocol/prompts.json')),file_sha('Fact_Prompt_Design/generated/model_prompts.json')))
write_json(list(status='passed',checks=checks,no_network_calls=TRUE),file.path(root,'reports/preflight_checks.json'))
cat(length(checks),'offline checks passed.\n')
