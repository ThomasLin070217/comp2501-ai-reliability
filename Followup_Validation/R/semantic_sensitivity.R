# Post-hoc sensitivity for completed, unscorable outputs with explicit Codex annotations.
# Never replaces frozen primary grades; never imputes uncollected or incomplete branches.
source('Followup_Validation/R/common.R')
p<-file.path(VROOT,'reports');d<-file.path(VROOT,'review');g<-read.csv(file.path(p,'graded_responses.csv'));c<-read.csv(file.path(p,'cells.csv'));a<-read.csv(file.path(d,'codex_format_annotations.csv'))
stopifnot(!anyDuplicated(a$task_id),all(a$semantic_grade%in%c('correct','incorrect','abstain','uncertain')),all(nzchar(a$evidence)))
ix<-match(a$task_id,g$task_id);stopifnot(!anyNA(ix),all(g$grade[ix]=='unscorable'),all(g$response_status[ix]=='ok'))
stopifnot(setequal(a$task_id,g$task_id[g$grade=='unscorable'&g$response_status=='ok']))
g$semantic_grade<-g$grade;use<-a$semantic_grade!='uncertain';g$semantic_grade[ix[use]]<-a$semantic_grade[use]
for(i in seq_len(nrow(g)))c[match(g$cell_id[i],c$cell_id),g$condition[i]]<-g$semantic_grade[i]
write.csv(g[,c('task_id','domain','provider','condition','grade','semantic_grade')],file.path(p,'format_sensitivity_grades.csv'),row.names=FALSE)
valid<-c('correct','incorrect','abstain');effects<-list()
for(domain in c('facts','mathematics'))for(cc in list(c('N2','N1'),c('N2','N0'),c('N3','N2'),c('W1','W0'),c('W2','W1'),c('W2','W0'))){
 if(domain=='mathematics'&&startsWith(cc[1],'W'))next
 z<-c[c$domain==domain&c[[cc[1]]]%in%valid&c[[cc[2]]]%in%valid,];if(!nrow(z))next
 for(target in valid){
  delta<-as.numeric(z[[cc[1]]]==target)-as.numeric(z[[cc[2]]]==target);ids<-unique(z$question_id)
  sums<-vapply(ids,function(id)sum(delta[z$question_id==id]),0);sizes<-vapply(ids,function(id)sum(z$question_id==id),0)
  set.seed(25011006);boot<-replicate(5000,{i<-sample(seq_along(ids),length(ids),replace=TRUE);100*sum(sums[i])/sum(sizes[i])});ci<-quantile(boot,c(.025,.975,.0125,.9875),names=FALSE)
  effects[[length(effects)+1]]<-data.frame(domain=domain,comparison=paste(cc,collapse='-'),outcome=target,n=nrow(z),before=sum(z[[cc[2]]]==target),after=sum(z[[cc[1]]]==target),difference_pp=100*mean(delta),ci_low=ci[1],ci_high=ci[2],ci975_low=ci[3],ci975_high=ci[4])
 }
}
e<-do.call(rbind,effects);write.csv(e,file.path(p,'format_sensitivity_effects.csv'),row.names=FALSE)
write_json(list(time=now(),reviewed=nrow(a),recovered=sum(use),unresolved=sum(!use),original_grades_modified=FALSE,unknown_branches_imputed=FALSE,note='Post-hoc final-answer meaning assessment, not validation of all reasoning. Confidence intervals remain exploratory in this sensitivity.'),file.path(p,'format_sensitivity_validation.json'))
print(e[e$outcome=='incorrect',])
