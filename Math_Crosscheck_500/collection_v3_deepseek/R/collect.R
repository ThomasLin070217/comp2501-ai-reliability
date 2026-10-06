# DeepSeek-only initial-answer collector for frozen GSM-Plus v3 tasks.
suppressPackageStartupMessages({library(jsonlite);library(curl);library(digest)})
`%or%` <- function(x,y) if(is.null(x))y else x
root <- normalizePath('.',winslash='/')
base <- file.path(root,'Math_Crosscheck_500/collection_v3_deepseek')
protocol <- file.path(base,'protocol'); runs <- file.path(base,'runs')
dir.create(runs,recursive=TRUE,showWarnings=FALSE)
lock <- file.path(runs,'collector.lock')
if(!dir.create(lock,showWarnings=FALSE)) stop('Collector lock exists; inspect before resuming.')
lg<-new.env(parent=emptyenv());reg.finalizer(lg,function(e)unlink(lock,recursive=TRUE,force=TRUE),onexit=TRUE)
writeLines(c(paste0('pid=',Sys.getpid()),paste0('started_at=',format(Sys.time(),tz='UTC',usetz=TRUE))),file.path(lock,'owner.txt'))
sha<-function(x)digest(file=x,algo='sha256')
read_jsonl<-function(p){if(!file.exists(p)||!file.info(p)$size)return(list());z<-readLines(p,warn=FALSE);if(any(!nzchar(z)))stop('Blank JSONL line: ',p);lapply(z,fromJSON,simplifyVector=FALSE)}
now<-function()format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC')
manifest<-fromJSON(file.path(protocol,'run_manifest.json'),simplifyVector=FALSE)
tasks_path<-file.path(protocol,'tasks_deepseek_500.csv');tasks<-read.csv(tasks_path,stringsAsFactors=FALSE,check.names=FALSE)
q_path<-file.path(root,'Math_Crosscheck_500/question_review_v3/model_inputs_500.csv')
k_path<-file.path(root,'Math_Crosscheck_500/question_review_v3/scoring_key_500.csv')
stopifnot(nrow(tasks)==500L,all(tasks$provider=='deepseek'),all(tasks$model=='deepseek-v4-pro'),all(tasks$repeat_id==1L),
  identical(sha(q_path),manifest$hashes$question_input),identical(sha(k_path),manifest$hashes$scoring_key),
  identical(sha(file.path(root,'Math_Crosscheck_500/question_review_v3/review_manifest.json')),manifest$hashes$review_manifest),
  identical(sha(tasks_path),manifest$hashes$task_manifest),
  identical(sha(file.path(base,'R/collect.R')),manifest$hashes$collector_code),
  identical(sha(file.path(base,'R/prepare.R')),manifest$hashes$prepare_code),
  identical(sha(file.path(root,'Two_Model_Collection/protocol/models.json')),manifest$hashes$provider_settings),!anyDuplicated(tasks$task_id))
models<-fromJSON(file.path(root,'Two_Model_Collection/protocol/models.json'),simplifyVector=FALSE)$deepseek
stopifnot(identical(models$model,'deepseek-v4-pro'),identical(models$protocol,'anthropic'))
ptr<-'/private/tmp/comp2501-two-model-credential-path.txt'
if(!file.exists(ptr))stop('Secure credential pointer unavailable.')
cp<-readLines(ptr,warn=FALSE);if(length(cp)!=1L||!startsWith(cp,'/private/tmp/')||!file.exists(cp))stop('Credential location invalid.')
creds<-readRDS(cp);if(!'DEEPSEEK_API_KEY'%in%names(creds)||!nzchar(creds$DEEPSEEK_API_KEY))stop('DeepSeek credential unavailable.')
Sys.setenv(DEEPSEEK_API_KEY=creds$DEEPSEEK_API_KEY);rm(creds)
if('--preflight'%in%commandArgs(trailingOnly=TRUE)){cat('Preflight passed: 500 frozen DeepSeek-only tasks, secure credential loaded, collector/hash/config bindings valid; no provider request sent.\n');quit(save='no',status=0)}
key<-Sys.getenv('DEEPSEEK_API_KEY');stopifnot(nzchar(key))
args<-commandArgs(trailingOnly=TRUE)
pilot_pos<-match('--pilot',args)
pilot_limit<-if(is.na(pilot_pos))500L else {
  if(pilot_pos==length(args))stop('--pilot requires a positive task count.')
  z<-suppressWarnings(as.integer(args[pilot_pos+1L]));if(is.na(z)||z<1L||z>500L)stop('Invalid --pilot count.')
  z
}
ap<-file.path(runs,'attempts.jsonl');rp<-file.path(runs,'http_responses.jsonl');cpth<-file.path(runs,'completed.jsonl');sp<-file.path(runs,'status.json')
append<-function(x,p){z<-toJSON(x,auto_unbox=TRUE,null='null',digits=NA);if(grepl(key,z,fixed=TRUE))stop('Credential leakage guard blocked a record.');cat(z,'\n',file=p,append=TRUE,sep='')}
status_write<-function(x)write_json(x,sp,pretty=TRUE,auto_unbox=TRUE,null='null')
attempts<-read_jsonl(ap);responses<-read_jsonl(rp);completed<-read_jsonl(cpth)
ids<-vapply(tasks$task_id,identity,''); aid<-vapply(attempts,function(x)x$attempt_id%or%'',''); rid<-vapply(responses,function(x)x$attempt_id%or%'',''); cid<-vapply(completed,function(x)x$task_id%or%'','')
if(anyDuplicated(aid)||anyDuplicated(rid)||anyDuplicated(cid)||any(!aid%in%rid)||any(!rid%in%aid)||any(!cid%in%ids))stop('Attempt/response/completed ledger inconsistency; audit before continuing.')
if(length(aid)){a_task<-vapply(attempts,function(x)x$task_id%or%'','');r_task<-vapply(responses,function(x)x$task_id%or%'','');if(any(!a_task%in%ids)||any(!r_task%in%ids))stop('Unexpected task ID in run ledger.')}
unknown<-vapply(responses,function(x)identical(x$status,'unknown_delivery'),TRUE)
if(any(unknown)||length(setdiff(aid,rid))){status_write(list(state='stopped_unknown_delivery',time=now(),planned=500L,completed=length(unique(cid))));stop('Unknown request outcome detected. Reconcile before resending any task.')}
# Recover only the crash window after a complete HTTP response was durably saved.
for(r in responses){if(r$status%in%c('ok','incomplete')&&!r$task_id%in%cid){t<-tasks[match(r$task_id,tasks$task_id),];o<-list(task_id=r$task_id,eval_id=t$eval_id,question_order=t$question_order,provider='deepseek',status=r$status,text=r$text,finish_reason=r$finish_reason,http_status=r$http_status,request_sha256=r$request_sha256,input_tokens=r$input_tokens,output_tokens=r$output_tokens,cache_read_input_tokens=r$cache_read_input_tokens,cache_creation_input_tokens=r$cache_creation_input_tokens,search_calls=r$search_calls,search_results=r$search_results,completed_at=now());append(o,cpth);completed[[length(completed)+1]]<-o;cid<-c(cid,r$task_id)}}
stopifnot(!anyDuplicated(cid))
headers<-list('Content-Type'='application/json','x-api-key'=key,'anthropic-version'='2023-06-01')
request_body<-function(t){toJSON(list(model=models$model,temperature=0.6,max_tokens=2048L,thinking=list(type='disabled'),stream=FALSE,tools=list(list(type='web_search_20250305',name='web_search')),messages=list(list(role='user',content=t$input_text))),auto_unbox=TRUE,null='null',digits=NA)}
rec_status<-function(x)x$status%or%''
write_status<-function(state){all_ids<-vapply(completed,function(x)x$task_id,'');it<-sum(vapply(responses,function(x)as.numeric(x$input_tokens%or%0),0));ot<-sum(vapply(responses,function(x)as.numeric(x$output_tokens%or%0),0));sc<-sum(vapply(responses,function(x)as.numeric(x$search_calls%or%0),0));st<-list(state=state,updated_at=now(),planned=500L,completed=length(unique(all_ids)),remaining=500L-length(unique(all_ids)),first_100_completed=sum(vapply(completed,function(x)x$task_id%in%tasks$task_id[tasks$batch=='first_100'],TRUE)),http_attempts=length(attempts),known_http_responses=length(responses),unknown_delivery=sum(vapply(responses,function(x)identical(x$status,'unknown_delivery'),TRUE)),input_tokens=it,output_tokens=ot,native_search_calls=sc,conservative_guard_cny=(it*20+ot*50)/1e6+sc*.08,actual_charge='unknown; guard is not an invoice');status_write(st);invisible(st)}
write_status('running')
repeat{
 done_ids<-vapply(completed,function(x)x$task_id,'');pending<-tasks[!tasks$task_id%in%done_ids,,drop=FALSE]
 if(!nrow(pending))break
 if(length(unique(done_ids))>=pilot_limit)break
 # Finish the first 100 checkpoint before starting the remaining 400.
 first_pending<-pending[pending$batch=='first_100',,drop=FALSE];batch<-if(nrow(first_pending))first_pending else pending
 wave<-batch[seq_len(min(2L,nrow(batch),pilot_limit-length(unique(done_ids)))),,drop=FALSE]
 pool<-new_pool(total_con=2L,host_con=2L,multiplex=FALSE);env<-new.env(parent=emptyenv());env$items<-list();wave_attempts<-list()
 for(i in seq_len(nrow(wave))){t<-as.list(wave[i,,drop=FALSE]);hist<-Filter(function(x)identical(x$task_id,t$task_id),responses);hist_attempts<-Filter(function(x)identical(x$task_id,t$task_id),attempts)
  if(any(vapply(hist,function(x)identical(x$status,'unknown_delivery'),TRUE)))stop('Unknown delivery blocks task resend.')
  if(length(hist_attempts)>=2L)stop('Known retry limit already exhausted.')
  payload<-request_body(t);rid<-digest(payload,algo='sha256',serialize=FALSE);an<-length(hist_attempts)+1L;att<-list(attempt_id=paste0(t$task_id,':http',an),task_id=t$task_id,attempt_no=an,started_at=now(),request_sha256=rid)
  att$request_payload<-fromJSON(payload,simplifyVector=FALSE);append(att,ap);attempts[[length(attempts)+1]]<-att;wave_attempts[[t$task_id]]<-att
  h<-new_handle(url=paste0(models$base_url,'/messages'));handle_setheaders(h,.list=headers);handle_setopt(h,postfields=payload,timeout=240,connecttimeout=20,followlocation=FALSE)
  local({ii<-i;tt<-t;aa<-att;hh<-h;rr<-rid;force(ii);force(tt);force(aa);force(hh);force(rr)
   done_cb<-function(res){x<-list(attempt_id=aa$attempt_id,task_id=tt$task_id,request_sha256=rr,finished_at=now(),latency_seconds=as.numeric(difftime(Sys.time(),as.POSIXct(aa$started_at,format='%Y-%m-%dT%H:%M:%SZ',tz='UTC'),units='secs')))
    x$http_status<-as.integer(res$status_code);body<-rawToChar(res$content);parsed<-tryCatch(fromJSON(body,simplifyVector=FALSE),error=function(e)NULL);x$raw_response<-parsed
    if(x$http_status==200L&&!is.null(parsed)){blocks<-parsed$content%or%list();tb<-Filter(function(b)identical(b$type,'text'),blocks);x$text<-paste(vapply(tb,function(b)b$text%or%'',''),collapse='\n');x$finish_reason<-parsed$stop_reason%or%'';x$status<-if(identical(x$finish_reason,'end_turn'))'ok'else'incomplete';u<-parsed$usage%or%list();x$usage<-u;x$input_tokens<-as.numeric(u$input_tokens%or%0);x$output_tokens<-as.numeric(u$output_tokens%or%0);x$cache_read_input_tokens<-as.numeric(u$cache_read_input_tokens%or%0);x$cache_creation_input_tokens<-as.numeric(u$cache_creation_input_tokens%or%0);x$search_calls<-sum(vapply(blocks,function(b)identical(b$type,'server_tool_use')&&identical(b$name,'web_search'),TRUE));x$search_results<-sum(vapply(blocks,function(b)identical(b$type,'web_search_tool_result'),TRUE))
    }else{x$status<-if(x$http_status==200L)'invalid_json_response'else if(x$http_status%in%c(401L,403L,408L,425L,429L)||x$http_status>=500L)'http_error'else'http_error';x$retryable<-x$http_status>=500L&&x$http_status<600L;x$error_detail<-if(is.null(parsed))substr(body,1,1000)else parsed$error$type%or%''}
    env$items[[length(env$items)+1]]<-x}
   fail_cb<-function(msg){env$items[[length(env$items)+1]]<-list(attempt_id=aa$attempt_id,task_id=tt$task_id,request_sha256=rr,status='unknown_delivery',error_detail=as.character(msg),finished_at=now())}
   curl::multi_add(hh,done=done_cb,fail=fail_cb,pool=pool)
  })
 }
 while(length(env$items)<nrow(wave))curl::multi_run(timeout=30,poll=TRUE,pool=pool)
 critical<-FALSE;retry500<-FALSE
 for(x in env$items){append(x,rp);responses[[length(responses)+1]]<-x;if(identical(x$status,'unknown_delivery'))critical<-TRUE;if(isTRUE(x$http_status%in%c(401L,402L,403L,429L)))critical<-TRUE;if(isTRUE(x$retryable)&&wave_attempts[[x$task_id]]$attempt_no<2L)retry500<-TRUE
  if(x$status%in%c('ok','incomplete')){t<-tasks[match(x$task_id,tasks$task_id),];o<-list(task_id=x$task_id,eval_id=t$eval_id,question_order=t$question_order,provider='deepseek',repeat_id=1L,origin='independent_initial',status=x$status,text=x$text,finish_reason=x$finish_reason,http_status=x$http_status,request_sha256=x$request_sha256,input_tokens=x$input_tokens,output_tokens=x$output_tokens,cache_read_input_tokens=x$cache_read_input_tokens,cache_creation_input_tokens=x$cache_creation_input_tokens,search_calls=x$search_calls,search_results=x$search_results,completed_at=now());append(o,cpth);completed[[length(completed)+1]]<-o}
 }
 if(critical){write_status(if(any(vapply(env$items,function(x)identical(x$status,'unknown_delivery'),TRUE)))'stopped_unknown_delivery'else'stopped_auth_or_quota');stop('Provider/auth/quota/unknown-delivery stop. Raw attempt and response records preserved.')}
 write_status('running');cat('DeepSeek completed',length(unique(vapply(completed,function(x)x$task_id,''))),'/500 | attempts',length(attempts),'\n');flush.console()
 # Known 5xx is retried once, identically, on next loop.
 if(retry500)next
}
if(length(unique(vapply(completed,function(x)x$task_id,'')))<500L){write_status('pilot_paused');cat('Pilot paused with frozen tasks remaining.\n')}else{write_status('finished');cat('All 500 DeepSeek tasks have terminal model responses (including any incomplete outputs).\n')}
