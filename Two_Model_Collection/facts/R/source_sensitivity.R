# Post-hoc conservative exclusion: any question with an observed benchmark-risk
# source is excluded entirely, including downstream branches and both models.
source('Two_Model_Collection/facts/protocol/scoring.R')
root<-'Two_Model_Collection/facts';out<-file.path(root,'reports')
d<-read.csv(file.path(out,'graded_responses.csv'),stringsAsFactors=FALSE)
flags<-read.csv(file.path(out,'benchmark_source_flags.csv'),stringsAsFactors=FALSE)
tasks<-read.csv(file.path(root,'protocol/tasks.csv'),stringsAsFactors=FALSE)
f<-merge(flags,tasks[c('id','question_id','provider','condition')],by.x='task_id',by.y='id')
excluded<-sort(unique(f$question_id))
write.csv(data.frame(question_id=excluded),file.path(out,'source_risk_excluded_questions.csv'),row.names=FALSE)
variants<-list(strict=d)
sp<-file.path(out,'semantic_sensitivity_records.csv')
if(file.exists(sp)){z<-read.csv(sp,stringsAsFactors=FALSE);z$error<-z$semantic_error;variants$semantic<-z}
results<-list();models<-c('minimax','deepseek')
for(name in names(variants)){
 z<-variants[[name]];z<-z[!z$question_id%in%excluded&!is.na(z$error),]
 pair<-merge(z[z$condition=='self_check',],z[z$condition=='A0_AI',],
  by=c('question_id','provider','repeat_id'),suffixes=c('_self','_cross'))
 if(!nrow(pair))next
 v<-aggregate(cbind(error_self,error_cross)~question_id+provider,pair,mean)
 bm<-aggregate(cbind(error_self,error_cross)~provider,v,mean)
 if(!setequal(bm$provider,models))next
 ids<-unique(v$question_id);ma<-mb<-matrix(NA_real_,length(ids),2,dimnames=list(ids,models))
 for(i in seq_len(nrow(v))){ma[v$question_id[i],v$provider[i]]<-v$error_self[i];mb[v$question_id[i],v$provider[i]]<-v$error_cross[i]}
 effect<-function(ix){aa<-colMeans(ma[ix,,drop=FALSE],na.rm=TRUE);bb<-colMeans(mb[ix,,drop=FALSE],na.rm=TRUE);if(any(!is.finite(c(aa,bb))))NA_real_ else mean(bb-aa)}
 set.seed(25011008);boot<-replicate(5000,effect(sample(seq_along(ids),length(ids),replace=TRUE)))
 ci<-quantile(boot,c(.0125,.9875),na.rm=TRUE,names=FALSE)
 results[[name]]<-data.frame(label_variant=name,excluded_questions=length(excluded),paired_questions=length(ids),pairs=nrow(pair),
  self_error=mean(bm$error_self),cross_error=mean(bm$error_cross),difference=effect(seq_along(ids)),lower=ci[1],upper=ci[2],confidence=.975)
}
if(length(results))write.csv(do.call(rbind,results),file.path(out,'source_exclusion_sensitivity.csv'),row.names=FALSE)
cat('Conservative source sensitivity excludes',length(excluded),'entire questions. This is post hoc, not contamination-free certification.\n')
