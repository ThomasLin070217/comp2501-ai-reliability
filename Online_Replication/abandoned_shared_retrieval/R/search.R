# Live retrieval gateway. No benchmark gold or model answer enters this request.
source('Followup_Validation/R/common.R')
OROOT <- 'Online_Replication'
oread <- function(p) if(file.exists(p))read_jsonl(p)else list()
search_request <- function(query,cfg) {
 list(model=cfg$model,max_tokens=512,temperature=0.6,thinking=list(type='disabled'),stream=FALSE,
   system=paste('You are a web retrieval gateway. Invoke web_search for the supplied query.',
     'Do not answer the underlying question. After searching, reply only: Retrieval complete.',
     'Do not search for benchmark datasets, answer lists, or this experiment.'),
   messages=list(list(role='user',content=paste('Search the web now for:',query))),
   tools=list(list(type='web_search_20250305',name='web_search')),
   tool_choice=list(type='tool',name='web_search'))
}
blocked_source <- function(url,title='',content='') {
 grepl('simpleqa|mathtrap|gsm.?symbolic|champ.dataset|comp2501.ai.reliability|huggingface\\.co|kaggle\\.com|github\\.com|githubusercontent\\.com',
   paste(url,title,substr(content,1,500)),ignore.case=TRUE,perl=TRUE)
}
extract_evidence <- function(raw) {
 blocks<-raw$content%||%list()
 calls<-Filter(function(b)identical(b$type,'server_tool_use')&&identical(b$name,'web_search'),blocks)
 results<-Filter(function(b)identical(b$type,'web_search_tool_result'),blocks)
 ids<-vapply(calls,function(b)b$id%||%'','')
 sources<-list();excluded<-list()
 for(b in results) {
  if(!length(ids)||!b$tool_use_id%in%ids)next
  for(s in b$content%||%list()) {
   if(!is.list(s)||!is.character(s$url)||!is.character(s$content)||!nzchar(trimws(s$content)))next
   if(!grepl('^https?://[^ /]+',s$url))next
   z<-list(url=s$url,title=s$title%||%'',excerpt=substr(s$content,1,1500),tool_use_id=b$tool_use_id)
   if(blocked_source(s$url,s$title%||%'',s$content))excluded[[length(excluded)+1L]]<-z
   else sources[[length(sources)+1L]]<-z
  }
 }
 if(length(sources))sources<-sources[!duplicated(field(sources,'url'))]
 list(valid=length(calls)>0&&length(sources)>0,search_calls=length(calls),
   queries=lapply(calls,function(b)b$input$query),sources=head(sources,4),excluded=excluded)
}
# Every outbound request is journalled without headers. No automatic retry of answers.
ohttp <- function(payload,cfg,id,stage,reserve,budget=500) {
 library(curl)
 dir.create(file.path(OROOT,'runs'),recursive=TRUE,showWarnings=FALSE)
 ap<-file.path(OROOT,'runs/attempts.jsonl');rp<-file.path(OROOT,'runs/responses.jsonl')
 a<-oread(ap);r<-oread(rp)
 if(length(setdiff(field(a,'id'),field(r,'id'))))stop('Unresolved attempt: account for it before resume')
 stopifnot(!id%in%field(a,'id'))
 used<-sum(vapply(r,function(x)x$guard_cny,0))
 if(used+reserve>budget)stop('Budget reservation guard; no request sent')
 key<-Sys.getenv(cfg$api_key_env);stopifnot(nzchar(key))
 url<-paste0(cfg$base_url,if(cfg$protocol=='anthropic')'/messages'else'/chat/completions')
 stopifnot(url%in%c('http://www.bio8.cs.hku.hk:8080/v1/messages','https://api.deepseek.com/chat/completions','https://api.moonshot.cn/v1/chat/completions'))
 body<-mjson(payload)
 z<-list(id=id,stage=stage,time=now(),request=payload,request_sha256=digest::digest(body,'sha256',serialize=FALSE),reservation_cny=reserve)
 stopifnot(!grepl(key,mjson(z),fixed=TRUE));mappend(z,ap)
 h<-new_handle();headers<-list('Content-Type'='application/json')
 if(cfg$protocol=='anthropic'){headers[['x-api-key']]<-key;headers[['anthropic-version']]<-'2023-06-01'}else headers[['Authorization']]<-paste('Bearer',key)
 handle_setheaders(h,.list=headers);handle_setopt(h,postfields=body,timeout=240,connecttimeout=20,followlocation=FALSE)
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
    out$status<-if(identical(raw$stop_reason,'end_turn'))'ok'else'incomplete'
   }else{
    out$text<-raw$choices[[1]]$message$content%||%'';out$finish_reason<-raw$choices[[1]]$finish_reason
    out$input_tokens<-raw$usage$prompt_tokens%||%0;out$output_tokens<-raw$usage$completion_tokens%||%0
    out$status<-if(identical(out$finish_reason,'stop'))'ok'else'incomplete'
   }
   out$search_calls<-extract_evidence(raw)$search_calls
   if(length(raw$usage))out$guard_cny<-(out$input_tokens*20+out$output_tokens*50)/1e6+out$search_calls*.08
  }
 }
 stopifnot(!grepl(key,mjson(out),fixed=TRUE));mappend(out,rp)
 if(!is.null(out$http_status)&&out$http_status%in%c(401,403,429))stop('Authentication or quota failure; no automatic retry')
 out
}
