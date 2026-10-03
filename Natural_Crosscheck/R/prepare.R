source('Natural_Crosscheck/R/common.R')
stopifnot(!file.exists(file.path(NROOT,'protocol/freeze.json')))
qs<-read_jsonl('Peer_Misleading_Study/data/main_questions.jsonl')
audit<-read_json('Peer_Misleading_Study/reports/interaction_posthoc/audit.json')
excluded<-unlist(audit$exclusions$exclude_all_known_reference_concerns)
qs<-Filter(function(q)!q$question_id%in%excluded,qs)
qs<-qs[order(field(qs,'question_id'))]
set.seed(25011003);qs<-qs[sort(sample(seq_along(qs),36))]
qs<-lapply(qs,function(q){q$domain<-'facts';q$family<-'date_fact';q})
mids<-unlist(read_json('Math_Supplement/protocol/freeze-supplementary.json')$question_ids)
mq<-Filter(function(q)q$question_id%in%mids,read_jsonl('Math_Supplement/protocol/questions.jsonl'))
mq<-mq[order(field(mq,'question_id'))];mq<-lapply(mq,function(q){q$domain<-'mathematics';q})
qs<-c(qs,mq);stopifnot(length(qs)==49,!anyDuplicated(field(qs,'question_id')))
units<-list()
for(d in c('facts','mathematics')){
 ids<-which(field(qs,'domain')==d)
 for(j in seq_along(ids)){
  q<-qs[[ids[j]]];direction<-if(j%%2)1 else 2
  for(p in MODELS){donor<-MODELS[(match(p,MODELS)-1+direction)%%3+1];units[[length(units)+1]]<-data.frame(question_id=q$question_id,domain=d,family=q$family,provider=p,donor=donor,direction=direction)}
 }
}
u<-do.call(rbind,units);write.csv(u,file.path(NROOT,'protocol/units.csv'),row.names=FALSE)
write_jsonl(qs,file.path(NROOT,'protocol/questions.jsonl'))
file.copy('Math_Supplement/protocol/models.json',file.path(NROOT,'protocol/models.json'))
orders<-list()
for(p in MODELS){
 set.seed(25011003+match(p,MODELS));v<-u[u$provider==p,];v<-v[sample(nrow(v)),]
 bas<-data.frame(question_id=v$question_id,provider=p,condition='N0')
 branches<-do.call(rbind,lapply(v$question_id,function(id)data.frame(question_id=id,provider=p,condition=sample(NCOND[-1]))))
 # Globally shuffle the branch requests to balance time across conditions.
 branches<-branches[sample(nrow(branches)),]
 orders[[p]]<-rbind(bas,branches)
}
write_json(orders,file.path(NROOT,'protocol/orders.json'))
write_json(list(fact_system=FSYSTEM,fact_neutral=FNEUTRAL,fact_structured=FSTRUCT,math_schema=MSCHEMA,math_neutral=MNEUTRAL,math_structured=MSTRUCT),file.path(NROOT,'protocol/prompts.json'))
cat('Prepared 49 questions,147 units,588 planned outputs. Freeze after tests and collector review.\n')
