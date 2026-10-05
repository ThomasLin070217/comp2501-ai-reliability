library(jsonlite);library(digest)
root<-'Two_Model_Collection/math'
files<-c(file.path(root,'R',c('prepare.R','scoring.R','check.R')),file.path(root,'protocol',c('questions.json','prompts.json','researcher_reference.json','stimulus_review.json','mechanism_subset.csv','tasks.csv','SCORING.md','checks.json','preparation.json')))
stopifnot(all(file.exists(files)),!file.exists(file.path(root,'protocol/freeze.json')))
hashes<-setNames(lapply(files,function(p)digest(file=p,algo='sha256')),files)
write_json(list(frozen_at=format(Sys.time(),tz='UTC',usetz=TRUE),domain='math',sample_seed=25011005,task_order_seed=25011006,
 question_count=41L,mechanism_question_count=15L,target_responses=732L,cap_cny=140,
 status='protocol_frozen_before_paid_calls_runtime_pending',files_sha256=hashes),file.path(root,'protocol/freeze.json'),pretty=TRUE,auto_unbox=TRUE)
cat('Mathematics protocol frozen. Shared runtime is separately frozen by coordinator.\n')
