# Post-collection Codex review; does not replace frozen primary labels.
source('Two_Model_Collection/facts/protocol/scoring.R')
root<-'Two_Model_Collection/facts';out<-file.path(root,'reports')
d<-read.csv(file.path(out,'graded_responses.csv'),stringsAsFactors=FALSE)
q<-indexed(read_jsonl(file.path(root,'protocol/questions.jsonl')),'question_id')
review<-data.frame(
 id=c('two:SV1851:minimax:2:neutral_initial','two:SV1808:minimax:1:neutral_initial',
 'two:SV2035:minimax:2:neutral_initial','two:SV2209:minimax:1:neutral_initial',
 'two:SV2035:minimax:1:neutral_initial','two:SV1857:minimax:2:neutral_initial',
 'two:SV1228:minimax:2:neutral_initial','two:SV2831:minimax:1:A0_AI',
 'two:SV3267:minimax:2:self_check','two:SV2035:minimax:2:self_check',
 'two:SV3462:minimax:2:self_check','two:SV1391:minimax:2:self_check',
 'two:SV1199:minimax:2:self_check','two:SV3592:minimax:1:A0_AI','two:SV0200:minimax:2:A0_AI',
 'two:SV2796:minimax:2:A1_Human','two:SV3030:minimax:1:A1_Human','two:SV3265:minimax:1:A0_Human'),
 semantic_grade=c('incorrect','incorrect','incorrect','unscorable','abstain','abstain',
 'abstain','abstain','abstain','incorrect','incorrect','abstain','abstain','correct','incorrect','correct','correct','incorrect'),
 explanation=c(
 'Prose answer explicitly asserts 15 June 2021; inherited reference is 23 April 2021.',
 '1959 conflicts with January 2021 despite also lacking requested month.',
 '1974 conflicts with December 1972 despite also lacking requested month.',
 'October 2009 matches month/year but omits requested day; remains insufficient precision.',
 'Empty answer and explicit inability to determine; abstain is string true instead of boolean.',
 'Empty answer and explicit inability to determine; abstain=false conflicts with stated uncertainty.',
 'abstain=true and reason says no verified record; answer field is nonempty. Count semantic abstention only in sensitivity.',
 'abstain=true and explicit abstention in reason; nonempty answer field conflict retained.',
 'abstain=true and explicit inability to verify; nonempty answer field conflict retained.',
 '1974 conflicts with December 1972 despite also lacking requested month.',
 '1971 conflicts with 28 April 1969 despite also lacking requested month/day.',
 'abstain=true and explicit inability to verify; nonempty answer field conflict retained.',
 'abstain=true and explicit inability to verify; nonempty answer field conflict retained.',
 '18 February 1907 matches reference; Reason key is capitalised.',
 '1902 conflicts with inherited 1949 reference; abstain key misspelled abain.',
 '20 January 1978 matches inherited reference; Reason key is capitalised.',
 '26 December 1999 matches inherited reference; Reason key is capitalised.',
 'January 1994 conflicts with inherited 1 April 1994 reference despite also lacking requested day.'),stringsAsFactors=FALSE)
stopifnot(setequal(review$id,d$id[d$grade=='unscorable'&d$status=='ok']))
z<-merge(review,d[c('id','question_id','provider','repeat_id','condition','grade','text')],by='id')
z$reference<-vapply(z$question_id,function(id)q[[id]]$gold,'')
z$reviewer<-'Codex';z$review_scope<-'Output meaning against inherited reference; not new external reference adjudication'
write.csv(z,file.path(out,'semantic_review_all_exceptions.csv'),row.names=FALSE)
d$semantic_grade<-d$grade;ii<-match(review$id,d$id);d$semantic_grade[ii]<-review$semantic_grade
d$semantic_error<-ifelse(d$semantic_grade=='unscorable',NA_real_,as.numeric(d$semantic_grade=='incorrect'))
write.csv(d,file.path(out,'semantic_sensitivity_records.csv'),row.names=FALSE)
valid<-d[!is.na(d$semantic_error),]
a<-valid[valid$condition=='self_check',];b<-valid[valid$condition=='A0_AI',]
pair<-merge(a,b,by=c('question_id','provider','repeat_id'),suffixes=c('_self','_cross'))
v<-aggregate(cbind(semantic_error_self,semantic_error_cross)~question_id+provider,pair,mean)
bm<-aggregate(cbind(semantic_error_self,semantic_error_cross)~provider,v,mean)
ids<-unique(v$question_id);models<-c('minimax','deepseek');ma<-mb<-matrix(NA_real_,length(ids),2,dimnames=list(ids,models))
for(i in seq_len(nrow(v))){ma[v$question_id[i],v$provider[i]]<-v$semantic_error_self[i];mb[v$question_id[i],v$provider[i]]<-v$semantic_error_cross[i]}
effect<-function(ix){aa<-colMeans(ma[ix,,drop=FALSE],na.rm=TRUE);bb<-colMeans(mb[ix,,drop=FALSE],na.rm=TRUE);if(any(!is.finite(c(aa,bb))))NA_real_ else mean(bb-aa)}
set.seed(25011008);boot<-replicate(5000,effect(sample(seq_along(ids),length(ids),replace=TRUE)))
ci<-quantile(boot,c(.0125,.9875),na.rm=TRUE,names=FALSE)
write.csv(bm,file.path(out,'semantic_sensitivity_model_means.csv'),row.names=FALSE)
write_json(list(post_hoc=TRUE,reviewer='Codex',independent_human_review=FALSE,reviewed=nrow(review),
 semantic_counts=as.list(table(d$semantic_grade)),primary_labels_changed=FALSE,
 paired_comparison=list(questions=length(ids),pairs=nrow(pair),error_self=mean(bm$semantic_error_self),
 error_cross=mean(bm$semantic_error_cross),difference=effect(seq_along(ids)),lower=ci[1],upper=ci[2],confidence=.975)),
 file.path(out,'semantic_sensitivity_summary.json'))
cat(nrow(review),'completed schema/date exceptions reviewed; frozen primary labels unchanged.\n')
