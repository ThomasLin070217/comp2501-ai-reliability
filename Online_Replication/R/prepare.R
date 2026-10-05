source('Online_Replication/R/common.R')
stopifnot(!file.exists(file.path(OROOT,'protocol/freeze.json')))
qs<-read_jsonl('Followup_Validation/protocol/questions.jsonl')
mq<-read_jsonl('Math_Supplement/protocol/questions.jsonl')
keep<-unlist(read_json('Math_Supplement/protocol/freeze-supplementary.json')$question_ids)
mq<-lapply(Filter(function(q)q$question_id%in%keep,mq),function(q){q$domain<-'math_trap';q})
qs<-c(qs,mq);stopifnot(length(qs)==154,!anyDuplicated(field(qs,'question_id')))
write_jsonl(qs,file.path(OROOT,'protocol/questions.jsonl'))
cfg<-read_json(file.path(OROOT,'protocol/models.json'))
oldunits<-read.csv('Followup_Validation/protocol/units.csv')
units<-list()
for(i in seq_along(qs))for(r in 1:2)for(p in MODELS){
 q<-qs[[i]];direction<-if((i+r)%%2)1 else 2;donor<-MODELS[(match(p,MODELS)-1+direction)%%3+1]
 old<-oldunits[oldunits$question_id==q$question_id&oldunits$provider==p&oldunits$repeat_id==r,]
 if(nrow(old))donor<-old$donor
 cs<-if(q$domain=='facts')c('N0','N1','N2','N3',paste0('C',1:5),if(nrow(old)&&old$wrong_ablation)'W1')else if(q$domain=='math_trap')c('N0',paste0('C',0:5))else c('N0','N1','N2','N3')
 for(c in cs)units[[length(units)+1L]]<-data.frame(id=oid(q$question_id,p,r,c),question_id=q$question_id,domain=q$domain,family=q$family,provider=p,donor=donor,repeat_id=r,condition=c)
}
u<-do.call(rbind,units);stopifnot(nrow(u)==7146,all(u$provider!=u$donor),!anyDuplicated(u$id))
# Fixed blocks mix fact/math questions. Complete natural comparisons before
# controlled branches, then repeat 2. A budget stop never selects by outcome.
set.seed(25011006);qorder<-sample(field(qs,'question_id'))
u$block<-ceiling(match(u$question_id,qorder)/10)
u$stage<-ifelse(u$condition=='N0',0,ifelse(u$condition%in%c('N1','N2','N3'),1,2))
u<-u[sample(nrow(u)),]
u<-u[order(u$stage==2,u$repeat_id,u$block,u$stage),]
write.csv(u,file.path(OROOT,'protocol/tasks.csv'),row.names=FALSE)
# All previous datasets remain in place; explicitly retain the known disputed references outside the new primary sample.
oldfacts<-read_jsonl('Peer_Misleading_Study/data/main_questions.jsonl')
excluded<-Filter(function(q)!q$question_id%in%field(qs,'question_id'),oldfacts)
write_jsonl(excluded,file.path(OROOT,'protocol/historical_reference_concerns.jsonl'))
inventory<-data.frame(component=c('natural facts','natural CHAMP math','controlled factual advice (additional branches)','abstention reminder ablation (additional branch)','legacy math traps','historical factual reference concerns','superseded pilots/development'),
 questions=c(100,41,100,36,13,20,NA),planned_new_outputs=c(2400,984,3000,216,546,0,0),
 treatment=c('N0,N1,N2,N3','N0,N1,N2,N3','C1-C5; N0/N1 shared','W1; C2=W0 and C3=W2 shared','N0,C0-C5; separate descriptive supplement','retain offline; reference uncertainty, not response quality','retain historical, no redundant recollection'))
write.csv(inventory,file.path(OROOT,'protocol/migration_inventory.csv'),row.names=FALSE)
probe<-Filter(function(x)x$stage=='probe',oread(file.path(OROOT,'runs/responses.jsonl')))
probe_cost<-sum(vapply(probe,function(x)x$guard_cny,0))
write_json(list(user_authorization='新增上限 ¥500，超出先停',new_budget_cny=500,collection_stop_guard_cny=480,
  previous_guard_cny=74.87456,abandoned_probe_guard_cny=.44723,native_probe_guard_cny=probe_cost,
  full_volume_searching_scenario_cny=7146*probe_cost/6,
  per_http_reservation_cny=2,max_http_turns_per_answer=4,concurrency=6,
  note='All three native probes searched; their average is NOT representative of every study question. Full 7146-answer scope may exceed 500. Stop at the budget, preserve incomplete tasks, never promise full completion within cap. HKU cash price unknown; conservative token/search guard is not an invoice.'),file.path(OROOT,'protocol/budget.json'))
cat('Prepared 154 unique questions,',nrow(u),'autonomous-search response tasks; not frozen yet.\n')
