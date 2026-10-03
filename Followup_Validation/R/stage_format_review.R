# Inspect completed provider logs without changing live requests or scoring rules.
source('Followup_Validation/R/common.R');args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)==1,args[1]%in%MODELS);provider<-args[1]
stopifnot(file.exists(file.path(VROOT,'runs',provider,'branches.done.json')))
qs<-indexed(read_jsonl(file.path(VROOT,'protocol/questions.jsonl')),'question_id');rr<-read_jsonl(file.path(VROOT,'runs',provider,'responses.jsonl'));rr<-rr[!duplicated(field(rr,'task_id'),fromLast=TRUE)]
rr<-Filter(function(r)r$status=='ok'&&vscore(r$text,qs[[r$question_id]])=='unscorable',rr)
p<-file.path(VROOT,'review','staged_format');dir.create(p,recursive=TRUE,showWarnings=FALSE)
z<-do.call(rbind,lapply(rr,function(r)data.frame(task_id=r$task_id,question_id=r$question_id,domain=r$domain,condition=r$condition,text=r$text)))
if(!length(rr))z<-data.frame(task_id=character(),question_id=character(),domain=character(),condition=character(),text=character())
write.csv(z,file.path(p,paste0(provider,'_responses.csv')),row.names=FALSE)
ix<-split(seq_len(nrow(z)),ceiling(seq_len(nrow(z))/10))
for(i in seq_along(ix)){a<-z[ix[[i]],];writeLines(unlist(lapply(seq_len(nrow(a)),function(k)c(paste0('## ',a$task_id[k]),qs[[a$question_id[k]]]$question,paste('Gold:',qs[[a$question_id[k]]]$gold),a$text[k],''))),file.path(p,sprintf('%s_packet_%02d.md',provider,i)))}
cat(provider,':',nrow(z),'complete unscorable outputs\n')
