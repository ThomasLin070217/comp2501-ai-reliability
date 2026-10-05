source('Online_Replication/R/common.R')
# A serial HTTP journal for connectivity probes. Collection uses the same schema.
ohttp<-function(payload,cfg,id,stage,reserve=2,budget=480){
 library(curl)
 dir.create(file.path(OROOT,'runs'),recursive=TRUE,showWarnings=FALSE)
 ap<-file.path(OROOT,'runs/attempts.jsonl');rp<-file.path(OROOT,'runs/responses.jsonl')
 a<-oread(ap);r<-oread(rp)
 stopifnot(!length(setdiff(field(a,'id'),field(r,'id'))),!id%in%field(a,'id'))
 used<-.44723+sum(vapply(r,function(x)x$guard_cny,0))
 if(used+reserve>budget)stop('Budget guard; no request sent')
 key<-Sys.getenv(cfg$api_key_env);stopifnot(nzchar(key))
 url<-paste0(cfg$base_url,if(cfg$protocol=='anthropic')'/messages'else'/chat/completions')
 stopifnot(url%in%c('http://www.bio8.cs.hku.hk:8080/v1/messages','https://api.deepseek.com/anthropic/v1/messages','https://api.moonshot.cn/v1/chat/completions'))
 body<-mjson(payload);z<-list(id=id,stage=stage,provider=cfg$provider,time=now(),request=payload,
   request_sha256=digest::digest(body,'sha256',serialize=FALSE),reservation_cny=reserve)
 stopifnot(!grepl(key,mjson(z),fixed=TRUE));mappend(z,ap)
 h<-new_handle();heads<-list('Content-Type'='application/json')
 if(cfg$protocol=='anthropic'){heads[['x-api-key']]<-key;heads[['anthropic-version']]<-'2023-06-01'}else heads[['Authorization']]<-paste('Bearer',key)
 handle_setheaders(h,.list=heads);handle_setopt(h,postfields=body,timeout=240,connecttimeout=20,followlocation=FALSE)
 start<-Sys.time();res<-tryCatch(curl_fetch_memory(url,h),error=function(e)NULL)
 out<-c(z,list(status='transport_error',guard_cny=reserve,latency_seconds=as.numeric(difftime(Sys.time(),start,units='secs'))))
 if(!is.null(res)){
  out$http_status<-res$status_code
  raw<-tryCatch(jsonlite::fromJSON(rawToChar(res$content),simplifyVector=FALSE),error=function(e)NULL)
  if(!is.null(raw))out$raw_response<-raw
  if(res$status_code==200&&!is.null(raw)){
   if(cfg$protocol=='anthropic'){
    out$text<-paste(vapply(Filter(function(b)identical(b$type,'text'),raw$content),function(b)b$text,''),collapse='\n')
    out$finish_reason<-raw$stop_reason
    out$input_tokens<-sum(unlist(raw$usage[c('input_tokens','cache_creation_input_tokens','cache_read_input_tokens')]))
    out$output_tokens<-raw$usage$output_tokens%||%0
    out$status<-if(identical(raw$stop_reason,'end_turn'))'ok'else if(identical(raw$stop_reason,'tool_use'))'tool_call'else'incomplete'
   }else{
    out$text<-raw$choices[[1]]$message$content%||%'';out$finish_reason<-raw$choices[[1]]$finish_reason
    out$input_tokens<-raw$usage$prompt_tokens%||%0;out$output_tokens<-raw$usage$completion_tokens%||%0
    out$status<-if(identical(out$finish_reason,'stop'))'ok'else if(identical(out$finish_reason,'tool_calls'))'tool_call'else'incomplete'
   }
   out$search<-osearches(raw,cfg$protocol)
   if(length(raw$usage))out$guard_cny<-(out$input_tokens*20+out$output_tokens*50)/1e6+out$search$requested*.08
  }
 }
 stopifnot(!grepl(key,mjson(out),fixed=TRUE));mappend(out,rp)
 out
}
