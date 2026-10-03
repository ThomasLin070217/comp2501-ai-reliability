# Offline results from frozen new-run inputs. Run from repository root.
source('Followup_Validation/R/common.R')
library(ggplot2)
out<-file.path(VROOT,'reports');dir.create(out,recursive=TRUE,showWarnings=FALSE)
freeze<-read_json(file.path(VROOT,'protocol/freeze.json'))
stopifnot(all(vapply(names(freeze$files_sha256),function(p)file_sha(p)==freeze$files_sha256[[p]],TRUE)))
qs<-indexed(read_jsonl(file.path(VROOT,'protocol/questions.jsonl')),'question_id')
wm<-read_json(file.path(VROOT,'protocol/wrong_materials.json'))
orders<-jsonlite::fromJSON(file.path(VROOT,'protocol/orders.json'))
planned<-do.call(rbind,orders)
rr<-unlist(lapply(MODELS,function(p)read_jsonl(file.path(VROOT,'runs',p,'responses.jsonl'))),recursive=FALSE)
raw<-rr[!duplicated(field(rr,'task_id'),fromLast=TRUE)];ri<-indexed(raw,'task_id')
grades<-do.call(rbind,lapply(seq_len(nrow(planned)),function(i){
 z<-planned[i,];id<-vtask(z$question_id,z$provider,z$repeat_id,z$condition);r<-ri[[id]];q<-qs[[z$question_id]]
 text<-if(is.null(r))''else r$text%||%'';status<-if(is.null(r))'not_requested'else r$status
 a<-vparse(text)
 cbind(z,task_id=id,cell_id=paste(z$question_id,z$provider,z$repeat_id,sep=':'),grade=if(status=='ok')vscore(text,q)else'unscorable',response_status=status,response_text=text,answer=if(vvalid(a))a$answer else'',reason=if(is.list(a))a$reason%||%''else'',stringsAsFactors=FALSE)
}))
write.csv(grades,file.path(out,'graded_responses.csv'),row.names=FALSE)
# Reconstruct every request, including Anthropic's separate system field.
for(r in raw){
 q<-qs[[r$question_id]];b<-ri[[r$baseline_task%||%'']];d<-ri[[r$donor_task%||%'']];w<-wm[[r$wrong_material_key%||%'']]
 expected<-vmessages(q,r$condition,if(is.null(b))NULL else b$text,if(is.null(d))NULL else d$text,w)
 actual<-r$request$messages;if(!is.null(r$request$system))actual<-c(list(list(role='system',content=r$request$system)),actual)
 stopifnot(identical(actual,expected));if(!is.null(d))stopifnot(d$provider!=r$provider,d$condition=='N0')
}
cells<-do.call(rbind,lapply(split(grades,grades$cell_id),function(z){r<-z[1,c('cell_id','question_id','domain','family','provider','donor','repeat_id','wrong_ablation')];for(k in VCOND)r[[k]]<-if(k%in%z$condition)z$grade[match(k,z$condition)]else'not_planned';r}))
write.csv(cells,file.path(out,'cells.csv'),row.names=FALSE)
valid<-c('correct','incorrect','abstain')
tables<-do.call(rbind,lapply(split(grades,interaction(grades$domain,grades$condition,drop=TRUE)),function(z){v<-z$grade[z$grade%in%valid];data.frame(domain=z$domain[1],condition=z$condition[1],planned=nrow(z),n=length(v),correct=sum(v=='correct'),wrong=sum(v=='incorrect'),abstain=sum(v=='abstain'),unscorable=sum(!z$grade%in%valid),error_pct=100*mean(v=='incorrect'))}))
write.csv(tables,file.path(out,'available_tables.csv'),row.names=FALSE)
effects<-list();trans<-list();bounds<-list();pairs<-list()
contrasts<-list(c('N2','N1'),c('N2','N0'),c('N3','N2'),c('W1','W0'),c('W2','W1'),c('W2','W0'))
for(domain in c('facts','mathematics'))for(provider in c('pooled',MODELS))for(cc in contrasts){
 if(domain=='mathematics'&&startsWith(cc[1],'W'))next
 a<-cc[1];b<-cc[2]
 allz<-cells[cells$domain==domain&(provider=='pooled'|cells$provider==provider),]
 if(startsWith(a,'W'))allz<-allz[allz$wrong_ablation,]
 z<-allz[allz[[a]]%in%valid & allz[[b]]%in%valid,];n<-nrow(z)
 if(!n)next
 pairs[[length(pairs)+1]]<-cbind(z[,1:8],comparison=paste(a,b,sep='-'),left=z[[b]],right=z[[a]])
 for(metric in c('error','correct','abstain')){
  target<-switch(metric,error='incorrect',correct='correct',abstain='abstain')
  delta<-as.numeric(z[[a]]==target)-as.numeric(z[[b]]==target)
  ids<-unique(z$question_id);sums<-vapply(ids,function(id)sum(delta[z$question_id==id]),0);sizes<-vapply(ids,function(id)sum(z$question_id==id),0)
  set.seed(25011006);boot<-replicate(5000,{ix<-sample(seq_along(ids),length(ids),replace=TRUE);100*sum(sums[ix])/sum(sizes[ix])})
  ci<-quantile(boot,c(.025,.975,.0125,.9875),names=FALSE)
  effects[[length(effects)+1]]<-data.frame(domain=domain,provider=provider,comparison=paste(a,b,sep='-'),metric=metric,n=n,questions=length(ids),before_n=sum(z[[b]]==target),after_n=sum(z[[a]]==target),before_pct=100*mean(z[[b]]==target),after_pct=100*mean(z[[a]]==target),difference_pp=100*mean(delta),ci_low=ci[1],ci_high=ci[2],familywise_low=ci[3],familywise_high=ci[4])
 }
 for(from in valid)for(to in valid)trans[[length(trans)+1]]<-data.frame(domain=domain,provider=provider,comparison=paste(a,b,sep='-'),from=from,to=to,n=sum(z[[b]]==from&z[[a]]==to),denominator=n)
 av<-ifelse(allz[[a]]%in%valid,as.numeric(allz[[a]]=='incorrect'),NA_real_);bv<-ifelse(allz[[b]]%in%valid,as.numeric(allz[[b]]=='incorrect'),NA_real_)
 bounds[[length(bounds)+1]]<-data.frame(domain=domain,provider=provider,comparison=paste(a,b,sep='-'),planned=nrow(allz),paired=n,low=100*mean(ifelse(is.na(av),0,av)-ifelse(is.na(bv),1,bv)),high=100*mean(ifelse(is.na(av),1,av)-ifelse(is.na(bv),0,bv)))
}
e<-do.call(rbind,effects);tr<-do.call(rbind,trans);pp<-do.call(rbind,pairs)
write.csv(e,file.path(out,'effects.csv'),row.names=FALSE);write.csv(tr,file.path(out,'transitions.csv'),row.names=FALSE);write.csv(do.call(rbind,bounds),file.path(out,'missing_bounds.csv'),row.names=FALSE)
write.csv(pp[!duplicated(paste(pp$cell_id,pp$comparison)),],file.path(out,'paired_outcomes.csv'),row.names=FALSE)
# Topic clustering is deliberately a sensitivity (only five mathematical topics).
topic<-list()
for(cc in contrasts[1:3]){
 z<-cells[cells$domain=='mathematics'&cells[[cc[1]]]%in%valid&cells[[cc[2]]]%in%valid,];delta<-as.numeric(z[[cc[1]]]=='incorrect')-as.numeric(z[[cc[2]]]=='incorrect');ids<-unique(z$family)
 sums<-vapply(ids,function(id)sum(delta[z$family==id]),0);sizes<-vapply(ids,function(id)sum(z$family==id),0)
 set.seed(25011006);boot<-replicate(5000,{ix<-sample(seq_along(ids),length(ids),replace=TRUE);100*sum(sums[ix])/sum(sizes[ix])});ci<-quantile(boot,c(.025,.975),names=FALSE)
 topic[[length(topic)+1]]<-data.frame(comparison=paste(cc,collapse='-'),topics=length(ids),n=nrow(z),difference_pp=100*mean(delta),ci_low=ci[1],ci_high=ci[2],note='Only five topics; unstable sensitivity, not population evidence')
}
write.csv(do.call(rbind,topic),file.path(out,'math_topic_sensitivity.csv'),row.names=FALSE)
usage<-do.call(rbind,lapply(MODELS,function(p){r<-Filter(function(x)x$provider==p,rr);data.frame(provider=p,attempts=length(r),input_tokens=sum(vapply(r,function(x)x$input_tokens%||%0,0)),output_tokens=sum(vapply(r,function(x)x$output_tokens%||%0,0)),guard_cny=sum(vapply(r,function(x)x$cost_guard_cny%||%0,0)))}))
write.csv(usage,file.path(out,'usage.csv'),row.names=FALSE)
primary<-subset(e,provider=='pooled'&comparison=='N2-N1'&metric=='error')
bars<-rbind(data.frame(domain=primary$domain,condition='Self-check',n=primary$n,wrong=primary$before_n,error_pct=primary$before_pct),data.frame(domain=primary$domain,condition='Cross-model check',n=primary$n,wrong=primary$after_n,error_pct=primary$after_pct))
bars$condition<-factor(bars$condition,levels=c('Self-check','Cross-model check'))
write.csv(bars,file.path(out,'primary_chart_data.csv'),row.names=FALSE)
p<-ggplot(bars,aes(condition,error_pct,fill=condition))+geom_col(width=.6)+geom_text(aes(label=sprintf('%.2f%%\n%d/%d',error_pct,wrong,n)),vjust=-.3,size=4)+facet_wrap(~domain,nrow=1)+scale_y_continuous(limits=c(0,100),breaks=seq(0,100,25))+scale_fill_manual(values=c('#657586','#147E77'),guide='none')+labs(x=NULL,y='Wrong answers (%)',title='Follow-up: cross-model checking versus self-checking',caption='Matched pairs within each domain. Explicit abstention is not an error; invalid outputs are separate.')+theme_minimal(base_size=12)
ggsave(file.path(out,'primary_error_rates.png'),p,width=10,height=5,dpi=160,bg='white')
# All failed outputs and mathematical baseline errors: review rather than silently rescore.
review<-grades[!grades$grade%in%valid|(grades$domain=='mathematics'&grades$condition=='N0'&grades$grade!='correct'),]
write.csv(review,file.path(out,'format_and_baseline_review.csv'),row.names=FALSE)
summary<-list(planned=nrow(grades),http_attempts=length(rr),returned_tasks=length(raw),grades=as.list(table(grades$grade)),returned_status=as.list(table(field(raw,'status'))),planned_units=nrow(cells),questions=length(qs),paid_guard_cny=sum(usage$guard_cny[usage$provider!='minimax']),prior_guard_cny=18.7603,review_guard_cap_cny=8,no_new_calls_in_analysis=TRUE,request_linkage_audit='all reconstructed requests match',input_hashes=setNames(lapply(file.path(VROOT,'runs',MODELS,'responses.jsonl'),file_sha),MODELS))
write_json(summary,file.path(out,'summary.json'))
stopifnot(all(tables$n==tables$correct+tables$wrong+tables$abstain),all(abs(e$difference_pp-(e$after_pct-e$before_pct))<1e-9))
print(subset(e,provider=='pooled'&metric=='error'));print(usage)
