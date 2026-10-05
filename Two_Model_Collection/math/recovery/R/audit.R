source('Two_Model_Collection/math/recovery/R/common.R')
freeze<-fromJSON(file.path(REC,'protocol/freeze.json'),simplifyVector=FALSE)
checks<-list();check<-function(n,v){checks[[n]]<<-isTRUE(v);if(!isTRUE(v))stop(n)}
check('frozen_sources_and_original_logs_unchanged',all(vapply(names(freeze$files_sha256),function(p)digest(file=p,algo='sha256')==freeze$files_sha256[[p]],TRUE)))
plan<-read.csv(file.path(REC,'protocol/plan.csv'),stringsAsFactors=FALSE,na.strings=NULL)
http<-tm_read(file.path(REC,'runs/http_responses.jsonl'));attempts<-tm_read(file.path(REC,'runs/attempts.jsonl'));records<-tm_read(file.path(REC,'runs/completed.jsonl'));blocked<-tm_read(file.path(REC,'runs/blocked.jsonl'))
main<-tm_read(file.path(MAIN,'runs/completed.jsonl'));done<-setNames(main,tm_fields(main,'id'));for(r in records)done[[r$id]]<-r
orig<-tm_read(file.path(MAIN,'runs/http_responses.jsonl'));orig<-setNames(orig,tm_fields(orig,'task_id'))
prompts<-fromJSON(file.path(MAIN,'protocol/prompts.json'),simplifyVector=FALSE)$questions;prompts<-setNames(prompts,tm_fields(prompts,'question_id'));cfg<-fromJSON('Two_Model_Collection/protocol/models.json',simplifyVector=FALSE)
parent_ids<-sub(':recovery[12]$','',tm_fields(http,'task_id'))
check('no_task_more_than_two_recovery_attempts',all(table(parent_ids)<=2L))
check('unique_http_ids',!anyDuplicated(tm_fields(http,'id')))
check('all_targets_frozen',all(parent_ids%in%plan$id))
check('no_unresolved_request',!length(setdiff(tm_fields(attempts,'id'),tm_fields(http,'id'))))
seen<-list()
for(r in http){
 id<-sub(':recovery[12]$','',r$task_id);prior<-seen[[id]]%or%list();task<-as.list(plan[match(id,plan$id),]);previous<-if(length(prior))tail(prior,1)[[1]]else orig[[id]]
 if(!is.null(previous))check(paste0('eligible_',r$task_id),recovery_eligible(previous))
 expected<-recovery_payload(task,orig,prior,done,prompts,cfg)$payload
 if(!identical(tm_json(expected),tm_json(r$request)))stop('Recovery payload mismatch: ',r$id)
 if(!identical(r$request_sha256,digest(tm_json(expected),'sha256',serialize=FALSE)))stop('Recovery request hash mismatch: ',r$id)
 seen[[id]]<-c(prior,list(r))
}
check('all_recovery_payloads_reconstructed',TRUE)
selected<-done;requests<-orig
for(r in http)requests[[sub(':recovery[12]$','',r$task_id)]]<-r
pairs<-0L
for(r in selected){
 if(!r$condition%in%c('A0_AI','A1_AI'))next
 human<-selected[[sub('_AI$','_Human',r$id)]];if(is.null(human))next
 a<-requests[[r$id]]$request;b<-requests[[human$id]]$request
 if(is.null(a)||is.null(b))next
 aa<-tail(a$messages,1)[[1]]$content;bb<-tail(b$messages,1)[[1]]$content
 if(!identical(sub('^[^\n]+\n','',aa),sub('^[^\n]+\n','',bb)))stop('Selected AI/Human donor mismatch')
 pairs<-pairs+1L
}
status<-fromJSON(file.path(REC,'runs/status.json'),simplifyVector=FALSE)
check('all_fixed_recovery_targets_terminal_or_blocked',status$remaining==0L&&identical(status$status,'finished'))
dir.create(file.path(REC,'reports'),showWarnings=FALSE)
tm_write(list(audited_at=tm_now(),status='passed',planned=nrow(plan),http_attempts=length(http),
 distinct_attempted_targets=length(unique(parent_ids)),blocked=length(blocked),
 repeated_targets=sum(table(parent_ids)==2L),selected_source_pairs_checked=pairs,
 attempt_status_counts=as.list(table(tm_fields(http,'status'))),guard_cny=sum(vapply(http,function(r)r$guard_cny,0)),checks=checks),file.path(REC,'reports/acquisition_audit.json'))
cat('Recovery audit passed; original logs unchanged and all selected source bodies match.\n')
