# Transparent source-risk screen. A URL match flags risk, not confirmed leakage.
source('Two_Model_Collection/facts/protocol/scoring.R')
root<-'Two_Model_Collection/facts';out<-file.path(root,'reports')
h<-read_jsonl(file.path(root,'runs/http_responses.jsonl'));rows<-list()
for(r in h){
 blocks<-Filter(function(b)identical(b$type,'web_search_tool_result'),r$raw_response$content%||%list())
 for(b in blocks)for(s in b$content%||%list())if(is.list(s)&&is.character(s$url)&&length(s$url)==1){
  text<-paste(s$url,s$title%||%'')
  risk<-grepl('simpleqa|huggingface.co/datasets|github.com/.{0,120}(benchmark|eval|qa.dataset)|benchmark.*dataset',text,ignore.case=TRUE,perl=TRUE)
  rows[[length(rows)+1L]]<-data.frame(task_id=r$task_id,url=s$url,title=s$title%||%'',benchmark_risk=risk)
 }
}
z<-if(length(rows))unique(do.call(rbind,rows))else data.frame()
write.csv(z,file.path(out,'search_sources.csv'),row.names=FALSE)
if(nrow(z))write.csv(z[z$benchmark_risk,],file.path(out,'benchmark_source_flags.csv'),row.names=FALSE)
write_json(list(status='screened_not_adjudicated',unique_task_url_title_rows=nrow(z),
 risky_source_rows=if(nrow(z))sum(z$benchmark_risk)else 0,
 exposed_http_tasks=if(nrow(z))length(unique(z$task_id[z$benchmark_risk]))else 0,
 definition='URL/title mentions SimpleQA, HuggingFace datasets, or benchmark/evaluation repositories. Flags do not prove benchmark copying. Unflagged results do not prove absence.',
 inherited_history='Only newly returned search blocks are screened here. Receiver baseline history and donor text may carry upstream exposure, so direct exposed task counts understate possible downstream exposure.',
 no_web_refetch=TRUE),file.path(out,'source_screen.json'))
cat('Source screen:',nrow(z),'task/source rows;',if(nrow(z))sum(z$benchmark_risk)else 0,'risk flags.\n')
