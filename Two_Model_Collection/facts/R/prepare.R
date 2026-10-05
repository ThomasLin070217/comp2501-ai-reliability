# Offline, deterministic preparation; run from repository root.
suppressPackageStartupMessages({library(jsonlite);library(digest)})
source('Followup_Validation/R/common.R')
root <- 'Two_Model_Collection/facts'
dir.create(file.path(root,'protocol'),recursive=TRUE,showWarnings=FALSE)
dir.create(file.path(root,'reports'),recursive=TRUE,showWarnings=FALSE)
stopifnot(!file.exists(file.path(root,'protocol/freeze.json')))
qs <- Filter(function(q)q$domain=='facts',read_jsonl('Online_Replication/protocol/questions.jsonl'))
qs <- qs[order(field(qs,'question_id'))]
stopifnot(length(qs)==100L,!anyDuplicated(field(qs,'question_id')))
bank <- read_json('Fact_Prompt_Design/generated/model_prompts.json')
stopifnot(identical(field(qs,'question_id'),field(bank$questions,'question_id')))
# Largest-remainder proportional allocation: day=9, month=3, year=13.
strata <- sort(unique(field(qs,'granularity')))
sizes <- setNames(vapply(strata,function(s)sum(field(qs,'granularity')==s),0L),strata)
raw <- 25*sizes/sum(sizes); allocation <- floor(raw)
allocation[order(-(raw-allocation),names(allocation))[seq_len(25-sum(allocation))]] <-
 allocation[order(-(raw-allocation),names(allocation))[seq_len(25-sum(allocation))]]+1L
RNGkind('Mersenne-Twister','Inversion','Rejection');set.seed(25011005)
selected <- unlist(lapply(strata,function(s)sample(sort(field(qs[field(qs,'granularity')==s],'question_id')),allocation[[s]],replace=FALSE)),use.names=FALSE)
subset <- data.frame(question_id=selected,selection_order=seq_along(selected),
 granularity=vapply(selected,function(id)qs[[match(id,field(qs,'question_id'))]]$granularity,''))
write.csv(subset,file.path(root,'protocol/mechanism_subset.csv'),row.names=FALSE)
models <- c('minimax','deepseek')
tid <- function(q,p,r,c)paste('two',q,p,r,c,sep=':')
rows <- list()
for(q in qs)for(r in 1:2)for(p in models){
 donor<-setdiff(models,p)
 cs<-c('neutral_initial','self_check','A0_AI')
 if(q$question_id%in%selected)cs<-c(cs,'misconception_initial','A0_Human','A1_AI','A1_Human')
 for(cond in cs){
  baseline<-if(cond%in%c('neutral_initial','misconception_initial'))''else tid(q$question_id,p,r,'neutral_initial')
  donor_id<-if(grepl('^A[01]_',cond))tid(q$question_id,donor,r,if(startsWith(cond,'A0'))'neutral_initial'else'misconception_initial')else''
  rows[[length(rows)+1L]]<-data.frame(id=tid(q$question_id,p,r,cond),question_id=q$question_id,
   domain='facts',family=q$family%||%q$granularity,provider=p,donor=donor,repeat_id=r,condition=cond,
   baseline_id=baseline,donor_id=donor_id,mechanism_selected=q$question_id%in%selected,
   stage=if(cond=='neutral_initial')0L else if(cond%in%c('self_check','A0_AI'))1L else if(cond=='misconception_initial')2L else 3L)
 }
}
tasks<-do.call(rbind,rows)
# Seeded task order, independent of new outputs, balances repetitions/providers within stages.
set.seed(25011006);tasks$order_draw<-runif(nrow(tasks))
tasks<-tasks[order(tasks$stage,tasks$order_draw),];tasks$order_draw<-NULL
write.csv(tasks,file.path(root,'protocol/tasks.csv'),row.names=FALSE)
write_jsonl(qs,file.path(root,'protocol/questions.jsonl'))
stopifnot(file.copy('Fact_Prompt_Design/generated/model_prompts.json',file.path(root,'protocol/prompts.json')))
write_json(list(status='frozen_before_paid_collection',domain='facts',date='2026-10-05',
 natural_questions=100,mechanism_questions=25,models=models,repetitions=2,target_responses=1600,
 natural_responses=1200,additional_mechanism_responses=400,
 sampling=list(seed=25011005,rng=RNGkind(),allocation=as.list(allocation),
  method='IDs sorted within date-granularity strata; largest-remainder proportional allocation; no replacement; no new outputs inspected'),
 run_order_seed=25011006,budget_cap_cny=280,budget_scope='New facts-domain HTTP calls including failures and unresolved reservations. Historical run costs charged at parent level.',
 references='Inherited retained 100-question reference key; not a new full web adjudication.',
 inference='Question-cluster bootstrap; average repetitions within question/model, then questions, then two models equally. Missing pairs not zero.',
 contrasts=list(primary='self_check vs A0_AI',secondary='neutral_initial vs self_check',
  exploratory=c('neutral_initial vs misconception_initial','A0_AI vs A1_AI','A0_Human vs A1_Human','A0_AI vs A0_Human','A1_AI vs A1_Human')),
 error_definition='incorrect/(correct+incorrect+explicit abstain); format, transport, truncation and unavailable dependencies separate.',
 no_search_exclusion=FALSE,no_result_based_retries=TRUE,holdout_claim=FALSE),file.path(root,'protocol/design.json'))
cat('Prepared',nrow(tasks),'target responses; selected',length(selected),'mechanism questions. No network calls.\n')
