source('Two_Model_Collection/R/runtime.R')
root<-'Two_Model_Collection/math/recovery/derived';out<-file.path(root,'reports')
d<-read.csv(file.path(out,'json_recovery_sensitivity.csv'),stringsAsFactors=FALSE)
p<-read.csv(file.path(root,'provenance.csv'),stringsAsFactors=FALSE)
d<-merge(d,p[,c('id','source','selected_recovery_attempt','http_id','recovery_mode')],by='id',sort=FALSE)
new<-d[d$source=='technical_recovery_appendix',]
exceptions<-new[new$status=='ok' & new$semantic_grade!='correct',]
set.seed(25011005);good<-new[new$status=='ok' & new$semantic_grade=='correct',];good<-good[order(good$id),];sample<-good[sample(seq_len(nrow(good)),min(40L,nrow(good))),]
review<-rbind(exceptions,sample);review$review_selection<-c(rep('all_new_complete_noncorrect_or_unresolved',nrow(exceptions)),rep('fixed_seed_new_correct_sample',nrow(sample)))
write.csv(review,file.path(out,'recovery_review_queue.csv'),row.names=FALSE)
writeLines(vapply(seq_len(nrow(review)),function(i){r<-review[i,];paste0('\nID ',r$id,' attempt ',r$selected_recovery_attempt,' ',r$review_selection,'\nAnswer: ',r$recovered_answer,'\nReason: ',if(nzchar(r$recovered_reason))r$recovered_reason else r$text)},''),file.path(out,'recovery_review_readable.txt'))
cat('Recovery review queue:',nrow(exceptions),'exceptions and',nrow(sample),'fixed-seed correct sample.\n')
