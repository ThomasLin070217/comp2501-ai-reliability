# Review already-finished N0 mathematical responses while fixed branch jobs run.
# This inspection never changes the frozen selection or subsequent requests.
source('Followup_Validation/R/common.R')
stopifnot(all(file.exists(file.path(VROOT,'runs',MODELS,'baseline.done.json'))))
qs<-indexed(read_jsonl(file.path(VROOT,'protocol/questions.jsonl')),'question_id')
rr<-unlist(lapply(MODELS,function(p)read_jsonl(file.path(VROOT,'runs',p,'responses.jsonl'))),recursive=FALSE)
rr<-Filter(function(r)r$condition=='N0'&&r$domain=='mathematics',rr)
rr<-rr[!duplicated(field(rr,'task_id'),fromLast=TRUE)]
dir<-file.path(VROOT,'baseline_review');dir.create(dir,showWarnings=FALSE)
g<-do.call(rbind,lapply(rr,function(r)data.frame(task_id=r$task_id,question_id=r$question_id,provider=r$provider,status=r$status,grade=if(r$status=='ok')vscore(r$text,qs[[r$question_id]])else'unscorable',text=r$text%||%'')))
write.csv(g,file.path(dir,'responses.csv'),row.names=FALSE)
z<-g[g$grade=='incorrect',];ix<-split(seq_len(nrow(z)),ceiling(seq_len(nrow(z))/10))
for(i in seq_along(ix)){a<-z[ix[[i]],];writeLines(unlist(lapply(seq_len(nrow(a)),function(k)c(paste0('## ',a$task_id[k]),qs[[a$question_id[k]]]$question,paste('Gold:',qs[[a$question_id[k]]]$gold),a$text[k],''))),file.path(dir,sprintf('wrong_packet_%02d.md',i)))}
write_json(list(time=now(),scope='All returned mathematical N0 responses. Baseline outcomes inspected while fixed branch collection runs; no request or sample changes.',responses=nrow(g),counts=as.list(table(g$grade))),file.path(dir,'inspection.json'))
print(table(g$provider,g$grade))
