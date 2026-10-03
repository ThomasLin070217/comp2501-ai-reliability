# Concurrent HTTP collection in R. Credentials are read only from environment.
source('Followup_Validation/R/common.R')
library(curl)
args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)==2,args[1]%in%c('baseline','branches'),args[2]%in%MODELS)
stage<-args[1];provider<-args[2]
freeze<-read_json(file.path(VROOT,'protocol/freeze.json'))
stopifnot(all(vapply(names(freeze$files_sha256),function(p)file_sha(p)==freeze$files_sha256[[p]],TRUE)))
cfg<-read_json(file.path(VROOT,'protocol/models.json'))[[provider]]
stopifnot(nzchar(Sys.getenv(cfg$api_key_env)))
qs<-indexed(read_jsonl(file.path(VROOT,'protocol/questions.jsonl')),'question_id')
wm<-read_json(file.path(VROOT,'protocol/wrong_materials.json'))
orders<-jsonlite::fromJSON(file.path(VROOT,'protocol/orders.json'))[[provider]]
orders<-orders[if(stage=='baseline')orders$condition=='N0'else orders$condition!='N0',]
dir<-file.path(VROOT,'runs',provider);dir.create(dir,recursive=TRUE,showWarnings=FALSE)
rp<-file.path(dir,'responses.jsonl');ap<-file.path(dir,'attempts.jsonl');sp<-file.path(dir,'skipped.jsonl')
readif<-function(p)if(file.exists(p))read_jsonl(p)else list()
rec<-readif(rp);at<-readif(ap);skipped<-readif(sp)
stopifnot(length(setdiff(field(at,'attempt_id'),field(rec,'attempt_id')))==0)
used<-sum(vapply(rec,function(r)r$cost_guard_cny%||%0,0));retry_used<-sum(vapply(at,function(a)a$retry%||%0,0))
allrec<-unlist(lapply(MODELS,function(p)readif(file.path(VROOT,'runs',p,'responses.jsonl'))),recursive=FALSE)
allrec<-allrec[!duplicated(field(allrec,'task_id'),fromLast=TRUE)];done<-indexed(allrec,'task_id')
if(stage=='branches')stopifnot(all(file.exists(file.path(VROOT,'runs',MODELS,'baseline.done.json'))))
deadline<-as.POSIXct(freeze$deadline_utc,tz='UTC')
cost_limit<-freeze$per_provider_cost_guard_cny
jobs<-list()
for(i in seq_len(nrow(orders))){
 z<-orders[i,];id<-vtask(z$question_id,provider,z$repeat_id,z$condition)
 if(!is.null(done[[id]])||id%in%field(skipped,'task_id'))next
 q<-qs[[z$question_id]];b<-done[[vtask(z$question_id,provider,z$repeat_id,'N0')]]
 d<-done[[vtask(z$question_id,z$donor,z$repeat_id,'N0')]]
 usable<-function(x)!is.null(x)&&x$status=='ok'&&vvalid(vparse(x$text%||%''))
 why<-NULL
 if(z$condition!='N0'&&!usable(b))why<-'baseline_unavailable_or_invalid'
 if(z$condition%in%c('N2','N3')&&!usable(d))why<-'donor_unavailable_or_invalid'
 if(!is.null(why)){x<-list(task_id=id,reason=why,time=now());mappend(x,sp);skipped[[length(skipped)+1L]]<-x;next}
 wrong<-if(z$condition%in%c('W0','W1','W2'))wm[[paste(z$question_id,z$donor,'wrong',sep=':')]]else NULL
 msg<-vmessages(q,z$condition,if(is.null(b))NULL else b$text,if(is.null(d))NULL else d$text,wrong)
 payload<-c(list(model=cfg$model),cfg$generation)
 payload$max_tokens<-if(q$domain=='facts')768 else 1536
 if(cfg$protocol=='anthropic'){payload$system<-msg[[1]]$content;payload$messages<-msg[-1]}else payload$messages<-msg
 jobs[[length(jobs)+1L]]<-list(task_id=id,question_id=z$question_id,domain=q$domain,family=q$family,provider=provider,donor=z$donor,repeat_id=z$repeat_id,condition=z$condition,baseline_task=if(z$condition=='N0')NULL else b$task_id,donor_task=if(z$condition%in%c('N2','N3'))d$task_id else NULL,wrong_material_key=if(is.null(wrong))NULL else paste(z$question_id,z$donor,'wrong',sep=':'),request=payload,retry=0L)
}
cat(provider,stage,'pending',length(jobs),'used guard',used,'\n');flush.console()
completed<-0L;fatal<-NULL
while(length(jobs)){
 if(Sys.time()>deadline||length(at)>=freeze$max_attempts_per_provider)stop('Deadline or attempt guard reached')
 batch<-head(jobs,4);jobs<-tail(jobs,-length(batch))
 reserves<-vapply(batch,function(j)(nchar(vjson(j$request),type='bytes')*20+j$request$max_tokens*50)/1e6,0)
 if(used+sum(reserves)>cost_limit)stop('Cost reservation guard reached; no further requests issued')
 pool<-new_pool(total_con=4,host_con=4);results<-vector('list',length(batch))
 for(k in seq_along(batch))local({
  kk<-k;j<-batch[[kk]];reserve<-reserves[kk];body<-vjson(j$request);start<-Sys.time()
  aid<-paste0(j$task_id,':http',j$retry)
  ar<-list(task_id=j$task_id,attempt_id=aid,retry=j$retry,time=now(),reservation_cny=reserve);mappend(ar,ap);at[[length(at)+1L]]<<-ar
  base<-c(j,list(attempt_id=aid,time=now(),request_sha256=digest::digest(body,algo='sha256',serialize=FALSE)))
  finish<-function(response=NULL,error=NULL){
   rr<-base;rr$status<-'transport_error';rr$cost_guard_cny<-reserve;rr$latency_seconds<-as.numeric(difftime(Sys.time(),start,units='secs'))
   rr$http_status<-if(is.null(response))NULL else response$status_code
   if(!is.null(response)&&response$status_code==200){
    raw<-tryCatch(jsonlite::fromJSON(rawToChar(response$content),simplifyVector=FALSE),error=function(e)NULL)
    if(!is.null(raw)){
     rr$raw_response<-raw;rr$usage<-raw$usage%||%list()
     if(cfg$protocol=='anthropic'){
      rr$text<-paste(vapply(Filter(function(b)b$type=='text',raw$content),function(b)b$text,''),collapse='\n');rr$finish_reason<-raw$stop_reason
      rr$input_tokens<-sum(unlist(rr$usage[c('input_tokens','cache_creation_input_tokens','cache_read_input_tokens')]));rr$output_tokens<-rr$usage$output_tokens%||%0
      rr$status<-if(identical(rr$finish_reason,'end_turn'))'ok'else'incomplete'
     }else{
      choice<-raw$choices[[1]];rr$text<-choice$message$content%||%'';rr$finish_reason<-choice$finish_reason
      rr$input_tokens<-rr$usage$prompt_tokens%||%0;rr$output_tokens<-rr$usage$completion_tokens%||%0
      rr$status<-if(identical(rr$finish_reason,'stop'))'ok'else'incomplete'
     }
     if(length(rr$usage))rr$cost_guard_cny<-(rr$input_tokens*20+rr$output_tokens*50)/1e6
    }
   }
   # Never save headers, credentials or verbose curl exception messages.
   mappend(rr,rp);results[[kk]]<<-rr
  }
  url<-paste0(sub('/$','',cfg$base_url),if(cfg$protocol=='anthropic')'/messages'else'/chat/completions')
  stopifnot(url%in%c('https://api.deepseek.com/chat/completions','https://api.moonshot.cn/v1/chat/completions','http://www.bio8.cs.hku.hk:8080/v1/messages'))
  h<-new_handle();headers<-list('Content-Type'='application/json')
  if(cfg$protocol=='anthropic'){headers[['x-api-key']]<-Sys.getenv(cfg$api_key_env);headers[['anthropic-version']]<-'2023-06-01'}else headers[['Authorization']]<-paste('Bearer',Sys.getenv(cfg$api_key_env))
  handle_setheaders(h,.list=headers);handle_setopt(h,postfields=body,timeout=120,connecttimeout=20,followlocation=FALSE)
  curl_fetch_multi(url,done=function(res)finish(res),fail=function(msg)finish(error=TRUE),pool=pool,handle=h)
 })
 multi_run(pool=pool)
 for(k in seq_along(results)){
  r<-results[[k]];stopifnot(!is.null(r));used<-used+r$cost_guard_cny;completed<-completed+1L
  if(!is.null(r$http_status)&&r$http_status%in%c(401,403,429))fatal<-'Provider authentication/rate limit; pause without automatic retry'
  retryable<-r$status=='transport_error'&&(is.null(r$http_status)||r$http_status%in%c(502,503,504))
  if(retryable&&batch[[k]]$retry==0L&&retry_used<freeze$max_retries_per_provider){j<-batch[[k]];j$retry<-1L;retry_used<-retry_used+1L;jobs<-c(jobs,list(j))}
 }
 cat(provider,stage,'completed',completed,'remaining',length(jobs),'guard',round(used,4),'last',paste(vapply(results,function(r)r$status,''),collapse=','),'\n');flush.console()
 if(!is.null(fatal))stop(fatal)
}
write_json(list(provider=provider,stage=stage,time=now(),completed_attempts_this_invocation=completed,cost_guard_cny=used),file.path(dir,paste0(stage,'.done.json')))
