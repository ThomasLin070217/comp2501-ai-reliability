# Acquisition integrity audit. Read-only on responses; no credentials or model calls.
source('Two_Model_Collection/R/runtime.R')
root<-'Two_Model_Collection/math'
tasks<-read.csv(file.path(root,'protocol/tasks.csv'),stringsAsFactors=FALSE,na.strings=NULL)
prompts<-fromJSON(file.path(root,'protocol/prompts.json'),simplifyVector=FALSE)$questions
prompts<-setNames(prompts,tm_fields(prompts,'question_id'))
records<-tm_read(file.path(root,'runs/completed.jsonl'));http<-tm_read(file.path(root,'runs/http_responses.jsonl'))
attempts<-tm_read(file.path(root,'runs/attempts.jsonl'));skips<-tm_read(file.path(root,'runs/skipped.jsonl'))
done<-setNames(records,tm_fields(records,'id'));requests<-setNames(http,tm_fields(http,'task_id'))
cfgs<-fromJSON('Two_Model_Collection/protocol/models.json',simplifyVector=FALSE)
checks<-list();check<-function(n,v){checks[[n]]<<-isTRUE(v);if(!isTRUE(v))stop(n)}
check('unique_completed_tasks',!anyDuplicated(tm_fields(records,'id')))
check('all_completed_in_frozen_plan',all(tm_fields(records,'id')%in%tasks$id))
check('unique_http_attempts',!anyDuplicated(tm_fields(attempts,'id')))
check('completed_and_skipped_disjoint',!length(intersect(tm_fields(records,'id'),tm_fields(skips,'id'))))
check('all_requests_allow_search_without_forcing',all(vapply(http,function(r)identical(r$request$tools[[1]]$name,'web_search')&&is.null(r$request$tool_choice),TRUE)))
for(r in records){
 task<-as.list(tasks[match(r$id,tasks$id),]);original<-requests[[r$id]]
 reconstructed<-tm_payload(task,prompts[[r$question_id]],done,cfgs[[r$provider]],'math')
 if(!identical(tm_json(original$request),tm_json(reconstructed)))stop('Request/history reconstruction mismatch: ',r$id)
 if(!identical(original$request_sha256,digest(tm_json(reconstructed),'sha256',serialize=FALSE)))stop('Request hash mismatch: ',r$id)
}
check('every_record_request_reconstructed_from_frozen_prompts_and_actual_dependencies',TRUE)
ai<-Filter(function(r)r$condition%in%c('A0_AI','A1_AI'),records)
paired<-0L
for(r in ai){
 human_id<-sub('_AI$','_Human',r$id);h<-done[[human_id]]
 if(is.null(h))next
 a<-tail(requests[[r$id]]$request$messages,1)[[1]]$content
 b<-tail(requests[[human_id]]$request$messages,1)[[1]]$content
 if(!identical(sub('^[^\n]+\n','',a),sub('^[^\n]+\n','',b)))stop('Source-attribution content mismatch')
 paired<-paired+1L
}
check('AI_Human_actual_donor_body_identical',TRUE)
unresolved<-setdiff(tm_fields(attempts,'id'),tm_fields(http,'id'))
unresolved_cost<-sum(vapply(Filter(function(x)x$id%in%unresolved,attempts),function(x)x$reservation_cny,0))
out<-list(audited_at=tm_now(),status='passed',checks=checks,completed=length(records),skipped=length(skips),
 http_attempts=length(attempts),http_returns=length(http),unresolved_http=unresolved,
 source_label_pairs_checked=paired,planned=nrow(tasks),remaining=nrow(tasks)-length(records)-length(skips),
 guard_cny=sum(vapply(http,function(x)x$guard_cny,0))+unresolved_cost,cap_cny=140,
 note='An unresolved request during active collection is in flight, not necessarily failed. No retries are performed by this audit.')
tm_write(out,file.path(root,'reports/acquisition_audit.json'))
cat('Acquisition audit passed:',length(records),'records;',paired,'source-label pairs.\n')
