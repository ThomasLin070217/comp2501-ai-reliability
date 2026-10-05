source('Two_Model_Collection/math/recovery/R/common.R')
run_recovery<-function(){
 freeze<-fromJSON(file.path(REC,'protocol/freeze.json'),simplifyVector=FALSE)
 for(p in names(freeze$files_sha256))stopifnot(identical(digest(file=p,algo='sha256'),freeze$files_sha256[[p]]))
 stopifnot(!dir.exists(file.path(MAIN,'runs/collector.lock')))
 lock<-file.path(REC,'runs/collector.lock');stopifnot(dir.create(lock,showWarnings=FALSE));on.exit(unlink(lock,recursive=TRUE),add=TRUE)
 tm_load_credentials();cfgs<-fromJSON('Two_Model_Collection/protocol/models.json',simplifyVector=FALSE)
 plan<-read.csv(file.path(REC,'protocol/plan.csv'),stringsAsFactors=FALSE,na.strings=NULL)
 prompts<-fromJSON(file.path(MAIN,'protocol/prompts.json'),simplifyVector=FALSE)$questions;prompts<-setNames(prompts,tm_fields(prompts,'question_id'))
 original<-tm_read(file.path(MAIN,'runs/completed.jsonl'));done<-setNames(original,tm_fields(original,'id'))
 orig_http<-tm_read(file.path(MAIN,'runs/http_responses.jsonl'));orig_http<-setNames(orig_http,tm_fields(orig_http,'task_id'))
 ap<-file.path(REC,'runs/attempts.jsonl');hp<-file.path(REC,'runs/http_responses.jsonl');cp<-file.path(REC,'runs/completed.jsonl');bp<-file.path(REC,'runs/blocked.jsonl')
 http<-tm_read(hp);records<-tm_read(cp);blocked<-tm_read(bp);attempts<-tm_read(ap)
 if(length(setdiff(tm_fields(attempts,'id'),tm_fields(http,'id'))))stop('Unresolved recovery request; do not retry until separately audited')
 for(r in records)done[[r$id]]<-r
 charged<-function()sum(vapply(http,function(r)r$guard_cny,0))
 task_http<-function(id)Filter(function(r)identical(sub(':recovery[12]$','',r$task_id),id),http)
 finished_ids<-function(){
  ids<-vapply(plan$id,function(id){x<-task_http(id);length(x)&&(!recovery_eligible(tail(x,1)[[1]])||length(x)>=2L)},TRUE)
  union(plan$id[ids],tm_fields(blocked,'id'))
 }
 save_status<-function(state){tm_write(list(time=tm_now(),status=state,planned=nrow(plan),
 terminal_targets=length(finished_ids()),remaining=nrow(plan)-length(finished_ids()),
 recovery_attempts=length(http),blocked=length(blocked),guard_cny=charged()),file.path(REC,'runs/status.json'))}
 save_status('running')
 repeat{
  if(file.exists('Two_Model_Collection/STOP_ALL')){save_status('global_stop');return(invisible(NULL))}
  pending<-plan[!plan$id%in%finished_ids(),];if(!nrow(pending))break
  pending<-pending[pending$phase==min(pending$phase),];jobs<-list()
  for(i in seq_len(nrow(pending))){
   task<-as.list(pending[i,]);prev<-task_http(task$id);n<-length(prev)+1L;stopifnot(n<=2L)
   if(is.null(orig_http[[task$id]])&&!length(prev)){
    deps<-c(task$baseline_id,task$donor_id);deps<-deps[nzchar(deps)]
    if(any(!vapply(deps,function(id)tm_usable(done[[id]]),TRUE))){
     b<-c(task,list(reason='required_final_baseline_or_donor_still_unavailable',time=tm_now()));tm_append(b,bp);blocked[[length(blocked)+1]]<-b;next
    }
   }
   input<-recovery_payload(task,orig_http,prev,done,prompts,cfgs)
   original_id<-task$id;task$id<-paste0(original_id,':recovery',n)
   jobs[[length(jobs)+1]]<-list(task=task,payload=input$payload,original_id=original_id,attempt_number=n,mode=input$mode)
   if(length(jobs)>=4L)break
  }
  if(!length(jobs))next
  answers<-recovery_http_batch(jobs,cfgs,ap,hp,charged(),Inf)
  fatal<-FALSE
  for(i in seq_along(jobs)){
   j<-jobs[[i]];r<-answers[[i]];http[[length(http)+1]]<-r
   stopifnot(identical(r$request_sha256,digest(tm_json(j$payload),'sha256',serialize=FALSE)))
   task<-j$task;task$id<-j$original_id
   out<-c(task,list(status=r$status,text=r$text%or%'',completed_at=tm_now(),http_id=r$id,
    recovery_attempt=j$attempt_number,recovery_mode=j$mode,source='technical_recovery_appendix',
    request_sha256=r$request_sha256,guard_cny=r$guard_cny,search_requested=r$search_requested%or%0,
    search_result_blocks=r$search_result_blocks%or%0,finish_reason=r$finish_reason%or%NULL,
    transcript=if(r$status=='ok')list(list(role='assistant',content=r$raw_response$content))else NULL))
   tm_append(out,cp);records[[length(records)+1]]<-out;done[[out$id]]<-out
   if(!is.null(r$http_status)&&r$http_status%in%c(401,403,429))fatal<-TRUE
  }
  save_status('running');cat('math recovery terminal',length(finished_ids()),'/',nrow(plan),'attempts',length(http),'guard',round(charged(),3),'\n');flush.console()
  if(fatal){save_status('provider_stopped');return(invisible(NULL))}
 }
 save_status('finished');cat('Recovery fixed plan complete.\n')
}
if(sys.nframe()==0L)run_recovery()
