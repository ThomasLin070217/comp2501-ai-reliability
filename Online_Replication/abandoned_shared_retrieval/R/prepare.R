source('Online_Replication/R/common.R')
stopifnot(!file.exists(file.path(OROOT,'protocol/freeze.json')))
qs<-read_jsonl('Followup_Validation/protocol/questions.jsonl')
mq<-read_jsonl('Math_Supplement/protocol/questions.jsonl')
keep<-unlist(read_json('Math_Supplement/protocol/freeze-supplementary.json')$question_ids)
mq<-lapply(Filter(function(q)q$question_id%in%keep,mq),function(q){q$domain<-'math_trap';q})
qs<-c(qs,mq);stopifnot(length(qs)==154,!anyDuplicated(field(qs,'question_id')))
write_jsonl(qs,file.path(OROOT,'protocol/questions.jsonl'))
cfg<-read_json('Followup_Validation/protocol/models.json');write_json(cfg,file.path(OROOT,'protocol/models.json'))
oldunits<-read.csv('Followup_Validation/protocol/units.csv')
units<-list()
for(i in seq_along(qs))for(r in 1:2)for(p in MODELS){
 q<-qs[[i]];direction<-if((i+r)%%2)1 else 2;donor<-MODELS[(match(p,MODELS)-1+direction)%%3+1]
 old<-oldunits[oldunits$question_id==q$question_id&oldunits$provider==p&oldunits$repeat_id==r,]
 if(nrow(old))donor<-old$donor
 cs<-if(q$domain=='facts')c('N0','N1','N2','N3',paste0('C',1:5),if(nrow(old)&&old$wrong_ablation)'W1')else if(q$domain=='math_trap')c('N0',paste0('C',0:5))else c('N0','N1','N2','N3')
 for(c in cs)units[[length(units)+1L]]<-data.frame(id=oid(q$question_id,p,r,c),question_id=q$question_id,domain=q$domain,family=q$family,provider=p,donor=donor,repeat_id=r,condition=c,evidence_id=epid(q$question_id,r))
}
u<-do.call(rbind,units);stopifnot(nrow(u)==7146,all(u$provider!=u$donor),!anyDuplicated(u$id))
set.seed(25011006);u<-u[sample(nrow(u)),];u<-u[order(u$condition!='N0'),]
write.csv(u,file.path(OROOT,'protocol/tasks.csv'),row.names=FALSE)
math_queries<-c(Combinatorics='combinatorics counting principles binomial coefficient inclusion exclusion reference',
 Inequality='mathematical inequalities positive variables AM GM Cauchy Schwarz equality conditions reference',
 'Number-Theory'='elementary number theory modular arithmetic divisibility congruences reference',
 Polynomial='polynomial identities roots coefficients factor theorem reference',
 Sequence='mathematical sequences recurrence relations geometric arithmetic progression reference',
 triangle='equilateral triangle side altitude area formula definition',
 kiwi='word problems irrelevant information total count addition subtraction',
 integer='quadratic equation integer roots discriminant perfect square criterion',
 month='word problems missing information unknown quantity relation')
queries<-list()
for(q in qs)for(r in 1:2){
 query<-if(q$domain=='facts')paste(q$question,'-simpleqa -huggingface -kaggle -github')else paste(math_queries[[q$family]],'-CHAMP -MathTrap -huggingface -kaggle -github')
 queries[[length(queries)+1L]]<-list(id=epid(q$question_id,r),question_id=q$question_id,repeat_id=r,query=query,
    mode=if(q$domain=='facts')'question_search'else'concept_reference_search')
}
set.seed(25011007);queries<-queries[sample(length(queries))]
write_jsonl(queries,file.path(OROOT,'protocol/retrieval_tasks.jsonl'))
# All previous datasets remain in place; explicitly retain the known disputed references outside the new primary sample.
oldfacts<-read_jsonl('Peer_Misleading_Study/data/main_questions.jsonl')
excluded<-Filter(function(q)!q$question_id%in%field(qs,'question_id'),oldfacts)
write_jsonl(excluded,file.path(OROOT,'protocol/historical_reference_concerns.jsonl'))
inventory<-data.frame(component=c('natural facts','natural CHAMP math','controlled factual advice (additional branches)','abstention reminder ablation (additional branch)','legacy math traps','historical factual reference concerns','superseded pilots/development'),
 questions=c(100,41,100,36,13,20,NA),planned_new_outputs=c(2400,984,3000,216,546,0,0),
 treatment=c('N0,N1,N2,N3','N0,N1,N2,N3','C1-C5; N0/N1 shared','W1; C2=W0 and C3=W2 shared','N0,C0-C5; separate descriptive supplement','retain offline; reference uncertainty, not response quality','retain historical, no redundant recollection'))
write.csv(inventory,file.path(OROOT,'protocol/migration_inventory.csv'),row.names=FALSE)
write_json(list(user_authorization='新增上限 ¥500，超出先停',new_budget_cny=500,collection_stop_guard_cny=480,
  previous_guard_cny=74.87456,receiver_scenario_input_tokens=1300,receiver_scenario_output_tokens=250,
  receiver_scenario_guard_cny=7146*(1300*20+250*50)/1e6,
  retrieval_scenario_guard_cny=308*.25,estimated_total_cny=7146*(1300*20+250*50)/1e6+308*.25,
  note='Planning scenario, not invoice or guarantee. HKU cash price unknown. Actual usage and reservation guard logged, 20 CNY buffer.'),file.path(OROOT,'protocol/budget.json'))
cat('Prepared 154 unique questions, 308 evidence packs,',nrow(u),'response tasks; not frozen yet.\n')
