source('Online_Replication/R/common.R')
qs<-indexed(read_jsonl(file.path(OROOT,'protocol/questions.jsonl')),'question_id')
t<-read.csv(file.path(OROOT,'protocol/tasks.csv'),stringsAsFactors=FALSE)
cfgs<-read_json(file.path(OROOT,'protocol/models.json'))
fm<-read_json('Peer_Misleading_Study/data/main_frozen/materials.json')
mm<-read_json('Math_Supplement/protocol/materials-supplementary.json')
checks<-list()
check<-function(name,ok){stopifnot(isTRUE(ok));checks[[name]]<<-TRUE}
check('unique_full_task_set',nrow(t)==7146&&!anyDuplicated(t$id)&&length(qs)==154)
check('different_model_donors',all(t$provider!=t$donor))
check('both_other_donors',all(vapply(split(t[t$condition=='N0',],interaction(t[t$condition=='N0','question_id'],t[t$condition=='N0','provider'],drop=TRUE)),function(z)length(unique(z$donor))==2,TRUE)))
for(i in seq_len(nrow(t))){
 z<-t[i,];q<-qs[[z$question_id]]
 baseline<-if(q$domain=='math_trap')mjson(c(q$gold,list(reason='A test justification.')))else mjson(list(answer=as.character(q$gold),abstain=FALSE,reason='A test justification.'))
 material<-NULL
 if(z$condition%in%c(paste0('C',1:5),'W1')){
  truth<-if(z$condition%in%c('C4','C5'))'correct'else'wrong'
  material<-(if(q$domain=='math_trap')mm else fm)[[paste(z$question_id,z$donor,truth,sep=':')]];stopifnot(!is.null(material))
 }
 msg<-omessages(q,z$condition,baseline,baseline,material)
 stopifnot(identical(msg[[2]]$content,q$question))
 stopifnot(!grepl('search|web|external|tools|live_web',msg[[1]]$content,ignore.case=TRUE))
 payload<-opayload(msg,q,cfgs[[z$provider]])
 stopifnot(is.null(payload$tool_choice),length(payload$tools)==1)
 if(z$condition=='N0')stopifnot(length(msg)==2)
}
check('all_7146_payloads_native_optional_no_prefetch',TRUE)
q<-qs[[t$question_id[which(t$domain=='facts')[1]]]]
check('abstention_nonerror',oscore(mjson(list(answer='',abstain=TRUE,reason='I do not know.')),q)=='abstain')
check('gold_correct',oscore(mjson(list(answer=q$gold,abstain=FALSE,reason='A justification.')),q)=='correct')
check('invalid_not_abstention',oscore('unparseable',q)=='unscorable')
probe<-oread(file.path(OROOT,'runs/responses.jsonl'))
for(p in MODELS){
 a<-Filter(function(r)r$id==paste0('probe:native:',p,':1'),probe)[[1]]
 check(paste0(p,'_real_native_search'),a$http_status==200&&a$search$requested>0)
 b<-Filter(function(r)startsWith(r$id,paste0('probe:branch:',p,':')),probe)
 check(paste0(p,'_conversation_with_search_history'),any(vapply(b,function(r)r$status=='ok',TRUE)))
}
write_json(list(time=now(),checks=checks),file.path(OROOT,'protocol/tests.json'))
cat('Passed',length(checks),'checks including every planned payload.\n')
