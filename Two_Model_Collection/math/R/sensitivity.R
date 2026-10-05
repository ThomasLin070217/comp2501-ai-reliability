# Post-collection sensitivity only. Frozen strict scoring remains unchanged.
source('Two_Model_Collection/R/runtime.R')
source('Two_Model_Collection/math/R/scoring.R')
root<-Sys.getenv('MATH_STUDY_ROOT','Two_Model_Collection/math');out<-file.path(root,'reports')
d<-read.csv(file.path(out,'graded_responses.csv'),stringsAsFactors=FALSE)
rows<-lapply(seq_len(nrow(d)),function(i){
 z<-d[i,];x<-tm_parse(z$text);g<-NULL
 if(z$status=='ok'&&!is.null(x))g<-math_score(as.character(toJSON(x,auto_unbox=TRUE)),z$question_id)
 if(is.null(g))g<-list(label='unscorable',scoring_reason='No complete unique JSON final answer in a complete response.',conflict=FALSE,needs_review=TRUE)
 data.frame(z,semantic_grade=if(g$label=='wrong')'incorrect'else g$label,semantic_conflict=g$conflict,
  semantic_scoring_reason=g$scoring_reason,recovered_answer=if(is.null(x$answer))''else as.character(x$answer),
  recovered_reason=if(is.null(x$reason))''else as.character(x$reason),posthoc_json_recovery=z$grade=='unscorable'&&g$label!='unscorable',stringsAsFactors=FALSE)
})
s<-do.call(rbind,rows)
write.csv(s,file.path(out,'json_recovery_sensitivity.csv'),row.names=FALSE)
counts<-as.data.frame(table(s$grade,s$semantic_grade));names(counts)<-c('strict_grade','semantic_grade','n')
write.csv(counts,file.path(out,'json_recovery_transitions.csv'),row.names=FALSE)
# Reuse the frozen analysis estimator on temporary normalized records only.
# Provenance is explicit; these are not additional observations or original responses.
tmp<-tempfile('math-json-sensitivity-');dir.create(file.path(tmp,'protocol'),recursive=TRUE);dir.create(file.path(tmp,'runs'))
file.copy(file.path(root,'protocol/tasks.csv'),file.path(tmp,'protocol/tasks.csv'))
if(file.exists(file.path(root,'runs/skipped.jsonl')))file.copy(file.path(root,'runs/skipped.jsonl'),file.path(tmp,'runs/skipped.jsonl'))
records<-tm_read(file.path(root,'runs/completed.jsonl'))
for(i in seq_along(records)){
 x<-tm_parse(records[[i]]$text)
 if(records[[i]]$status=='ok'&&!is.null(x))records[[i]]$text<-as.character(toJSON(x,auto_unbox=TRUE))
}
writeLines(vapply(records,tm_json,''),file.path(tmp,'runs/completed.jsonl'))
Sys.setenv(MATH_ANALYSIS_ROOT=tmp);source('Two_Model_Collection/math/R/analyse.R',local=new.env(parent=globalenv()));Sys.unsetenv('MATH_ANALYSIS_ROOT')
dest<-file.path(out,'json_recovery_sensitivity');dir.create(dest,showWarnings=FALSE)
file.copy(list.files(file.path(tmp,'reports'),full.names=TRUE),dest,overwrite=TRUE)
unlink(tmp,recursive=TRUE)
tm_write(list(status='posthoc_sensitivity_not_replacement',recovered=sum(s$posthoc_json_recovery),
 strict_counts=as.list(table(s$grade)),sensitivity_counts=as.list(table(s$semantic_grade)),
 method='Use the already frozen acquisition parser to recover a unique JSON object from surrounding prose; score its unchanged fields against the frozen reference. Incomplete/transport failures are never repaired into valid responses.',
 review='Automatic format-recovery sensitivity, with separate Codex review of wrong/unresolved final claims. It is not a claim that every reasoning paragraph has been independently verified.'),file.path(out,'json_recovery_summary.json'))
cat('Recovered',sum(s$posthoc_json_recovery),'complete JSON answers from surrounding prose.\n')
