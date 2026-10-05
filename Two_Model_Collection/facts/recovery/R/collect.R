source('Two_Model_Collection/facts/recovery/R/common.R')
freeze<-fromJSON(file.path(rc_root,'protocol/freeze.json'),simplifyVector=FALSE)
for(p in names(freeze$files_sha256))stopifnot(identical(digest(file=p,algo='sha256'),freeze$files_sha256[[p]]))
plan<-fromJSON(file.path(rc_root,'protocol/plan.json'),simplifyVector=FALSE)
cfgs<-fromJSON('Two_Model_Collection/protocol/models.json',simplifyVector=FALSE)
tasks<-read.csv(file.path(rc_original,'protocol/tasks.csv'),stringsAsFactors=FALSE,na.strings=NULL)
prompts<-fromJSON(file.path(rc_original,'protocol/prompts.json'),simplifyVector=FALSE)$questions
prompts<-setNames(prompts,tm_fields(prompts,'question_id'))
original<-tm_read(file.path(rc_original,'runs/completed.jsonl'));orig_http<-tm_read(file.path(rc_original,'runs/http_responses.jsonl'))
working<-setNames(original,tm_fields(original,'id'))
tm_load_credentials()
ap<-file.path(rc_root,'runs/attempts.jsonl');hp<-file.path(rc_root,'runs/http_responses.jsonl')
cp<-file.path(rc_root,'runs/completed.jsonl');bp<-file.path(rc_root,'runs/blocked.jsonl')
old_attempts<-tm_read(ap);all_http<-tm_read(hp);terminals<-tm_read(cp);blocked<-tm_read(bp)
if(length(setdiff(tm_fields(old_attempts,'id'),tm_fields(all_http,'id'))))stop('Unresolved recovery HTTP attempt; inspect before any retry')
for(r in terminals)working[[r$id]]<-r
save_status<-function(status){tm_write(list(time=tm_now(),status=status,direct_planned=14,dependency_candidates=24,
 terminal_recovery_tasks=length(terminals),dependency_still_blocked=length(blocked),http_attempts=length(all_http),
 added_guard_cny=sum(vapply(all_http,function(r)r$guard_cny,0)),budget_enforced=FALSE),file.path(rc_root,'runs/status.json'))}
run_one<-function(task,payload,kind,provenance){
 previous<-Filter(function(r)identical(r$task_id,task$id),all_http)
 if(length(previous)>2L)stop('Recovery maximum attempts violated')
 if(length(previous)&&!identical(previous[[1]]$request_sha256,digest(tm_json(payload),'sha256',serialize=FALSE)))stop('Recovery payload changed across attempts')
 repeat{
  r<-if(length(previous))tail(previous,1)[[1]]else NULL
  if(!is.null(r)&&(!rc_retryable(r)||length(previous)>=2L))break
  r<-rc_http(task,payload,cfgs[[task$provider]],length(previous)+1L)
  all_http[[length(all_http)+1L]]<<-r;previous[[length(previous)+1L]]<-r
  save_status('running')
  if(!is.null(r$http_status)&&r$http_status%in%c(401L,403L,429L)){
   save_status('provider_auth_or_quota_stopped');stop('Provider auth/quota stop; no automatic retry')
  }
 }
 result<-rc_record(task,r,kind,c(provenance,list(recovery_attempts=length(previous))))
 tm_append(result,cp);terminals[[length(terminals)+1L]]<<-result;working[[task$id]]<<-result
 cat('facts recovery',length(terminals),'terminal tasks;',length(all_http),'HTTP; guard',sum(vapply(all_http,function(x)x$guard_cny,0)),'\n');flush.console()
 save_status('running')
}
lock<-file.path(rc_root,'runs/collector.lock');stopifnot(dir.create(lock,showWarnings=FALSE))
tryCatch({
 save_status('running')
 for(p in plan$direct_recovery_tasks){
  if(p$id%in%tm_fields(terminals,'id'))next
  task<-as.list(tasks[match(p$id,tasks$id),]);h<-orig_http[[match(p$original_http_id,tm_fields(orig_http,'id'))]]
  stopifnot(identical(digest(tm_json(h$request),'sha256',serialize=FALSE),p$original_request_sha256))
  run_one(task,h$request,p$kind,list(original_http_id=p$original_http_id,original_request_sha256=p$original_request_sha256,
   payload_equal_to_original=TRUE,changed_parameters=list(timeout_seconds=600)))
 }
 for(id in unlist(plan$dependency_skip_candidates)){
  if(id%in%c(tm_fields(terminals,'id'),tm_fields(blocked,'id')))next
  task<-as.list(tasks[match(id,tasks$id),]);deps<-c(task$baseline_id,task$donor_id);deps<-deps[nzchar(deps)]
  bad<-deps[!vapply(deps,function(d)tm_usable(working[[d]]),TRUE)]
  if(length(bad)){
   b<-list(id=id,reason='dependencies_still_unusable',dependency_ids=bad,
    statuses=setNames(lapply(bad,function(d)working[[d]]$status%or%'missing'),bad),time=tm_now())
   tm_append(b,bp);blocked[[length(blocked)+1L]]<-b;next
  }
  payload<-tm_payload(task,prompts[[task$question_id]],working,cfgs[[task$provider]],'facts')
  run_one(task,payload,'newly_available_dependency',list(original_dependency_skip=TRUE,
   dependency_http_ids=setNames(lapply(deps,function(d)working[[d]]$http_id),deps),max_tokens=768))
 }
 save_status('finished')
},finally=unlink(lock,recursive=TRUE))
