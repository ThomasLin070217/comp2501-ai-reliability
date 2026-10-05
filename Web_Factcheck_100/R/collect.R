source('Web_Factcheck_100/R/common.R')
library(curl)
freeze<-read_json(file.path(WROOT,'protocol/freeze.json'))
stopifnot(all(vapply(names(freeze$files_sha256),function(p)file_sha(p)==freeze$files_sha256[[p]],TRUE)))
cfg<-read_json(file.path(WROOT,'protocol/model.json'))
key<-Sys.getenv(cfg$api_key_env);stopifnot(nzchar(key))
url<-paste0(cfg$base_url,'/messages')
stopifnot(identical(url,'http://www.bio8.cs.hku.hk:8080/v1/messages'))
qs<-read_jsonl(file.path(WROOT,'protocol/questions.jsonl'))
dir.create(file.path(WROOT,'runs'),showWarnings=FALSE)
rp<-file.path(WROOT,'runs/responses.jsonl');ap<-file.path(WROOT,'runs/attempts.jsonl')
rec<-wread(rp);ats<-wread(ap)
stopifnot(setequal(field(rec,'attempt_id'),field(ats,'attempt_id')))
used<-sum(vapply(rec,function(r)r$guard_cny,0));retry_used<-sum(vapply(ats,function(r)r$retry,0))
jobs<-lapply(Filter(function(q)!q$question_id%in%field(rec,'question_id'),qs),function(q)list(q=q,retry=0L))
while(length(jobs)){
 batch<-head(jobs,freeze$concurrency);jobs<-tail(jobs,-length(batch))
 if(length(ats)+length(batch)>freeze$max_attempts || used+length(batch)*freeze$next_request_reservation_cny>freeze$token_and_search_guard_cny)stop('Attempt or budget guard; no further requests issued')
 pool<-new_pool(total_con=freeze$concurrency,host_con=freeze$concurrency);results<-vector('list',length(batch))
 for(k in seq_along(batch))local({
  kk<-k;j<-batch[[k]];q<-j$q;payload<-wrequest(q,cfg);body<-mjson(payload);aid<-paste0(q$question_id,':web:r1:http',j$retry)
  a<-list(question_id=q$question_id,attempt_id=aid,retry=j$retry,time=now())
  mappend(a,ap);ats[[length(ats)+1L]]<<-a;start<-Sys.time()
  finish<-function(res=NULL){
   r<-c(a,list(request=payload,request_sha256=digest::digest(body,'sha256',serialize=FALSE),status='transport_error',
     http_status=if(is.null(res))NULL else res$status_code,guard_cny=freeze$next_request_reservation_cny))
   if(!is.null(res)){
    raw<-tryCatch(jsonlite::fromJSON(rawToChar(res$content),simplifyVector=FALSE),error=function(e)NULL)
    if(!is.null(raw)){
     r$raw_response<-raw
     if(res$status_code==200){
      blocks<-raw$content%||%list()
      r$text<-paste(vapply(Filter(function(b)identical(b$type,'text'),blocks),function(b)b$text,''),collapse='\n')
      r$stop_reason<-raw$stop_reason;r$status<-if(identical(raw$stop_reason,'end_turn'))'ok'else'incomplete'
      r$search_calls<-sum(vapply(blocks,function(b)identical(b$type,'server_tool_use')&&identical(b$name,'web_search'),TRUE))
      r$search_result_blocks<-sum(vapply(blocks,function(b)identical(b$type,'web_search_tool_result'),TRUE))
      r$input_tokens<-sum(unlist(raw$usage[c('input_tokens','cache_creation_input_tokens','cache_read_input_tokens')]))
      r$output_tokens<-raw$usage$output_tokens%||%0
      r$guard_cny<-(r$input_tokens*20+r$output_tokens*50)/1e6+r$search_calls*0.08
     }
    }
   }
   r$latency_seconds<-as.numeric(difftime(Sys.time(),start,units='secs'))
   # Raw API responses may echo text; never persist a credential even on error.
   serialized<-mjson(r);stopifnot(!grepl(key,serialized,fixed=TRUE))
   mappend(r,rp);results[[kk]]<<-r
  }
  h<-new_handle();handle_setheaders(h,'Content-Type'='application/json','x-api-key'=key,'anthropic-version'='2023-06-01')
  handle_setopt(h,postfields=body,timeout=freeze$timeout_seconds,connecttimeout=20,followlocation=FALSE)
  curl_fetch_multi(url,handle=h,pool=pool,done=function(res)finish(res),fail=function(msg)finish())
 })
 multi_run(pool=pool)
 fatal<-FALSE
 for(k in seq_along(results)){
  r<-results[[k]];stopifnot(!is.null(r));used<-used+r$guard_cny
  if(!is.null(r$http_status)&&r$http_status%in%c(401,403,429))fatal<-TRUE
  retryable<-r$status=='transport_error'&&(is.null(r$http_status)||r$http_status%in%c(502,503,504))
  if(retryable&&batch[[k]]$retry==0&&retry_used<freeze$max_transport_retries){j<-batch[[k]];j$retry<-1L;retry_used<-retry_used+1L;jobs<-c(jobs,list(j))}
 }
 cat('attempts',length(ats),'remaining',length(jobs),'guard',round(used,3),
     'last',paste(vapply(results,function(r)paste(r$status,r$search_calls%||%0),''),collapse=', '),'\n');flush.console()
 if(fatal)stop('Authentication or rate limit; pause without automatic retry')
}
write_json(list(completed_at=now(),attempts=length(ats),guard_cny=used),file.path(WROOT,'runs/done.json'))
