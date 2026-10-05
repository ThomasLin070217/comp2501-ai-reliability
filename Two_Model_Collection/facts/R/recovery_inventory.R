# Inventory only. No recovery calls and no mutation of original responses.
source('Two_Model_Collection/R/runtime.R')
root<-'Two_Model_Collection/facts';out<-file.path(root,'reports')
records<-tm_read(file.path(root,'runs/completed.jsonl'));done<-setNames(records,tm_fields(records,'id'))
h<-tm_read(file.path(root,'runs/http_responses.jsonl'));a<-tm_read(file.path(root,'runs/attempts.jsonl'))
skips<-tm_read(file.path(root,'runs/skipped.jsonl'))
tasks<-read.csv(file.path(root,'protocol/tasks.csv'),stringsAsFactors=FALSE)
failed<-Filter(function(r)identical(r$status,'transport_error'),records)
fr<-do.call(rbind,lapply(failed,function(r)data.frame(id=r$id,question_id=r$question_id,provider=r$provider,
 repeat_id=r$repeat_id,condition=r$condition,status=r$status,http_id=r$http_id,request_sha256=r$request_sha256,
 original_guard_cny=r$guard_cny,recovery_calls_made=0L)))
write.csv(fr,file.path(out,'transport_recovery_candidates.csv'),row.names=FALSE)
technical<-Filter(function(r)!identical(r$status,'ok'),records)
tr<-do.call(rbind,lapply(technical,function(r)data.frame(id=r$id,question_id=r$question_id,
 provider=r$provider,repeat_id=r$repeat_id,condition=r$condition,status=r$status,
 finish_reason=r$finish_reason%or%'',request_sha256=r$request_sha256)))
write.csv(tr,file.path(out,'all_technical_failures.csv'),row.names=FALSE)
dep_rows<-list()
for(s in skips){
 t<-as.list(tasks[match(s$id,tasks$id),]);deps<-c(t$baseline_id,t$donor_id);deps<-deps[nzchar(deps)]
 bad<-deps[!vapply(deps,function(id)tm_usable(done[[id]]),TRUE)]
 statuses<-vapply(bad,function(id)done[[id]]$status%or%'missing','')
 onlytransport<-length(bad)>0&&all(statuses=='transport_error')
 dep_rows[[length(dep_rows)+1L]]<-data.frame(id=t$id,question_id=t$question_id,provider=t$provider,
  repeat_id=t$repeat_id,condition=t$condition,unusable_dependency_ids=paste(bad,collapse=' | '),
  dependency_statuses=paste(statuses,collapse=' | '),all_blockers_transport_only=onlytransport,
  note=if(onlytransport)'Eligible to reconsider only after separate transport recovery yields usable output.'else'Includes incomplete or schema-invalid input; outside a transport-only recovery appendix.')
}
deps<-do.call(rbind,dep_rows);write.csv(deps,file.path(out,'dependency_recovery_inventory.csv'),row.names=FALSE)
write.csv(deps[deps$all_blockers_transport_only,],file.path(out,'transport_only_dependency_candidates.csv'),row.names=FALSE)
unresolved<-setdiff(tm_fields(a,'id'),tm_fields(h,'id'))
stopifnot(length(unresolved)==0L,length(a)==length(h),!anyDuplicated(tm_fields(h,'id')))
summary<-list(status='inventory_only_no_recovery_calls',original_planned=nrow(tasks),
 http_attempts=length(h),transport_failures=nrow(fr),other_incomplete=sum(tr$status=='incomplete'),
 all_dependency_skips=nrow(deps),transport_only_dependency_skips=sum(deps$all_blockers_transport_only),
 unresolved_http_attempts=length(unresolved),guard_cny=sum(vapply(h,function(r)r$guard_cny,0)),
 transport_uncertainty_reserve_cny=sum(fr$original_guard_cny),
 rules='Original records stay immutable. Candidate list does not authorize calls; parent must freeze a separately labelled transport-only recovery appendix. Never retry based on correctness.')
tm_write(summary,file.path(out,'technical_recovery_summary.json'));print(summary)
