# Explicit paid collection. Environment credentials only; no private config is read here.
source('Math_Supplement/R/common.R')
args<-commandArgs(trailingOnly=TRUE)
if(length(args)!=3||!args[1]%in%c('materials','receive')||!args[2]%in%c('development','supplementary')||!args[3]%in%MODELS)stop('Usage: collect.R materials|receive development|supplementary provider')
stage<-args[1];split<-args[2];provider<-args[3]
qs<-Filter(function(q)q$split==split,read_jsonl('Math_Supplement/protocol/questions.jsonl'))
cfg<-read_json('Math_Supplement/protocol/models.json')
cfg<-cfg$models[[provider]] %||% cfg[[provider]]
stopifnot(!is.null(cfg),nzchar(Sys.getenv(cfg$api_key_env)))
run<-file.path(MROOT,'runs',provider);dir.create(run,recursive=TRUE,showWarnings=FALSE)
rp<-file.path(run,'responses.jsonl');ap<-file.path(run,'attempts.jsonl')
records<-if(file.exists(rp))read_jsonl(rp) else list()
attempts<-if(file.exists(ap))read_jsonl(ap) else list()
done<-indexed(records,'task_id')
# Reserve unresolved attempts as well as recorded failures; never silently retry after a crash.
unresolved<-setdiff(field(attempts,'attempt_id'),field(records,'attempt_id'))
if(length(unresolved))stop('Unresolved request attempt; investigate before any new call.')
used<-sum(vapply(records,function(r)r$cost_guard_cny %||% 0,0))
limit<-if(provider=='minimax')30 else 30 # HKU separate unknown-price equivalent token envelope.
deadline<-as.POSIXct('2026-10-03 04:00:00',tz='UTC')
invoke<-function(task,msg,meta){
 prior<-done[[task]]
 if(!is.null(prior)){
   if(prior$status!='ok')stop('Recorded unsuccessful call. Explicit recovery required: ',task)
   return(prior)
 }
 payload<-c(list(model=cfg$model),cfg$generation)
 if(cfg$protocol=='anthropic'){
   payload$system<-msg[[1]]$content;payload$messages<-msg[-1]
 }else payload$messages<-msg
 body<-mjson(payload)
 reserve<-(nchar(body,type='bytes')*20+payload$max_tokens*50)/1e6
 if(Sys.time()>deadline||used+reserve>limit||length(attempts)>=600)stop('Deadline/cost/call guard reached')
 aid<-paste0(task,':http0')
 ar<-list(task_id=task,attempt_id=aid,time=now(),reservation_cny=reserve)
 mappend(ar,ap);attempts[[length(attempts)+1]]<<-ar
 rec<-c(list(task_id=task,attempt_id=aid,provider=provider,stage=stage,split=split,time=now(),request=payload,request_sha256=digest::digest(body,algo='sha256',serialize=FALSE)),meta)
 suffix<-if(cfg$protocol=='anthropic')'/messages' else '/chat/completions'
 url<-paste0(sub('/$','',cfg$base_url),suffix)
 stopifnot(url%in%c('https://api.deepseek.com/chat/completions','https://api.moonshot.cn/v1/chat/completions','http://www.bio8.cs.hku.hk:8080/v1/messages'))
 h<-curl::new_handle();headers<-list('Content-Type'='application/json')
 if(cfg$protocol=='anthropic'){headers[['x-api-key']]<-Sys.getenv(cfg$api_key_env);headers[['anthropic-version']]<-'2023-06-01'}else headers[['Authorization']]<-paste('Bearer',Sys.getenv(cfg$api_key_env))
 curl::handle_setheaders(h,.list=headers)
 curl::handle_setopt(h,postfields=body,timeout=150,connecttimeout=30,followlocation=FALSE)
 start<-Sys.time()
 response<-tryCatch(curl::curl_fetch_memory(url,h),error=function(e)NULL)
 rec$latency_seconds<-as.numeric(difftime(Sys.time(),start,units='secs'))
 rec$status<-'transport_error';rec$cost_guard_cny<-reserve
 if(!is.null(response)){
   rec$http_status<-response$status_code
   if(response$status_code==200){
     raw<-tryCatch(jsonlite::fromJSON(rawToChar(response$content),simplifyVector=FALSE),error=function(e)NULL)
     if(!is.null(raw)){
       rec$raw_response<-raw;u<-raw$usage %||% list();rec$usage<-u
       if(cfg$protocol=='anthropic'){
         rec$text<-paste(vapply(Filter(function(b)identical(b$type,'text'),raw$content),function(b)b$text,''),collapse='\n')
         rec$finish_reason<-raw$stop_reason
         rec$input_tokens<-sum(unlist(u[c('input_tokens','cache_creation_input_tokens','cache_read_input_tokens')]))
         rec$output_tokens<-u$output_tokens %||% 0
         rec$status<-if(identical(raw$stop_reason,'end_turn'))'ok' else 'incomplete'
       }else{
         choice<-raw$choices[[1]];rec$text<-choice$message$content %||% '';rec$finish_reason<-choice$finish_reason
         rec$input_tokens<-u$prompt_tokens %||% 0;rec$output_tokens<-u$completion_tokens %||% 0
         rec$status<-if(identical(choice$finish_reason,'stop'))'ok' else 'incomplete'
       }
       if(length(u)>0)rec$cost_guard_cny<-(rec$input_tokens*20+rec$output_tokens*50)/1e6
     }
   }
 }
 mappend(rec,rp);used<<-used+rec$cost_guard_cny;records[[length(records)+1]]<<-rec;done[[task]]<<-rec
 cat(task,rec$status,sprintf('guard=%.4f',used),'\n');flush.console()
 if(rec$status!='ok')stop('Collection paused after unsuccessful request; original record preserved.')
 rec
}
if(stage=='materials'){
 for(q in qs)for(truth in c('correct','wrong'))for(a in 0:1){
   task<-paste(q$question_id,provider,truth,MVERSION,paste0('a',a),sep=':')
   r<-invoke(task,material_messages(q,truth),list(question_id=q$question_id,truth=truth,generation_attempt=a))
   obj<-parse_json(r$text);target<-q[[if(truth=='correct')'gold' else 'wrong']]
   if(match_answer(obj,target,q$tolerance)&&is.character(obj$reason)&&nchar(obj$reason)>30)break
 }
}else{
 matfile<-file.path(MROOT,'protocol',paste0('materials-',split,'.json'))
 frozen<-read_json(file.path(MROOT,'protocol',paste0('freeze-',split,'.json')))
 stopifnot(identical(file_sha(matfile),frozen$materials_sha256))
 materials<-read_json(matfile)
 qs<-Filter(function(q)q$question_id%in%unlist(frozen$question_ids),qs)
 reps<-if(split=='development')1 else 2
 set.seed(25011002+match(provider,MODELS))
 units<-expand.grid(q=seq_along(qs),r=0:(reps-1));units<-units[sample(nrow(units)),,drop=FALSE]
 for(i in seq_len(nrow(units))){
   q<-qs[[units$q[i]]];rr<-units$r[i];prefix<-paste(q$question_id,provider,paste0('r',rr),sep=':')
   meta<-list(question_id=q$question_id,repeat_id=rr,donor=generator(provider,q))
   b<-invoke(paste0(prefix,':baseline'),receiver_messages(q),c(meta,list(condition='baseline')))
   for(cond in sample(paste0('C',0:5))){
     key<-if(cond=='C0')NULL else paste(q$question_id,meta$donor,if(cond%in%c('C4','C5'))'correct' else 'wrong',sep=':')
     m<-if(is.null(key))NULL else materials[[key]]
     if(cond!='C0')stopifnot(!is.null(m))
     invoke(paste0(prefix,':',cond),receiver_messages(q,cond,b$text,m),c(meta,list(condition=cond,baseline_id=b$task_id,material_id=key,material_sha256=if(is.null(m))NULL else digest::digest(mjson(m),algo='sha256',serialize=FALSE))))
   }
 }
}
cat('Stage finished:',stage,split,provider,'\n')
