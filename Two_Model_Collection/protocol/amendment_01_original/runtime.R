suppressPackageStartupMessages({library(jsonlite);library(curl);library(digest)})
source('Fact_Prompt_Design/R/prompts.R')
tm_root<-'Two_Model_Collection'
`%or%`<-function(x,y)if(is.null(x))y else x
tm_json<-function(x)toJSON(x,auto_unbox=TRUE,null='null',digits=NA)
tm_read<-function(p)if(file.exists(p))lapply(readLines(p,warn=FALSE),function(z)fromJSON(z,simplifyVector=FALSE))else list()
tm_write<-function(x,p)jsonlite::write_json(x,p,pretty=TRUE,auto_unbox=TRUE,null='null',digits=NA)
tm_append<-function(x,p)cat(tm_json(x),'\n',file=p,append=TRUE,sep='')
tm_now<-function()format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC')
tm_fields<-function(x,n)vapply(x,function(z)as.character(z[[n]]%or%''),'')
tm_parse<-function(text){
 if(!is.character(text)||length(text)!=1||is.na(text))return(NULL)
 parse<-function(s)tryCatch(fromJSON(s,simplifyVector=FALSE),error=function(e)NULL)
 valid<-function(x)is.list(x)&&!anyDuplicated(names(x))&&all(c('answer','abstain','reason')%in%names(x))
 x<-parse(text);if(valid(x))return(x)
 ch<-strsplit(text,'',fixed=TRUE)[[1]];found<-list()
 for(start in which(ch=='{')){depth<-0L;quoted<-FALSE;escaped<-FALSE
  for(i in start:length(ch)){c<-ch[i];if(quoted){if(escaped)escaped<-FALSE else if(c=='\\')escaped<-TRUE else if(c=='"')quoted<-FALSE;next}
   if(c=='"')quoted<-TRUE else if(c=='{')depth<-depth+1L else if(c=='}'){depth<-depth-1L;if(depth==0){z<-parse(paste(ch[start:i],collapse=''));if(valid(z))found[[length(found)+1L]]<-z;break}}}
 }
 if(!length(found))return(NULL)
 vals<-vapply(found,function(x)tm_json(x[c('answer','abstain','reason')]),'')
 if(length(unique(vals))!=1)return(NULL)
 found[[1]]
}
tm_usable<-function(r){
 if(is.null(r)||!identical(r$status,'ok'))return(FALSE)
 x<-tm_parse(r$text)
 !inherits(tryCatch(donor_body(x),error=function(e)e),'error')
}
tm_payload<-function(task,prompt,done,cfg,domain){
 condition<-task$condition
 if(condition%in%c('neutral_initial','misconception_initial')){
  messages<-list(list(role='user',content=prompt$prompts[[condition]]))
 }else{
  b<-done[[task$baseline_id]];stopifnot(tm_usable(b),identical(b$question_id,task$question_id),
    identical(b$provider,task$provider),as.integer(b$repeat_id)==as.integer(task$repeat_id),identical(b$condition,'neutral_initial'))
  follow<-review_suffix
  if(condition!='self_check'){
   d<-done[[task$donor_id]];stopifnot(tm_usable(d),identical(d$question_id,task$question_id),
    d$provider!=task$provider,as.integer(d$repeat_id)==as.integer(task$repeat_id),
    identical(d$condition,if(startsWith(condition,'A0'))'neutral_initial'else'misconception_initial'))
   follow<-peer_prompt(tm_parse(d$text),if(endsWith(condition,'Human'))'human'else'ai')
  }
  messages<-c(list(list(role='user',content=prompt$question)),b$transcript,list(list(role='user',content=follow)))
 }
 stopifnot(identical(cfg$protocol,'anthropic'))
 p<-c(list(model=cfg$model),cfg$generation);p$system<-prompt$system;p$messages<-messages
 p$max_tokens<-if(domain=='facts')768L else 1536L
 p$tools<-list(list(type='web_search_20250305',name='web_search'))
 p
}
tm_load_credentials<-function(){
 pointer<-'/private/tmp/comp2501-two-model-credential-path.txt';stopifnot(file.exists(pointer))
 path<-readLines(pointer,warn=FALSE);stopifnot(length(path)==1,startsWith(path,'/private/tmp/'))
 creds<-readRDS(path);stopifnot(setequal(names(creds),c('DEEPSEEK_API_KEY','MINIMAX_API_KEY')))
 do.call(Sys.setenv,creds);invisible(TRUE)
}
tm_http_batch<-function(jobs,cfgs,ap,rp,used,cap){
 reserve<-2;stopifnot(used+reserve*length(jobs)<=cap)
 results<-vector('list',length(jobs));pool<-new_pool(total_con=2,host_con=1)
 for(i in seq_along(jobs))local({
  ii<-i;j<-jobs[[i]];cfg<-cfgs[[j$task$provider]];key<-Sys.getenv(cfg$api_key_env);stopifnot(nzchar(key))
  url<-paste0(cfg$base_url,'/messages')
  stopifnot(url%in%c('http://www.bio8.cs.hku.hk:8080/v1/messages','https://api.deepseek.com/anthropic/v1/messages'))
  body<-tm_json(j$payload);stopifnot(!grepl(key,body,fixed=TRUE))
  attempt<-list(id=paste0(j$task$id,':http1'),task_id=j$task$id,provider=j$task$provider,time=tm_now(),
    reservation_cny=reserve,request_sha256=digest(body,'sha256',serialize=FALSE))
  tm_append(attempt,ap);start<-Sys.time()
  finish<-function(res=NULL){
   r<-c(attempt,list(request=j$payload,status='transport_error',guard_cny=reserve,latency_seconds=as.numeric(difftime(Sys.time(),start,units='secs'))))
   if(!is.null(res)){
    r$http_status<-res$status_code;raw<-tryCatch(fromJSON(rawToChar(res$content),simplifyVector=FALSE),error=function(e)NULL)
    if(!is.null(raw))r$raw_response<-raw
    if(res$status_code==200&&!is.null(raw)){
     blocks<-raw$content%or%list();r$text<-paste(vapply(Filter(function(x)identical(x$type,'text'),blocks),function(x)x$text,''),collapse='\n')
     r$finish_reason<-raw$stop_reason;r$status<-if(identical(raw$stop_reason,'end_turn'))'ok'else'incomplete'
     r$input_tokens<-sum(unlist(raw$usage[c('input_tokens','cache_creation_input_tokens','cache_read_input_tokens')]))
     r$output_tokens<-raw$usage$output_tokens%or%0
     r$search_requested<-sum(vapply(blocks,function(x)identical(x$type,'server_tool_use')&&identical(x$name,'web_search'),TRUE))
     r$search_result_blocks<-sum(vapply(blocks,function(x)identical(x$type,'web_search_tool_result'),TRUE))
     if(length(raw$usage))r$guard_cny<-(r$input_tokens*20+r$output_tokens*50)/1e6+r$search_requested*.08
    }else r$status<-if(res$status_code==200)'invalid_json_response'else'http_error'
   }
   serialized<-tm_json(r);stopifnot(!grepl(key,serialized,fixed=TRUE));tm_append(r,rp);results[[ii]]<<-r
  }
  h<-new_handle();handle_setheaders(h,.list=list('Content-Type'='application/json','x-api-key'=key,'anthropic-version'='2023-06-01'))
  handle_setopt(h,postfields=body,timeout=240,connecttimeout=20,followlocation=FALSE)
  curl_fetch_multi(url,handle=h,pool=pool,done=function(res)finish(res),fail=function(msg)finish())
 })
 multi_run(pool=pool);stopifnot(all(vapply(results,Negate(is.null),TRUE)));results
}
run_domain<-function(domain,cap_cny){
 stopifnot(domain%in%c('facts','math'))
 budget<-fromJSON(file.path(tm_root,'protocol/budget.json'),simplifyVector=FALSE)
 stopifnot(cap_cny==budget$domain_caps[[domain]])
 global<-fromJSON(file.path(tm_root,'protocol/runtime_freeze.json'),simplifyVector=FALSE)
 freeze<-fromJSON(file.path(tm_root,domain,'protocol/freeze.json'),simplifyVector=FALSE)
 for(f in list(global,freeze))for(p in names(f$files_sha256))stopifnot(digest(file=p,algo='sha256')==f$files_sha256[[p]])
 tm_load_credentials()
 cfgs<-fromJSON(file.path(tm_root,'protocol/models.json'),simplifyVector=FALSE)
 tasks<-read.csv(file.path(tm_root,domain,'protocol/tasks.csv'),stringsAsFactors=FALSE,na.strings=NULL)
 p<-fromJSON(file.path(tm_root,domain,'protocol/prompts.json'),simplifyVector=FALSE)$questions
 prompts<-setNames(p,tm_fields(p,'question_id'));dir<-file.path(tm_root,domain,'runs');dir.create(dir,recursive=TRUE,showWarnings=FALSE)
 lock<-file.path(dir,'collector.lock');if(!dir.create(lock,showWarnings=FALSE))stop('Domain collector lock exists; inspect before resuming')
 on.exit(unlink(lock,recursive=TRUE),add=TRUE)
 ap<-file.path(dir,'attempts.jsonl');rp<-file.path(dir,'http_responses.jsonl');cp<-file.path(dir,'completed.jsonl');sp<-file.path(dir,'skipped.jsonl')
 attempts<-tm_read(ap);http<-tm_read(rp);records<-tm_read(cp);done<-setNames(records,tm_fields(records,'id'));skipped<-tm_read(sp)
 unresolved<-setdiff(tm_fields(attempts,'id'),tm_fields(http,'id'));if(length(unresolved))stop('Unresolved in-flight HTTP attempts retained; no automatic retry')
 charged<-function()sum(vapply(http,function(x)x$guard_cny,0))
 save_status<-function(state){tm_write(list(time=tm_now(),status=state,domain=domain,planned=nrow(tasks),completed=length(done),
  skipped=length(skipped),remaining=nrow(tasks)-length(done)-length(skipped),http_attempts=length(http),guard_cny=charged(),cap_cny=cap_cny),file.path(dir,'status.json'))}
 save_status('running')
 repeat{
  if(file.exists(file.path(tm_root,'STOP_ALL'))){save_status('global_stop');return(invisible(NULL))}
  pending<-tasks[!tasks$id%in%c(names(done),tm_fields(skipped,'id')),];if(!nrow(pending))break
  # Follow the frozen task order and phases; dependencies must be earlier rows.
  phase_col<-if('stage'%in%names(pending))'stage'else'phase';phase<-pending[[phase_col]][1]
  pending<-pending[pending[[phase_col]]==phase,];jobs<-list()
  capacity<-min(4L,floor((cap_cny-charged())/2));if(capacity<1){save_status('budget_stopped');return(invisible(NULL))}
  for(i in seq_len(nrow(pending))){
   task<-as.list(pending[i,]);why<-NULL
   for(dep in c(task$baseline_id,task$donor_id))if(nzchar(dep)){
    if(!dep%in%c(names(done),tm_fields(skipped,'id')))stop('Frozen dependency order violation')
    if(!tm_usable(done[[dep]]))why<-if(dep==task$baseline_id)'baseline_unavailable_or_invalid'else'donor_unavailable_or_invalid'
   }
   if(!is.null(why)){s<-c(task,list(reason=why,time=tm_now()));tm_append(s,sp);skipped[[length(skipped)+1]]<-s;next}
   payload<-tm_payload(task,prompts[[task$question_id]],done,cfgs[[task$provider]],domain)
   previous<-Filter(function(x)identical(x$task_id,task$id),http)
   if(length(previous)>1)stop('Duplicate HTTP task')
   jobs[[length(jobs)+1]]<-list(task=task,payload=payload,previous=previous)
   if(length(jobs)>=capacity)break
  }
  if(!length(jobs))next
  fresh<-which(vapply(jobs,function(x)!length(x$previous),TRUE));rr<-vector('list',length(jobs))
  if(length(fresh)){
   stopifnot(!any(vapply(jobs[fresh],function(x)paste0(x$task$id,':http1'),'')%in%tm_fields(attempts,'id')))
   ans<-tm_http_batch(jobs[fresh],cfgs,ap,rp,charged(),cap_cny)
   for(k in seq_along(fresh)){rr[[fresh[k]]]<-ans[[k]];http[[length(http)+1]]<-ans[[k]]}
   attempts<-tm_read(ap)
  }
  for(i in setdiff(seq_along(jobs),fresh))rr[[i]]<-jobs[[i]]$previous[[1]]
  fatal<-FALSE
  for(i in seq_along(jobs)){
   j<-jobs[[i]];r<-rr[[i]];stopifnot(identical(r$request_sha256,digest(tm_json(j$payload),'sha256',serialize=FALSE)))
   out<-c(j$task,list(status=r$status,text=r$text%or%'',completed_at=tm_now(),http_id=r$id,
     request_sha256=r$request_sha256,guard_cny=r$guard_cny,search_requested=r$search_requested%or%0,
     search_result_blocks=r$search_result_blocks%or%0,finish_reason=r$finish_reason%or%NULL,
     transcript=if(r$status=='ok')list(list(role='assistant',content=r$raw_response$content))else NULL))
   tm_append(out,cp);done[[j$task$id]]<-out
   if(!is.null(r$http_status)&&r$http_status%in%c(401,403,429))fatal<-TRUE
   if(r$guard_cny>r$reservation_cny){writeLines('A request exceeded its conservative reservation; audit budget before continuing.',file.path(tm_root,'STOP_ALL'));fatal<-TRUE}
  }
  save_status('running');cat(domain,'completed',length(done),'skipped',length(skipped),'guard',round(charged(),3),'/',cap_cny,'\n');flush.console()
  if(fatal){save_status('provider_or_reservation_stopped');return(invisible(NULL))}
 }
 save_status('finished');cat(domain,'all tasks reached terminal status.\n');invisible(NULL)
}
