# Post-hoc semantic review and source-risk sensitivities; no model calls.
source('Two_Model_Collection/facts/protocol/scoring.R')
recroot<-'Two_Model_Collection/facts/recovery';derived<-file.path(recroot,'derived');out<-file.path(derived,'reports')
d<-read.csv(file.path(out,'graded_responses.csv'),stringsAsFactors=FALSE)
old<-read.csv('Two_Model_Collection/facts/reports/semantic_review_all_exceptions.csv',stringsAsFactors=FALSE)
review<-old[c('id','semantic_grade','explanation')]
review<-rbind(review,data.frame(id='two:SV4261:minimax:2:self_check',semantic_grade='abstain',
 explanation='The nonempty answer is itself an explicit statement of inability to verify; abstain=true and reason also express uncertainty. Schema invalidity is preserved in the strict endpoint.'))
stopifnot(setequal(review$id,d$id[d$grade=='unscorable'&d$status=='ok']))
q<-indexed(read_jsonl('Two_Model_Collection/facts/protocol/questions.jsonl'),'question_id')
review<-merge(review,d[c('id','question_id','provider','repeat_id','condition','grade','text')],by='id')
review$reference<-vapply(review$question_id,function(id)q[[id]]$gold,'');review$reviewer<-'Codex'
write.csv(review,file.path(out,'semantic_review_all_exceptions.csv'),row.names=FALSE)
d$semantic_grade<-d$grade;ii<-match(review$id,d$id);d$semantic_grade[ii]<-review$semantic_grade
d$semantic_error<-ifelse(d$semantic_grade=='unscorable',NA_real_,as.numeric(d$semantic_grade=='incorrect'))
write.csv(d,file.path(out,'semantic_sensitivity_records.csv'),row.names=FALSE)
valid<-d[!is.na(d$semantic_error),]
pair<-merge(valid[valid$condition=='self_check',],valid[valid$condition=='A0_AI',],
 by=c('question_id','provider','repeat_id'),suffixes=c('_self','_cross'))
v<-aggregate(cbind(semantic_error_self,semantic_error_cross)~question_id+provider,pair,mean)
bm<-aggregate(cbind(semantic_error_self,semantic_error_cross)~provider,v,mean)
ids<-unique(v$question_id);models<-c('minimax','deepseek');ma<-mb<-matrix(NA_real_,length(ids),2,dimnames=list(ids,models))
for(i in seq_len(nrow(v))){ma[v$question_id[i],v$provider[i]]<-v$semantic_error_self[i];mb[v$question_id[i],v$provider[i]]<-v$semantic_error_cross[i]}
ef<-function(ix){aa<-colMeans(ma[ix,,drop=FALSE],na.rm=TRUE);bb<-colMeans(mb[ix,,drop=FALSE],na.rm=TRUE);if(any(!is.finite(c(aa,bb))))NA_real_ else mean(bb-aa)}
set.seed(25011008);boot<-replicate(5000,ef(sample(seq_along(ids),length(ids),replace=TRUE)))
ci<-quantile(boot,c(.0125,.9875),na.rm=TRUE,names=FALSE)
write.csv(bm,file.path(out,'semantic_sensitivity_model_means.csv'),row.names=FALSE)
write.csv(data.frame(comparison='natural_crosscheck',condition_a='self_check',condition_b='A0_AI',
 error_a=mean(bm$semantic_error_self),error_b=mean(bm$semantic_error_cross),difference=ef(seq_along(ids)),
 lower=ci[1],upper=ci[2],confidence=.975,questions=length(ids),pairs=nrow(pair),post_hoc=TRUE),
 file.path(out,'semantic_sensitivity_effects.csv'),row.names=FALSE)
write_json(list(post_hoc=TRUE,reviewer='Codex',independent_human_review=FALSE,
 reviewed_exceptions=nrow(review),new_exception_count=1,new_recovery_outputs_read=29,
 counts=as.list(table(d$semantic_grade)),strict_labels_changed=FALSE,
 natural_comparison=list(questions=length(ids),pairs=nrow(pair),error_self=mean(bm$semantic_error_self),
 error_cross=mean(bm$semantic_error_cross),difference=ef(seq_along(ids)),lower=ci[1],upper=ci[2],confidence=.975)),
 file.path(out,'semantic_sensitivity_summary.json'))
new<-read_jsonl(file.path(recroot,'runs/completed.jsonl'));nr<-d[match(field(new,'id'),d$id),]
notes<-data.frame(id=nr$id,question_id=nr$question_id,strict_grade=nr$grade,
 review_note=ifelse(nr$id=='two:SV4261:minimax:2:self_check','Explicit semantic abstention in nonempty answer field; sensitivity only.',
 ifelse(nr$question_id=='SV0097'&nr$grade=='incorrect','The response gives a build/file date or December release claim instead of the inherited release date. Official project changelog independently supports 2020-06-28.',
 'Read final answer and brief justification against inherited reference; no further answer/reason conflict identified. This is not a new web check of every factual explanation.')),
 reviewer='Codex',stringsAsFactors=FALSE)
write.csv(notes,file.path(recroot,'reports/reviewed_recovery_outputs.csv'),row.names=FALSE)
write_json(list(question_id='SV0097',reference='June 28, 2020',review_date='2026-10-05',
 result='The project GitHub changelog lists 7.8.8 with 2020-06-28, supporting the inherited reference over the build-date confusion.',
 source='https://github.com/notepad-plus-plus/notepad-plus-plus/wiki/Changes-v7#788',
 direct_download_and_news_pages='Attempted but returned HTTP 403; not claimed as directly inspected.',
 scope='Only this disputed recovered item received a fresh primary-source check; no frozen scoring/reference changed.'),
 file.path(recroot,'reports/SV0097_reference_check.json'))
# Reuse the exact original source-risk code, overriding only its output/input root
# in an isolated R evaluation environment. Frozen files are not edited.
with_root<-function(script,newroot){
 exprs<-parse(file=script);replaced<-0L;e<-new.env(parent=globalenv())
 for(expr in exprs){
  if(is.call(expr)&&identical(expr[[1]],as.name('<-'))&&identical(expr[[2]],as.name('root'))){
   expr[[3]]<-newroot;replaced<-replaced+1L
  }
  eval(expr,envir=e)
 }
 stopifnot(replaced==1L)
}
with_root('Two_Model_Collection/facts/R/audit_sources.R',derived)
with_root('Two_Model_Collection/facts/R/source_sensitivity.R',derived)
cat('Reviewed all 29 selected recovery outputs and all 19 complete strict-score exceptions; source sensitivities regenerated.\n')
