# Offline selection of checks on the saved masked review and format failures.
source('Followup_Validation/R/common.R')
p<-file.path(VROOT,'reports');d<-file.path(VROOT,'review');g<-read.csv(file.path(p,'graded_responses.csv'));a<-read.csv(file.path(d,'annotations.csv'))
qs<-indexed(read_jsonl(file.path(VROOT,'protocol/questions.jsonl')),'question_id')
# A fixed-seed sample of reviewer-valid cases, independent of provider or effect direction.
set.seed(25011008);controls<-a[a$reasoning%in%'valid',];controls<-controls[sample(seq_len(nrow(controls)),min(24,nrow(controls))),]
write.csv(controls,file.path(d,'valid_control_selection.csv'),row.names=FALSE)
pack<-function(ids,prefix,folder){
 z<-g[match(ids,g$task_id),];stopifnot(!anyNA(z$task_id));chunks<-split(seq_len(nrow(z)),ceiling(seq_len(nrow(z))/12))
 for(i in seq_along(chunks)){b<-z[chunks[[i]],];writeLines(unlist(lapply(seq_len(nrow(b)),function(k)c(paste0('## ',b$task_id[k]),qs[[b$question_id[k]]]$question,paste('Gold:',qs[[b$question_id[k]]]$gold),b$response_text[k],''))),file.path(folder,sprintf('%s_%02d.md',prefix,i)))}
}
pack(controls$task_id,'valid_control_packet',d)
z<-g[g$response_status=='ok'&g$grade=='unscorable',]
pack(z$task_id,'completed_format_packet',d)
write.csv(z[,c('task_id','domain','condition','question_id','provider')],file.path(d,'completed_format_selection.csv'),row.names=FALSE)
write_json(list(time=now(),controls=nrow(controls),completed_format_cases=nrow(z),control_seed=25011008,selection='All completed unscorable outputs; seeded 24 reviewer-valid mathematical N1/N2 outputs. Existing flagged review packets are read separately.'),file.path(d,'codex_check_selection.json'))
cat('Prepared',nrow(controls),'valid controls and',nrow(z),'completed format failures.\n')
