source('Online_Replication/R/batch.R')
freeze<-read_json(file.path(OROOT,'protocol/freeze.json'))
stopifnot(all(vapply(names(freeze$files_sha256),function(p)file_sha(p)==freeze$files_sha256[[p]],TRUE)))
cfgs<-read_json(file.path(OROOT,'protocol/models.json'))
qs<-indexed(read_jsonl(file.path(OROOT,'protocol/questions.jsonl')),'question_id')
tasks<-read.csv(file.path(OROOT,'protocol/tasks.csv'),stringsAsFactors=FALSE)
facts_materials<-read_json('Peer_Misleading_Study/data/main_frozen/materials.json')
math_materials<-read_json('Math_Supplement/protocol/materials-supplementary.json')
cp<-file.path(OROOT,'runs/completed.jsonl');sp<-file.path(OROOT,'runs/skipped.jsonl')
completed<-oread(cp);done<-indexed(completed,'id');skipped<-oread(sp)
http<-oallhttp()
aps<-list.files(file.path(OROOT,'runs/http'),pattern='attempts.jsonl$',full.names=TRUE)
attempts<-unlist(lapply(aps,oread),recursive=FALSE)
stopifnot(!length(setdiff(field(attempts,'id'),field(http,'id'))))
usage<-function().44723+sum(vapply(http,function(x)x$guard_cny,0))
save_status<-function(status)write_json(list(time=now(),status=status,completed=length(done),skipped=length(skipped),planned=nrow(tasks),
 remaining=nrow(tasks)-length(done)-length(skipped),guard_cny=usage()),file.path(OROOT,'runs/status.json'))
tags<-paste(tasks$repeat_id,tasks$stage==2,tasks$block,tasks$stage,sep='-')
for(tag in unique(tags)){
 tt<-tasks[tags==tag,];jobs<-list()
 for(i in seq_len(nrow(tt))){
  z<-as.list(tt[i,]);if(z$id%in%c(names(done),field(skipped,'id')))next
  q<-qs[[z$question_id]];cfg<-cfgs[[z$provider]]
  b<-done[[oid(z$question_id,z$provider,z$repeat_id,'N0')]]
  d<-done[[oid(z$question_id,z$donor,z$repeat_id,'N0')]]
  usable<-function(x)!is.null(x)&&identical(x$status,'ok')&&ovalid(x$text,q)
  why<-NULL
  if(z$condition!='N0'&&!usable(b))why<-'baseline_unavailable_or_invalid'
  if(z$condition%in%c('N2','N3')&&!usable(d))why<-'donor_unavailable_or_invalid'
  if(!is.null(why)){r<-c(z,list(reason=why,time=now()));mappend(r,sp);skipped[[length(skipped)+1L]]<-r;next}
  material<-NULL
  if(z$condition%in%c(paste0('C',1:5),'W1')){
   truth<-if(z$condition%in%c('C4','C5'))'correct'else'wrong'
   key<-paste(z$question_id,z$donor,truth,sep=':')
   material<-if(q$domain=='math_trap')math_materials[[key]]else facts_materials[[key]]
   stopifnot(!is.null(material))
  }
  msg<-omessages(q,z$condition,if(is.null(b))NULL else b$text,if(is.null(d))NULL else d$text,material)
  # Preserve receiver's own prior search/tool transcript for conversational review.
  if(z$condition!='N0')msg<-c(msg[1:2],b$transcript,msg[length(msg)])
  payload<-opayload(msg,q,cfg)
  j<-c(z,list(payload=payload,turn=1L,search_requested=0L,search_result_blocks=0L,http_ids=list()))
  # Resume already-received HTTP turns without issuing duplicate requests.
  previous<-Filter(function(r)identical(r$task_id,z$id),http)
  j$previous<-previous;jobs[[length(jobs)+1L]]<-j
 }
 while(length(jobs)){
  capacity<-min(6L,floor((freeze$collection_stop_guard_cny-usage())/2))
  if(capacity<1){save_status('budget_paused');cat('BUDGET PAUSED',usage(),'\n');quit(status=0)}
  batch<-head(jobs,capacity);jobs<-tail(jobs,-length(batch));fresh<-which(vapply(batch,function(j)length(j$previous)==0,TRUE))
  rr<-vector('list',length(batch))
  if(length(fresh)){
   ans<-obatch(batch[fresh],cfgs,tag,freeze$collection_stop_guard_cny,usage(),field(http,'id'))
   for(k in seq_along(fresh)){rr[[fresh[k]]]<-ans[[k]];http[[length(http)+1L]]<-ans[[k]]}
  }
  for(k in setdiff(seq_along(batch),fresh)){rr[[k]]<-batch[[k]]$previous[[1]];batch[[k]]$previous<-tail(batch[[k]]$previous,-1)}
  fatal<-FALSE
  for(k in seq_along(batch)){
   j<-batch[[k]];r<-rr[[k]];cfg<-cfgs[[j$provider]]
   stopifnot(identical(r$request_sha256,digest::digest(mjson(j$payload),'sha256',serialize=FALSE)))
   j$http_ids<-c(j$http_ids,list(r$id));j$search_requested<-j$search_requested+(r$search$requested%||%0)
   j$search_result_blocks<-j$search_result_blocks+if(is.null(r$search$result_blocks)||is.na(r$search$result_blocks))0 else r$search$result_blocks
   if(!is.null(r$http_status)&&r$http_status%in%c(401,403,429))fatal<-TRUE
   if(r$status=='tool_call'&&j$provider=='kimi'&&j$turn<freeze$max_http_turns_per_answer){
    msg<-r$raw_response$choices[[1]]$message
    if(all(vapply(msg$tool_calls,function(tc)identical(tc[['function']]$name,'$web_search'),TRUE))){
     j$payload$messages<-c(j$payload$messages,list(msg))
     for(tc in msg$tool_calls)j$payload$messages<-c(j$payload$messages,list(list(role='tool',tool_call_id=tc$id,name='$web_search',content=tc[['function']]$arguments)))
     j$turn<-j$turn+1L;jobs<-c(list(j),jobs);next
    }
   }
   transcript<-NULL
   if(j$condition=='N0'&&r$status=='ok'){
    if(cfg$protocol=='anthropic')transcript<-list(list(role='assistant',content=r$raw_response$content))
    else transcript<-c(j$payload$messages[-c(1,2)],list(r$raw_response$choices[[1]]$message))
   }
   out<-c(j[setdiff(names(j),c('payload','previous'))],list(status=if(r$status=='tool_call')'tool_limit_or_unsupported'else r$status,
      text=r$text%||%'',transcript=transcript,completed_at=now()))
   mappend(out,cp);done[[j$id]]<-out
  }
  save_status('running');cat('completed',length(done),'skipped',length(skipped),'guard',round(usage(),3),'block',tag,'\n');flush.console()
  if(fatal){save_status('provider_paused');stop('Provider authentication/quota error; no automatic retry')}
 }
}
save_status('finished');cat('All planned tasks reached a terminal status.\n')
