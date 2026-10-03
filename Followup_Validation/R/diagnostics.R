# Offline diagnostics added before reading aggregated follow-up outcomes.
# Frozen primary scores are read, not changed.
source('Followup_Validation/R/common.R')
p<-file.path(VROOT,'reports');g<-read.csv(file.path(p,'graded_responses.csv'));cells<-read.csv(file.path(p,'cells.csv'))
valid<-c('correct','incorrect','abstain');checks<-list()
check<-function(k,v){stopifnot(isTRUE(v));checks[[k]]<<-TRUE}
freeze<-read_json(file.path(VROOT,'protocol/freeze.json'))
check('original_frozen_files_unchanged',all(vapply(names(freeze$files_sha256),function(f)file_sha(f)==freeze$files_sha256[[f]],TRUE)))
rr<-list();availability<-list()
for(provider in MODELS){
 d<-file.path(VROOT,'runs',provider);r<-read_jsonl(file.path(d,'responses.jsonl'));at<-read_jsonl(file.path(d,'attempts.jsonl'))
 sk<-if(file.exists(file.path(d,'skipped.jsonl')))read_jsonl(file.path(d,'skipped.jsonl'))else list()
 check(paste0(provider,'_all_attempts_have_receipts'),setequal(field(r,'attempt_id'),field(at,'attempt_id'))&&!anyDuplicated(field(r,'attempt_id')))
 retry<-Filter(function(x)x$retry==1,r)
 for(x in retry){old<-Filter(function(y)y$task_id==x$task_id&&y$retry==0,r);stopifnot(length(old)==1,old[[1]]$status=='transport_error',identical(old[[1]]$request,x$request))}
 check(paste0(provider,'_retries_exact_transport_only'),length(retry)<=12)
 check(paste0(provider,'_cost_and_attempt_guards'),sum(vapply(r,function(x)x$cost_guard_cny,0))<=35&&length(r)<=1360)
 check(paste0(provider,'_no_gold_in_payload'),all(vapply(r,function(x)!any(c('gold','gold_numeric','reference_solution')%in%names(x$request)),TRUE)))
 z<-g[g$provider==provider,];sid<-field(sk,'task_id')
 availability[[provider]]<-data.frame(provider=provider,planned=nrow(z),attempts=length(r),retries=length(retry),distinct_attempted=length(unique(field(r,'task_id'))),skipped_input=length(sid),other_not_requested=sum(z$response_status=='not_requested'&!z$task_id%in%sid),incomplete=sum(z$response_status=='incomplete'),transport_failed=sum(z$response_status=='transport_error'),status_ok_unscorable=sum(z$response_status=='ok'&z$grade=='unscorable'))
 rr<-c(rr,r)
}
write.csv(do.call(rbind,availability),file.path(p,'availability_diagnostics.csv'),row.names=FALSE)
common<-cells[apply(cells[,c('N0','N1','N2','N3')],1,function(v)all(v%in%valid)),]
ct<-list()
for(domain in unique(common$domain))for(provider in c('pooled',MODELS))for(cond in c('N0','N1','N2','N3')){
 z<-common[common$domain==domain&(provider=='pooled'|common$provider==provider),];if(!nrow(z))next
 ct[[length(ct)+1]]<-data.frame(domain=domain,provider=provider,condition=cond,n=nrow(z),correct=sum(z[[cond]]=='correct'),wrong=sum(z[[cond]]=='incorrect'),abstain=sum(z[[cond]]=='abstain'),error_pct=100*mean(z[[cond]]=='incorrect'))
}
write.csv(do.call(rbind,ct),file.path(p,'common_four_conditions.csv'),row.names=FALSE)
paired<-cells[cells$N1%in%valid&cells$N2%in%valid,]
ds<-do.call(rbind,lapply(split(paired,interaction(paired$domain,paired$provider,paired$donor,drop=TRUE)),function(z)data.frame(domain=z$domain[1],receiver=z$provider[1],donor=z$donor[1],n=nrow(z),self_wrong=sum(z$N1=='incorrect'),cross_wrong=sum(z$N2=='incorrect'),difference_pp=100*mean((z$N2=='incorrect')-(z$N1=='incorrect')))))
write.csv(ds,file.path(p,'donor_receiver_descriptive.csv'),row.names=FALSE)
# Keep answer-format failures visible without treating them as mathematical mistakes.
z<-g[g$domain=='mathematics'&g$response_status=='ok',]
z$reason_position<-regexpr('"reason"[[:space:]]*:',z$response_text)
z$answer_position<-regexpr('"answer"[[:space:]]*:',z$response_text)
fmt<-do.call(rbind,lapply(split(z,interaction(z$provider,z$condition,drop=TRUE)),function(x)data.frame(provider=x$provider[1],condition=x$condition[1],status_ok=nrow(x),reason_before_answer=sum(x$reason_position>0&x$answer_position>x$reason_position),unscorable=sum(x$grade=='unscorable'))))
write.csv(fmt,file.path(p,'math_field_order.csv'),row.names=FALSE)
qs<-indexed(read_jsonl(file.path(VROOT,'protocol/questions.jsonl')),'question_id')
packets<-list(baseline_math=g[g$domain=='mathematics'&g$condition=='N0'&g$grade=='incorrect',],format=g[g$response_status=='ok'&g$grade=='unscorable',])
for(kind in names(packets)){
 z<-packets[[kind]];ix<-split(seq_len(nrow(z)),ceiling(seq_len(nrow(z))/12))
 for(i in seq_along(ix)){a<-z[ix[[i]],];writeLines(unlist(lapply(seq_len(nrow(a)),function(k)c(paste0('## ',a$task_id[k]),qs[[a$question_id[k]]]$question,paste('Gold:',qs[[a$question_id[k]]]$gold),a$response_text[k],''))),file.path(p,sprintf('review_%s_%02d.md',kind,i)))}
}
write_json(list(time=now(),checks=checks,checks_passed=length(checks),model_calls=0,field_grades_changed=FALSE),file.path(p,'diagnostic_validation.json'))
cat('Diagnostic checks passed:',length(checks),'\n')
