#!/usr/bin/env Rscript
# Run from repository root. All data processing in R; no network/model calls.
source('Peer_Misleading_Study/R/core.R')
args <- commandArgs(trailingOnly=TRUE)
out <- if(length(args)) args[1] else 'Peer_Misleading_Study/reports/interaction_posthoc'
dir.create(out,recursive=TRUE,showWarnings=FALSE)
root <- 'Peer_Misleading_Study'
frozen <- read_json(file.path(root,'protocol/formal-receiver-freeze.json'))$hashes
for(p in names(frozen)) assert(identical(file_sha(file.path(root,p)),frozen[[p]]),paste('Frozen input changed',p))
qs <- read_jsonl(file.path(root,'data/main_questions.jsonl')); qi <- indexed(qs,'question_id')
records <- assemble(root)$records; ri <- indexed(records,'task_id')
decisions<-read_json(file.path(root,'data/main_adjudications.json'))
raw_g<-score_records(qs,records,decisions)
g <- quality_filter(raw_g)$grades
arch <- read.csv(file.path(root,'reports/main_r/graded_responses.csv'),stringsAsFactors=FALSE)
ix <- match(g$task_id,arch$task_id)
assert(nrow(g)==5033 && !anyNA(ix) && identical(g$grade,arch$grade[ix]),'Original grade mismatch')
assert(identical(g$target_adopted,arch$target_adopted[ix]),'Original target score mismatch')
c <- make_cells(g); assert(nrow(c)==719,'Wrong complete-unit count')
for(k in CONDITIONS) {
 z <- g[g$condition==k,]; ix<-match(c$cell_id,z$cell_id)
 assert(!anyNA(ix) && all(z$grade[is.na(z$target_adopted)]=='abstain'),'Missing target score for asserted answer')
 # Four adjudicated abstentions have NA target flags: no committed final answer.
 c[[paste0(k,'_target')]] <- z$target_adopted[ix] %in% TRUE
}
specs <- list(C0_vs_baseline=c('baseline','C0'),C1_vs_C0=c('C0','C1'),
 C2_vs_C0=c('C0','C2'),C3_vs_C2=c('C2','C3'),C5_vs_C4=c('C4','C5'))
states<-c('correct','incorrect','abstain')
trans<-list();pairs<-list()
for(nm in names(specs)) {
 a<-specs[[nm]][1];b<-specs[[nm]][2]
 z<-c[,c('question_id','provider','repeat_id','cell_id','baseline')]
 z$comparison<-nm;z$left_condition<-a;z$right_condition<-b
 z$left_grade<-c[[a]];z$right_grade<-c[[b]]
 z$left_target<-c[[paste0(a,'_target')]];z$right_target<-c[[paste0(b,'_target')]]
 z$new_target<-!z$left_target & z$right_target;z$lost_target<-z$left_target & !z$right_target
 pairs[[nm]]<-z
 for(model in c('pooled',MODELS)) for(stratum in c('all',states)) {
  zz<-z[(model=='pooled'|z$provider==model)&(stratum=='all'|z$baseline==stratum),]
  for(x in states) for(y in states) trans[[length(trans)+1L]]<-data.frame(
   comparison=nm,provider=model,baseline_stratum=stratum,from=x,to=y,n=sum(zz$left_grade==x&zz$right_grade==y),
   denominator=nrow(zz),from_denominator=sum(zz$left_grade==x))
 }
}
pairs<-do.call(rbind,pairs);rownames(pairs)<-NULL
write.csv(pairs,file.path(out,'paired_outcomes.csv'),row.names=FALSE)
write.csv(do.call(rbind,trans),file.path(out,'transitions.csv'),row.names=FALSE)

# Ratio-of-sums question-cluster bootstrap, including conditional error rate.
estimate<-function(z,a,b,metric,B=5000L) {
 vals<-function(k) {
  v<-z[[k]]
  num<-switch(metric,error=v=='incorrect',correct=v=='correct',abstain=v=='abstain',
    target=z[[paste0(k,'_target')]],coverage=v!='abstain',error_among_answered=v=='incorrect')
  den<-if(metric=='error_among_answered')as.integer(v!='abstain') else rep(1L,nrow(z))
  cbind(as.integer(num),den)
 }
 l<-vals(a);r<-vals(b);q<-sort(unique(z$question_id))
 mat<-t(vapply(q,function(id)colSums(cbind(l,r)[z$question_id==id,,drop=FALSE]),numeric(4)))
 totals<-colSums(mat);left<-pct(totals[1],totals[2]);right<-pct(totals[3],totals[4])
 RNGkind('Mersenne-Twister','Inversion','Rejection');set.seed(25011003)
 draws<-matrix(sample.int(length(q),length(q)*B,replace=TRUE),nrow=length(q))
 sums<-sapply(1:4,function(j)colSums(matrix(mat[draws,j],nrow=length(q))))
 keep<-sums[,2]>0&sums[,4]>0;boot<-100*(sums[keep,3]/sums[keep,4]-sums[keep,1]/sums[keep,2])
 ci<-if(length(boot))as.numeric(quantile(boot,c(.025,.975),names=FALSE)) else c(NA,NA)
 data.frame(metric=metric,left_n=totals[1],left_den=totals[2],right_n=totals[3],right_den=totals[4],
  left_pct=left,right_pct=right,difference_pp=right-left,ci_low_pp=ci[1],ci_high_pp=ci[2],
  question_clusters=length(q),bootstrap_iterations=sum(keep),
  interval_note=if(length(unique(boot))<=1)'degenerate; not evidence of equivalence' else 'pointwise exploratory percentile interval')
}
caveats<-read_json(file.path(root,'data/main_preanalysis_caveats.json'))
# Match the established exclusion set rather than invent new exclusions.
disputed_keys<-names(Filter(function(x)isTRUE(x$disputed),decisions))
source_exclude<-unique(c(field(caveats$question_caveats,'question_id'),
 g$question_id[g$review_id%in%disputed_keys],raw_g$question_id[raw_g$unscorable]))
source_exclude<-intersect(source_exclude,c$question_id)
effects<-list()
exclusions<-list(primary=character(),exclude_source_caveats=source_exclude,
 exclude_all_known_reference_concerns=union(source_exclude,c('SV3691','SV3593')))
for(variant in names(exclusions)) {
 zz<-c[!c$question_id%in%exclusions[[variant]],]
 for(model in c('pooled',MODELS)) {
  z<-zz[model=='pooled'|zz$provider==model,]
  for(nm in names(specs)) for(metric in c('error','correct','abstain','target','coverage','error_among_answered'))
   effects[[length(effects)+1L]]<-cbind(variant=variant,provider=model,comparison=nm,
    estimate(z,specs[[nm]][1],specs[[nm]][2],metric))
 }
}
effects<-do.call(rbind,effects)
write.csv(effects,file.path(out,'effects.csv'),row.names=FALSE,na='')

# Full withdrawal set, plus systematic key cases for all contrast directions.
sel<-list();add<-function(z,reason) {if(nrow(z)){z$selection_reason<-reason;sel[[length(sel)+1L]]<<-z}}
add(subset(pairs,comparison=='C3_vs_C2' & left_grade=='incorrect' & right_grade=='abstain'),'all_C2_wrong_C3_abstain')
for(nm in names(specs)) for(model in MODELS) {
 z<-pairs[pairs$comparison==nm & pairs$provider==model,];z<-z[order(z$cell_id),]
 for(x in states) for(y in states) if(x!=y) add(head(z[z$left_grade==x&z$right_grade==y,],1),paste('first_per_model_transition',x,y))
 for(flag in c('new_target','lost_target'))add(head(z[z[[flag]],],1),paste('first_per_model',flag))
}
add(subset(pairs,baseline=='correct' & right_condition%in%c('C1','C2') & right_grade=='incorrect'),'all_baseline_correct_harm_C1_C2')
queue<-do.call(rbind,sel);queue$pair_id<-paste(queue$comparison,queue$cell_id,sep='|')
reasons<-tapply(queue$selection_reason,queue$pair_id,function(x)paste(sort(unique(x)),collapse='; '))
queue<-queue[!duplicated(queue$pair_id),];queue$selection_reason<-unname(reasons[queue$pair_id]);queue<-queue[order(queue$pair_id),]
queue$question<-vapply(queue$question_id,function(id)qi[[id]]$question,'')
queue$gold<-vapply(queue$question_id,function(id)qi[[id]]$gold,'')
queue$false_target<-vapply(queue$question_id,function(id)qi[[id]]$false_target,'')
for(side in c('left','right')) {
 ids<-paste0(queue$cell_id,':',queue[[paste0(side,'_condition')]])
 queue[[paste0(side,'_task_id')]]<-ids
 queue[[paste0(side,'_text')]]<-vapply(ids,function(id)ri[[id]]$text,'')
 queue[[paste0(side,'_request_sha256')]]<-vapply(ids,function(id)ri[[id]]$request_sha256,'')
}
queue$review_number<-seq_len(nrow(queue))
write.csv(queue,file.path(out,'ai_review_queue.csv'),row.names=FALSE,na='')
# Compact but verbatim review packets; both endpoints remain in CSV.
for(batch in split(seq_len(nrow(queue)),ceiling(seq_len(nrow(queue))/20))) {
 lines<-unlist(lapply(batch,function(i){z<-queue[i,];c(paste0('## ',z$review_number,' ',z$pair_id),
  paste('Q:',z$question),paste('Reference:',z$gold,'| Assigned wrong:',z$false_target),
  paste('Grades:',z$left_grade,'->',z$right_grade,'| Target:',z$left_target,'->',z$right_target),
  'LEFT:',z$left_text,'RIGHT:',z$right_text,'')}))
 writeLines(head(lines,-1),file.path(out,sprintf('review_packet_%02d.md',ceiling(batch[1]/20))))
}
write.csv(condition_tables(c,g),file.path(out,'condition_tables.csv'),row.names=FALSE,na='')
protected<-c(file.path(root,'reports/main_r/graded_responses.csv'),file.path(root,'reports/main_r/analysis_data.csv'),
 'outputs/01a0e6a9-review/COMP2501_人工复核.xlsx')
write_json(list(language='R',model_calls=0,post_hoc=TRUE,seed=25011003,iterations=5000,
 raw_response_count=length(records),main_response_count=nrow(g),cells=nrow(c),question_count=length(unique(c$question_id)),
 grade_agreement=TRUE,target_agreement=TRUE,frozen_hashes_verified=length(frozen),
 excluded_source_questions=source_exclude,exclusions=exclusions,source_caveat_structure=names(caveats),
 review_pairs=nrow(queue),full_withdrawal_pairs=sum(queue$comparison=='C3_vs_C2'&queue$left_grade=='incorrect'&queue$right_grade=='abstain'),
 protected_sha256=setNames(lapply(protected,file_sha),protected),script_sha256=file_sha('Peer_Misleading_Study/R/interaction_posthoc.R')),
 file.path(out,'audit.json'))
writeLines(sub('[[:space:]]+$','',capture.output(sessionInfo())),file.path(out,'sessionInfo.txt'))
print(effects[effects$variant=='primary'&effects$provider=='pooled'&effects$metric%in%c('error','target'),],row.names=FALSE)
cat('AI review pairs:',nrow(queue),'\nSource exclusions:',paste(source_exclude,collapse=', '),'\n')
