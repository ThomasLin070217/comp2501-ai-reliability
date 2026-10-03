# Offline analysis; no API calls, no credential reading, no changes to frozen grades.
source('Natural_Crosscheck/R/common.R')
library(ggplot2)
qs<-indexed(read_jsonl(file.path(NROOT,'protocol/questions.jsonl')),'question_id')
u<-read.csv(file.path(NROOT,'protocol/units.csv'))
freeze<-read_json(file.path(NROOT,'protocol/freeze.json'))
stopifnot(all(vapply(names(freeze$files_sha256),function(p)file_sha(p)==freeze$files_sha256[[p]],TRUE)))
rows<-unlist(lapply(MODELS,function(p){fp<-file.path(NROOT,'runs',p,'responses.jsonl');if(file.exists(fp))read_jsonl(fp)else list()}),recursive=FALSE)
stopifnot(length(rows)>0)
rr<-rows[!duplicated(field(rows,'task_id'),fromLast=TRUE)];idx<-indexed(rr,'task_id')
planned<-do.call(rbind,lapply(seq_len(nrow(u)),function(i)cbind(u[rep(i,4),],condition=NCOND)))
g<-do.call(rbind,lapply(seq_len(nrow(planned)),function(i){
 z<-planned[i,];task<-ntask(z$question_id,z$provider,z$condition);r<-idx[[task]];q<-qs[[z$question_id]]
 status<-if(is.null(r))'not_requested'else r$status
 text<-if(is.null(r))''else r$text%||%''
 score<-if(status=='ok')nscore(text,q)else'not_scorable'
 cbind(z,task_id=task,grade=score,response_status=status,response_text=text,question=q$question,gold=if(q$domain=='facts')q$gold else mjson(q$gold),cell_id=paste(z$question_id,z$provider,sep=':'),stringsAsFactors=FALSE)
}))
valid<-c('correct','incorrect','abstain')
out<-file.path(NROOT,'reports');dir.create(out,recursive=TRUE,showWarnings=FALSE)
write.csv(g,file.path(out,'graded_responses.csv'),row.names=FALSE)
# Each pairing carries exactly the original same-question independent N0 as peer input.
for(r in rr){
 if(r$condition%in%c('N2','N3')){
  d<-idx[[r$donor_task]];q<-qs[[r$question_id]]
  stopifnot(!is.null(d),d$provider!=r$provider,d$condition=='N0',d$question_id==r$question_id,
   r$donor_text_sha256==digest::digest(donor_text(d$text,q),algo='sha256',serialize=FALSE),
   grepl(donor_text(d$text,q),tail(r$request$messages,1)[[1]]$content,fixed=TRUE))
 }
}
cells<-do.call(rbind,lapply(split(g,g$cell_id),function(z){r<-z[1,c('cell_id','question_id','domain','family','provider','donor')];for(c in NCOND)r[[c]]<-z$grade[match(c,z$condition)];r}))
cells$complete<-apply(cells[NCOND],1,function(z)all(z%in%valid))
write.csv(cells,file.path(out,'cells.csv'),row.names=FALSE)
summary_table<-function(z,scope){
 do.call(rbind,lapply(c('facts','mathematics'),function(d)do.call(rbind,lapply(c('pooled',MODELS),function(p)do.call(rbind,lapply(NCOND,function(c){
  x<-subset(z,domain==d & (p=='pooled'|provider==p));v<-x[[c]];v<-v[v%in%valid];n<-length(v)
  data.frame(scope=scope,domain=d,provider=p,condition=c,n=n,correct=sum(v=='correct'),wrong=sum(v=='incorrect'),abstain=sum(v=='abstain'),error_pct=if(n)100*mean(v=='incorrect')else NA_real_,correct_pct=if(n)100*mean(v=='correct')else NA_real_,abstain_pct=if(n)100*mean(v=='abstain')else NA_real_)
 }))))))
}
tab<-rbind(summary_table(cells[cells$complete,],'common_four'),summary_table(cells,'available_condition'))
write.csv(tab,file.path(out,'tables.csv'),row.names=FALSE)
comparisons<-list(c('N2','N1'),c('N2','N0'),c('N3','N2'))
set.seed(freeze$bootstrap_seed)
compar<-list();trans<-list();missing<-list();j<-0L
for(d in c('facts','mathematics'))for(p in c('pooled',MODELS))for(cc in comparisons){
 a<-cc[1];b<-cc[2];allz<-subset(cells,domain==d & (p=='pooled'|provider==p));z<-allz[allz[[a]]%in%valid & allz[[b]]%in%valid,];n<-nrow(z)
 for(metric in c('error','correct','abstain')){
  target<-switch(metric,error='incorrect',correct='correct',abstain='abstain')
  delta<-as.numeric(z[[a]]==target)-as.numeric(z[[b]]==target)
  lo<-hi<-NA_real_
  if(d=='facts'&&n>0){
   ids<-unique(z$question_id);sums<-vapply(ids,function(id)sum(delta[z$question_id==id]),0);sizes<-vapply(ids,function(id)sum(z$question_id==id),0)
   draws<-replicate(freeze$bootstrap_iterations,{ix<-sample(seq_along(ids),length(ids),replace=TRUE);100*sum(sums[ix])/sum(sizes[ix])})
   ci<-quantile(draws,c(.025,.975),names=FALSE);lo<-ci[1];hi<-ci[2]
  }
  j<-j+1L;compar[[j]]<-data.frame(domain=d,provider=p,comparison=paste(a,b,sep='-'),metric=metric,n=n,question_clusters=length(unique(z$question_id)),a_pct=if(n)100*mean(z[[a]]==target)else NA_real_,b_pct=if(n)100*mean(z[[b]]==target)else NA_real_,difference_pp=if(n)100*mean(delta)else NA_real_,ci_low_pp=lo,ci_high_pp=hi)
 }
 for(from in valid)for(to in valid)trans[[length(trans)+1]]<-data.frame(domain=d,provider=p,comparison=paste(a,b,sep='-'),from=from,to=to,n=sum(z[[b]]==from & z[[a]]==to))
 # Bound all unscorable/missing outputs for the planned same-cell comparison.
 av<-ifelse(allz[[a]]%in%valid,as.numeric(allz[[a]]=='incorrect'),NA_real_);bv<-ifelse(allz[[b]]%in%valid,as.numeric(allz[[b]]=='incorrect'),NA_real_)
 missing[[length(missing)+1]]<-data.frame(domain=d,provider=p,comparison=paste(a,b,sep='-'),planned=nrow(allz),paired=n,missing_a=sum(is.na(av)),missing_b=sum(is.na(bv)),difference_lower_pp=100*mean(ifelse(is.na(av),0,av)-ifelse(is.na(bv),1,bv)),difference_upper_pp=100*mean(ifelse(is.na(av),1,av)-ifelse(is.na(bv),0,bv)))
}
e<-do.call(rbind,compar);t<-do.call(rbind,trans)
write.csv(e,file.path(out,'effects.csv'),row.names=FALSE);write.csv(t,file.path(out,'transitions.csv'),row.names=FALSE);write.csv(do.call(rbind,missing),file.path(out,'missing_bounds.csv'),row.names=FALSE)
# Donor correctness is observed rather than assigned; descriptive only, not causal strata.
donors<-do.call(rbind,lapply(seq_len(nrow(cells)),function(i){z<-cells[i,];d<-subset(cells,question_id==z$question_id & provider==z$donor);stopifnot(nrow(d)==1);data.frame(cell_id=z$cell_id,question_id=z$question_id,domain=z$domain,provider=z$provider,donor=z$donor,own_initial=z$N0,donor_initial=d$N0)}))
write.csv(donors,file.path(out,'donor_states.csv'),row.names=FALSE)
family<-do.call(rbind,lapply(unique(subset(cells,domain=='mathematics')$family),function(f){z<-subset(cells,domain=='mathematics'&family==f&complete);do.call(rbind,lapply(NCOND,function(c)data.frame(family=f,condition=c,n=nrow(z),wrong=sum(z[[c]]=='incorrect'),correct=sum(z[[c]]=='correct'),abstain=sum(z[[c]]=='abstain'))))}))
write.csv(family,file.path(out,'math_families.csv'),row.names=FALSE)
usage<-do.call(rbind,lapply(MODELS,function(p){x<-Filter(function(r)r$provider==p,rows);data.frame(provider=p,attempts=length(x),input_tokens=sum(vapply(x,function(r)r$input_tokens%||%0,0)),output_tokens=sum(vapply(x,function(r)r$output_tokens%||%0,0)),token_envelope_cny=sum(vapply(x,function(r)r$cost_guard_cny%||%0,0)),paid_provider=p!='minimax')}))
write.csv(usage,file.path(out,'usage.csv'),row.names=FALSE)
plotdata<-subset(tab,scope=='common_four'&provider=='pooled');plotdata$condition<-factor(plotdata$condition,levels=NCOND)
write.csv(plotdata,file.path(out,'plotted_error_rates.csv'),row.names=FALSE)
p<-ggplot(plotdata,aes(condition,error_pct,fill=condition))+geom_col(width=.65)+geom_text(aes(label=sprintf('%.2f%%',error_pct)),vjust=-.5,size=4.5,fontface='bold')+facet_wrap(~domain,nrow=1)+scale_fill_manual(values=c(N0='#8B9BAE',N1='#657586',N2='#C45F48',N3='#147E77'),guide='none')+scale_y_continuous(limits=c(0,100),breaks=seq(0,100,25),labels=function(x)paste0(x,'%'))+scale_x_discrete(labels=c(N0='Direct\nanswer',N1='Self\ncheck',N2='Peer\ncheck',N3='Structured\npeer check'))+labs(title='Natural cross-checking: observed error rates',subtitle=paste('Common four-output samples:',paste(paste(plotdata$domain[plotdata$condition=='N0'],plotdata$n[plotdata$condition=='N0'],sep=' n='),collapse='; ')),x=NULL,y='Error rate',caption='Correct answers and abstentions remain in the denominator; only wrong answers count as errors.\nPost-hoc follow-up on previously studied questions. Mathematical families are few; domains are not difficulty matched.')+theme_minimal(base_size=13)+theme(panel.grid.major.x=element_blank(),plot.caption=element_text(hjust=0))
ggsave(file.path(out,'error_rates.png'),p,width=11,height=5.4,dpi=160,bg='white')
# Review all mathematics outputs, all unscorable outputs and factual discordant primary pairs.
changed<-subset(cells,domain=='facts' & N1!=N2)$cell_id
review<-g[g$domain=='mathematics'|!g$grade%in%valid|g$cell_id%in%changed,]
write.csv(review,file.path(out,'ai_review_queue.csv'),row.names=FALSE)
packets<-split(seq_len(nrow(review)),ceiling(seq_len(nrow(review))/20))
for(k in seq_along(packets)){
 lines<-unlist(lapply(packets[[k]],function(i){z<-review[i,];c(paste0('## ',z$task_id),'',paste('Question:',z$question),paste('Reference:',z$gold),paste('Field grade:',z$grade),'',z$response_text,'')}))
 writeLines(lines,file.path(out,sprintf('review_packet_%02d.md',k)))
}
summary<-list(post_hoc=TRUE,questions=length(qs),planned_outputs=nrow(g),http_attempts=length(rows),returned_tasks=length(rr),status_counts=as.list(table(g$response_status)),grade_counts=as.list(table(g$grade)),common_cells_by_domain=as.list(table(cells$domain[cells$complete])),review_outputs=nrow(review),paid_guard_cny=sum(usage$token_envelope_cny[usage$paid_provider]),prior_new_paid_guard_cny=15.433696,cumulative_new_paid_guard_cny=15.433696+sum(usage$token_envelope_cny[usage$paid_provider]),hku_price_unknown=TRUE,input_hashes=setNames(lapply(file.path(NROOT,'runs',MODELS,'responses.jsonl'),file_sha),MODELS),frozen_hashes_verified=TRUE)
write_json(summary,file.path(out,'summary.json'))
write_json(list(rates=lapply(seq_len(nrow(plotdata)),function(i)as.list(plotdata[i,])),effects=lapply(seq_len(nrow(e)),function(i)as.list(e[i,])),summary=summary),file.path(out,'presentation_data.json'))
cat('Analysis complete.\n');print(subset(e,provider=='pooled'&metric=='error'));print(usage)
