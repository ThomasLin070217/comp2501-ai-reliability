# Freeze the technical recovery appendix before any new provider call.
source('Two_Model_Collection/facts/recovery/R/common.R')
stopifnot(!file.exists(file.path(rc_root,'protocol/freeze.json')))
for(d in c('protocol','runs','reports','derived'))dir.create(file.path(rc_root,d),recursive=TRUE,showWarnings=FALSE)
records<-tm_read(file.path(rc_original,'runs/completed.jsonl'))
http<-tm_read(file.path(rc_original,'runs/http_responses.jsonl'))
tasks<-read.csv(file.path(rc_original,'protocol/tasks.csv'),stringsAsFactors=FALSE)
skips<-tm_read(file.path(rc_original,'runs/skipped.jsonl'))
direct<-Filter(function(r)r$status%in%c('transport_error','incomplete'),records)
stopifnot(length(direct)==14L,sum(tm_fields(direct,'status')=='transport_error')==9L)
plans<-lapply(direct,function(r){
 h<-http[[match(r$http_id,tm_fields(http,'id'))]]
 stopifnot(identical(digest(tm_json(h$request),'sha256',serialize=FALSE),r$request_sha256),h$request$max_tokens==768L)
 errors<-unlist(lapply(h$raw_response$content%or%list(),function(b)if(identical(b$type,'web_search_tool_result'))
   lapply(b$content%or%list(),function(z)z$error_code%or%NULL)else NULL))
 undeclared_json<-any(vapply(h$raw_response$content%or%list(),function(b)identical(b$type,'tool_use')&&identical(b$name,'json'),TRUE))
 list(id=r$id,kind=if(r$status=='transport_error')'transport_exact_payload'else'tool_protocol_exact_payload',
  original_status=r$status,original_finish_reason=r$finish_reason%or%NULL,
  original_http_id=r$http_id,original_request_sha256=r$request_sha256,
  search_max_uses_exceeded='max_uses_exceeded'%in%errors,undeclared_json_tool_call=undeclared_json,
  max_recovery_attempts=2L,max_tokens=768L,payload_changed=FALSE)
})
plans<-plans[order(match(tm_fields(plans,'id'),tasks$id))]
tm_write(list(status='frozen_recovery_design',date=tm_now(),original_targets=1600L,
 direct_recovery_tasks=plans,dependency_skip_candidates=tm_fields(skips,'id'),
 retry_rule='At most two recovery HTTP attempts per task; stop on first end_turn regardless of correctness, abstention or parseability. Retry only transport/invalid-response/server failure or non-end_turn; auth/quota errors stop the collector.',
 same_request_payload_for_all_direct_tasks=TRUE,max_tokens=768L,timeout_seconds=600L,
 incomplete_diagnosis='All five original incomplete outputs stopped with tool_use, not max_tokens. Three exhausted native search uses; two emitted an undeclared json tool call. No tool is manually executed or injected. No token-limit change.',
 dependency_rule='Reconsider each original skipped task only after all required receiver/donor records are strictly usable. Reuse real recovered output and full receiver native history. Keep AI/Human source bodies matched.',
 budget_ceiling=NULL,uncertain_transport_cost_reserve_cny=10,
 primary_records_immutable=TRUE,secondary_analysis='Original and recovery-completed analyses are reported separately.'),file.path(rc_root,'protocol/plan.json'))
# Decisions depend on technical status only; no answer or gold is consulted.
fixtures<-list(list(status='ok',text='wrong answer'),list(status='ok',text=''),
 list(status='ok',text='{"answer":"","abstain":true,"reason":"Unknown"}'))
stopifnot(!any(vapply(fixtures,rc_retryable,TRUE)),rc_retryable(list(status='transport_error')),
 rc_retryable(list(status='incomplete')),rc_retryable(list(status='http_error',http_status=500)),
 !rc_retryable(list(status='http_error',http_status=401)),!rc_retryable(list(status='http_error',http_status=429)))
stopifnot(all(tm_fields(Filter(function(z)z$kind=='tool_protocol_exact_payload',plans),'original_finish_reason')=='tool_use'))
stopifnot(sum(vapply(plans,function(z)z$search_max_uses_exceeded,TRUE))==3,
 sum(vapply(plans,function(z)z$undeclared_json_tool_call,TRUE))==2)
known<-tm_fields(records,'id')
skip_tasks<-tasks[tasks$id%in%tm_fields(skips,'id'),]
for(i in seq_len(nrow(skip_tasks))){ds<-unlist(skip_tasks[i,c('baseline_id','donor_id')]);stopifnot(all(ds[nzchar(ds)]%in%known))}
tm_write(list(status='passed',direct_payload_hashes_verified=14,dependency_graphs_checked=24,
 retry_independent_of_answer=TRUE,original_tool_use_diagnoses_verified=5,no_network_calls=TRUE),file.path(rc_root,'protocol/checks.json'))
files<-c(file.path(rc_original,'runs',c('attempts.jsonl','http_responses.jsonl','completed.jsonl','skipped.jsonl')),
 file.path(rc_original,'protocol',c('tasks.csv','prompts.json','questions.jsonl','scoring.R')),
 'Two_Model_Collection/protocol/models.json','Two_Model_Collection/R/runtime.R','Fact_Prompt_Design/R/prompts.R',
 list.files(file.path(rc_root,'R'),full.names=TRUE),file.path(rc_root,'protocol',c('plan.json','checks.json')))
tm_write(list(frozen_at=tm_now(),files_sha256=setNames(lapply(files,function(p)digest(file=p,algo='sha256')),files)),
 file.path(rc_root,'protocol/freeze.json'))
cat('Recovery frozen: 14 exact-payload technical tasks, 24 conditional dependency candidates; no calls.\n')
