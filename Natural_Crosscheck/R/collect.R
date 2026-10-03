# Environment credentials only. Run from repo root after protocol freeze.
source('Natural_Crosscheck/R/common.R')
args<-commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==2,args[1]%in%c('baseline','branches'),args[2]%in%MODELS)
stage<-args[1];provider<-args[2]
freeze<-read_json(file.path(NROOT,'protocol/freeze.json'))
stopifnot(all(vapply(names(freeze$files_sha256),function(p)file_sha(p)==freeze$files_sha256[[p]],TRUE)))
qs<-indexed(read_jsonl(file.path(NROOT,'protocol/questions.jsonl')),'question_id')
u<-read.csv(file.path(NROOT,'protocol/units.csv'));cfg<-read_json(file.path(NROOT,'protocol/models.json'))[[provider]]
stopifnot(nzchar(Sys.getenv(cfg$api_key_env)))
rundir<-file.path(NROOT,'runs',provider);dir.create(rundir,recursive=TRUE,showWarnings=FALSE)
rp<-file.path(rundir,'responses.jsonl');ap<-file.path(rundir,'attempts.jsonl');sp<-file.path(rundir,'skipped.jsonl')
rec<-if(file.exists(rp))read_jsonl(rp)else list();at<-if(file.exists(ap))read_jsonl(ap)else list()
stopifnot(length(setdiff(field(at,'attempt_id'),field(rec,'attempt_id')))==0)
used<-sum(vapply(rec,function(r)r$cost_guard_cny%||%0,0));maxcost<-15
retry_used<-sum(vapply(at,function(a)a$retry%||%0,0));maxretry<-6
records_all<-unlist(lapply(MODELS,function(p){f<-file.path(NROOT,'runs',p,'responses.jsonl');if(file.exists(f))read_jsonl(f)else list()}),recursive=FALSE)
# Last logged attempt for each task is the one available to later branches.
records_all<-records_all[!duplicated(field(records_all,'task_id'),fromLast=TRUE)]
done<-indexed(records_all,'task_id')
orders<-jsonlite::fromJSON(file.path(NROOT,'protocol/orders.json'))[[provider]]
orders<-orders[if(stage=='baseline')orders$condition=='N0' else orders$condition!='N0',]
if(stage=='branches')stopifnot(all(file.exists(file.path(NROOT,'runs',MODELS,'baseline.done.json'))))
deadline<-as.POSIXct(freeze$collection_deadline_utc,tz='UTC')
invoke<-function(task,msg,meta){
 if(!is.null(done[[task]]))return(done[[task]])
 payload<-c(list(model=cfg$model),cfg$generation)
 if(cfg$protocol=='anthropic'){payload$system<-msg[[1]]$content;payload$messages<-msg[-1]}else payload$messages<-msg
 body<-mjson(payload);reserve<-(nchar(body,type='bytes')*20+payload$max_tokens*50)/1e6
 for(retry in 0:1){
  if(Sys.time()>deadline||used+reserve>maxcost||length(at)>=202)stop('Deadline/cost/call guard reached')
  if(retry==1){if(retry_used>=maxretry)stop('Retry cap reached');retry_used<<-retry_used+1}
  aid<-paste0(task,':http',retry)
  ar<-list(task_id=task,attempt_id=aid,retry=retry,time=now(),reservation_cny=reserve)
  mappend(ar,ap);at[[length(at)+1]]<<-ar
  rr<-c(list(task_id=task,attempt_id=aid,provider=provider,stage=stage,time=now(),request=payload,request_sha256=digest::digest(body,algo='sha256',serialize=FALSE)),meta)
  url<-paste0(sub('/$','',cfg$base_url),if(cfg$protocol=='anthropic')'/messages'else'/chat/completions')
  stopifnot(url%in%c('https://api.deepseek.com/chat/completions','https://api.moonshot.cn/v1/chat/completions','http://www.bio8.cs.hku.hk:8080/v1/messages'))
  h<-curl::new_handle();headers<-list('Content-Type'='application/json')
  if(cfg$protocol=='anthropic'){headers[['x-api-key']]<-Sys.getenv(cfg$api_key_env);headers[['anthropic-version']]<-'2023-06-01'}else headers[['Authorization']]<-paste('Bearer',Sys.getenv(cfg$api_key_env))
  curl::handle_setheaders(h,.list=headers);curl::handle_setopt(h,postfields=body,timeout=90,connecttimeout=20,followlocation=FALSE)
  start<-Sys.time();response<-tryCatch(curl::curl_fetch_memory(url,h),error=function(e)NULL)
  rr$latency_seconds<-as.numeric(difftime(Sys.time(),start,units='secs'));rr$status<-'transport_error';rr$cost_guard_cny<-reserve
  retryable<-is.null(response)
  if(!is.null(response)){
   rr$http_status<-response$status_code;retryable<-response$status_code%in%c(502,503,504)
   if(response$status_code==200){
    raw<-tryCatch(jsonlite::fromJSON(rawToChar(response$content),simplifyVector=FALSE),error=function(e)NULL)
    if(!is.null(raw)){
     rr$raw_response<-raw;usage<-raw$usage%||%list();rr$usage<-usage
     if(cfg$protocol=='anthropic'){
      rr$text<-paste(vapply(Filter(function(b)identical(b$type,'text'),raw$content),function(b)b$text,''),collapse='\n');rr$finish_reason<-raw$stop_reason
      rr$input_tokens<-sum(unlist(usage[c('input_tokens','cache_creation_input_tokens','cache_read_input_tokens')]));rr$output_tokens<-usage$output_tokens%||%0
      rr$status<-if(identical(raw$stop_reason,'end_turn'))'ok'else'incomplete'
     }else{
      choice<-raw$choices[[1]];rr$text<-choice$message$content%||%'';rr$finish_reason<-choice$finish_reason
      rr$input_tokens<-usage$prompt_tokens%||%0;rr$output_tokens<-usage$completion_tokens%||%0
      rr$status<-if(identical(choice$finish_reason,'stop'))'ok'else'incomplete'
     }
     if(length(usage)>0)rr$cost_guard_cny<-(rr$input_tokens*20+rr$output_tokens*50)/1e6
    }
   }
  }
  mappend(rr,rp);rec[[length(rec)+1]]<<-rr;used<<-used+rr$cost_guard_cny;done[[task]]<<-rr
  cat(task,rr$status,sprintf('guard=%.4f',used),'\n');flush.console()
  if(!is.null(rr$http_status)&&rr$http_status%in%c(401,403,429))stop('Authentication or rate limit; provider paused')
  if(!retryable||retry==1)return(rr)
 }
}
for(i in seq_len(nrow(orders))){
 id<-orders$question_id[i];cond<-orders$condition[i];q<-qs[[id]];unit<-u[u$question_id==id & u$provider==provider,];task<-ntask(id,provider,cond)
 b<-done[[ntask(id,provider,'N0')]];d<-done[[ntask(id,unit$donor,'N0')]]
 usable<-function(r)!is.null(r)&&identical(r$status,'ok')&&nvalid(r$text,q)
 skip<-NULL
 if(cond!='N0'&&!usable(b))skip<-'baseline_unavailable_or_invalid'
 if(cond%in%c('N2','N3')&&!usable(d))skip<-'donor_unavailable_or_invalid'
 if(!is.null(skip)){mappend(list(task_id=task,question_id=id,provider=provider,condition=cond,reason=skip,time=now()),sp);next}
 msg<-nmessages(q,cond,if(is.null(b))NULL else b$text,if(is.null(d))NULL else d$text)
 meta<-list(question_id=id,domain=q$domain,family=q$family,condition=cond,donor=unit$donor,baseline_task=if(cond=='N0')NULL else b$task_id,donor_task=if(cond%in%c('N2','N3'))d$task_id else NULL,donor_text_sha256=if(cond%in%c('N2','N3'))digest::digest(donor_text(d$text,q),algo='sha256',serialize=FALSE)else NULL)
 invoke(task,msg,meta)
}
write_json(list(stage=stage,provider=provider,time=now(),logged_attempts=length(rec),token_envelope_cny=used),file.path(rundir,paste0(stage,'.done.json')))
cat('STAGE COMPLETE',stage,provider,'\n')
