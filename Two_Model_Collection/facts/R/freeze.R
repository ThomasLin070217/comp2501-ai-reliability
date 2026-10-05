source('Two_Model_Collection/facts/protocol/scoring.R')
root<-'Two_Model_Collection/facts'
out<-file.path(root,'protocol/freeze.json')
stopifnot(!file.exists(out),read_json(file.path(root,'reports/preflight_checks.json'))$status=='passed')
files<-c(list.files(file.path(root,'protocol'),full.names=TRUE),list.files(file.path(root,'R'),full.names=TRUE),
 'Fact_Prompt_Design/R/prompts.R','Followup_Validation/R/common.R','Natural_Crosscheck/R/common.R',
 'Math_Supplement/R/common.R','Peer_Misleading_Study/R/core.R')
write_json(list(frozen_at=now(),domain='facts',target_responses=1600,cap_cny=280,
 no_new_model_outputs_inspected=TRUE,files_sha256=setNames(lapply(files,file_sha),files)),out)
cat('Facts protocol frozen. No paid calls.\n')
