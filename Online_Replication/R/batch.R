source('Online_Replication/R/common.R')
oallhttp<-function(){
 paths<-c(file.path(OROOT,'runs/responses.jsonl'),list.files(file.path(OROOT,'runs/http'),pattern='responses.jsonl$',full.names=TRUE))
 unlist(lapply(paths,oread),recursive=FALSE)
}
obatch<-function(jobs,cfgs,tag,budget,used,known_ids){
 library(curl)
 dir.create(file.path(OROOT,'runs/http'),recursive=TRUE,showWarnings=FALSE)
 ap<-file.path(OROOT,'runs/http',paste0(tag,'-attempts.jsonl'))
 rp<-file.path(OROOT,'runs/http',paste0(tag,'-responses.jsonl'))
 ids<-vapply(jobs,function(j)paste0(j$id,':http',j$turn),'')
 stopifnot(!anyDuplicated(ids),!any(ids%in%known_ids))
 if(used+2*length(jobs)>budget)stop('Budget reservation guard')
 results<-vector('list',length(jobs));pool<-new_pool(total_con=6,host_con=2)
 for(i in seq_along(jobs))local({
  ii<-i;j<-jobs[[i]];cfg<-cfgs[[j$provider]];payload<-j$payload
  key<-Sys.getenv(cfg$api_key_env);stopifnot(nzchar(key))
  url<-paste0(cfg$base_url,if(cfg$protocol=='anthropic')'/messages'else'/chat/completions')
  stopifnot(url%in%c('http://www.bio8.cs.hku.hk:8080/v1/messages','https://api.deepseek.com/anthropic/v1/messages','https://api.moonshot.cn/v1/chat/completions'))
  body<-mjson(payload)
  a<-list(id=ids[ii],task_id=j$id,turn=j$turn,provider=j$provider,stage=j$request_scope%||%'formal',time=now(),reservation_cny=2,
    request_sha256=digest::digest(body,'sha256',serialize=FALSE))
  mappend(a,ap);start<-Sys.time()
  finish<-function(res=NULL){
   r<-c(a,list(request=payload,status='transport_error',guard_cny=2,
    latency_seconds=as.numeric(difftime(Sys.time(),start,units='secs'))))
   if(!is.null(res)){
    r$http_status<-res$status_code
    raw<-tryCatch(jsonlite::fromJSON(rawToChar(res$content),simplifyVector=FALSE),error=function(e)NULL)
    if(!is.null(raw))r$raw_response<-raw
    if(res$status_code==200&&!is.null(raw)){
     if(cfg$protocol=='anthropic'){
      r$text<-paste(vapply(Filter(function(b)identical(b$type,'text'),raw$content),function(b)b$text,''),collapse='\n')
      r$finish_reason<-raw$stop_reason
      r$input_tokens<-sum(unlist(raw$usage[c('input_tokens','cache_creation_input_tokens','cache_read_input_tokens')]))
      r$output_tokens<-raw$usage$output_tokens%||%0
      r$status<-if(identical(raw$stop_reason,'end_turn'))'ok'else if(identical(raw$stop_reason,'tool_use'))'tool_call'else'incomplete'
     }else{
      r$text<-raw$choices[[1]]$message$content%||%'';r$finish_reason<-raw$choices[[1]]$finish_reason
      r$input_tokens<-raw$usage$prompt_tokens%||%0;r$output_tokens<-raw$usage$completion_tokens%||%0
      r$status<-if(identical(r$finish_reason,'stop'))'ok'else if(identical(r$finish_reason,'tool_calls'))'tool_call'else'incomplete'
     }
     r$search<-osearches(raw,cfg$protocol)
     if(length(raw$usage))r$guard_cny<-(r$input_tokens*20+r$output_tokens*50)/1e6+r$search$requested*.08
    }
   }
   serialized<-mjson(r);stopifnot(!grepl(key,serialized,fixed=TRUE));mappend(r,rp);results[[ii]]<<-r
  }
  h<-new_handle();heads<-list('Content-Type'='application/json')
  if(cfg$protocol=='anthropic'){heads[['x-api-key']]<-key;heads[['anthropic-version']]<-'2023-06-01'}else heads[['Authorization']]<-paste('Bearer',key)
  handle_setheaders(h,.list=heads);handle_setopt(h,postfields=body,timeout=240,connecttimeout=20,followlocation=FALSE)
  curl_fetch_multi(url,handle=h,pool=pool,done=function(res)finish(res),fail=function(msg)finish())
 })
 multi_run(pool=pool);stopifnot(all(vapply(results,Negate(is.null),TRUE)));results
}
