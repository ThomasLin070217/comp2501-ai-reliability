source('Two_Model_Collection/facts/recovery/R/common.R')
f<-fromJSON(file.path(rc_root,'protocol/freeze.json'),simplifyVector=FALSE)
for(p in names(f$files_sha256))stopifnot(identical(digest(file=p,algo='sha256'),f$files_sha256[[p]]))
plan<-fromJSON(file.path(rc_root,'protocol/plan.json'),simplifyVector=FALSE)
original<-tm_read(file.path(rc_original,'runs/completed.jsonl'))
orig_http<-tm_read(file.path(rc_original,'runs/http_responses.jsonl'))
new<-tm_read(file.path(rc_root,'runs/completed.jsonl'));http<-tm_read(file.path(rc_root,'runs/http_responses.jsonl'))
attempts<-tm_read(file.path(rc_root,'runs/attempts.jsonl'));blocked<-tm_read(file.path(rc_root,'runs/blocked.jsonl'))
stopifnot(!anyDuplicated(tm_fields(new,'id')),!anyDuplicated(tm_fields(http,'id')),
 setequal(tm_fields(attempts,'id'),tm_fields(http,'id')),all(table(tm_fields(http,'task_id'))<=2))
tasks<-read.csv(file.path(rc_original,'protocol/tasks.csv'),stringsAsFactors=FALSE,na.strings=NULL)
prompts<-fromJSON(file.path(rc_original,'protocol/prompts.json'),simplifyVector=FALSE)$questions
prompts<-setNames(prompts,tm_fields(prompts,'question_id'))
cfg<-fromJSON('Two_Model_Collection/protocol/models.json',simplifyVector=FALSE)
working<-setNames(original,tm_fields(original,'id'));for(r in new)working[[r$id]]<-r
direct<-setNames(plan$direct_recovery_tasks,tm_fields(plan$direct_recovery_tasks,'id'))
for(h in http){
 task<-as.list(tasks[match(h$task_id,tasks$id),]);stopifnot(h$timeout_seconds==600,
  identical(digest(tm_json(h$request),'sha256',serialize=FALSE),h$request_sha256),h$request$max_tokens==768)
 if(h$task_id%in%names(direct)){
  p<-direct[[h$task_id]];stopifnot(identical(h$request_sha256,p$original_request_sha256))
 }else{
  expected<-tm_payload(task,prompts[[task$question_id]],working,cfg[[task$provider]],'facts')
  stopifnot(identical(tm_json(expected),tm_json(h$request)))
 }
 prev<-Filter(function(z)z$task_id==h$task_id&&z$attempt_no<h$attempt_no,http)
 if(length(prev))stopifnot(all(vapply(prev,rc_retryable,TRUE)))
}
for(r in new){
 rows<-Filter(function(h)h$task_id==r$id,http);first_ok<-which(tm_fields(rows,'status')=='ok')
 chosen<-if(length(first_ok))rows[[first_ok[1]]]else tail(rows,1)[[1]]
 stopifnot(identical(chosen$id,r$http_id),identical(chosen$text%or%'',r$text))
 if(r$status=='ok')stopifnot(identical(r$transcript[[1]]$content,chosen$raw_response$content))
}
stopifnot(length(new)+length(blocked)==14+24)
tm_write(list(status='passed',original_frozen_hashes_unchanged=TRUE,requests_audited=length(http),
 recovery_terminal_tasks=length(new),remaining_blocked=length(blocked),
 all_direct_payloads_unchanged=TRUE,max_tokens=768,timeout_seconds=600,
 at_most_two_attempts=TRUE,only_technical_failures_retried=TRUE,
 actual_recovered_dependencies_and_native_history_checked=TRUE,
 added_guard_cny=sum(vapply(http,function(h)h$guard_cny,0))),file.path(rc_root,'reports/integrity.json'))
cat('Recovery integrity checks passed:',length(http),'requests,',length(new),'selected records,',length(blocked),'blocked.\n')
