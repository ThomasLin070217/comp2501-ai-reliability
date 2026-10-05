# Same conservative URL/title screen as facts, with CHAMP as the task identifier.
source('Two_Model_Collection/R/runtime.R')
root<-'Two_Model_Collection/math';out<-file.path(root,'reports')
pattern<-'champ|huggingface.co/datasets|github.com/.{0,120}(benchmark|eval|qa.dataset)|benchmark.*dataset'
tasks<-read.csv(file.path(root,'protocol/tasks.csv'),stringsAsFactors=FALSE)
records<-list(original=tm_read(file.path(root,'runs/http_responses.jsonl')),
 recovery=tm_read(file.path(root,'recovery/runs/http_responses.jsonl')))
rows<-list();claims<-list()
for(stage in names(records))for(r in records[[stage]]){
 id<-sub(':recovery[12]$','',r$task_id);qid<-tasks$question_id[match(id,tasks$id)]
 stopifnot(length(qid)==1L,!is.na(qid))
 scan<-function(blocks,scope){
  for(b in Filter(function(b)is.list(b)&&identical(b$type,'web_search_tool_result'),blocks))
   if(is.list(b$content))for(s in b$content)if(is.list(s)&&is.character(s$url)&&length(s$url)==1L){
    txt<-paste(s$url,s$title%or%'');risk<-grepl(pattern,txt,ignore.case=TRUE,perl=TRUE)
    rows[[length(rows)+1L]]<<-data.frame(stage=stage,task_id=id,http_id=r$id,question_id=qid,scope=scope,url=s$url,title=s$title%or%'',benchmark_risk=risk,stringsAsFactors=FALSE)
   }
 }
 scan(r$raw_response$content%or%list(),'returned_search_results')
 for(m in r$request$messages%or%list())if(is.list(m$content))scan(m$content,'inherited_baseline_search_history')
 # Donor narrative claims are preserved as separate evidence, not substituted
 # for the URL/title screen. Whole-question exclusion covers same-question donors.
 for(m in r$request$messages%or%list())if(is.character(m$content)&&grepl('ground truth|champ.dataset',m$content,ignore.case=TRUE,perl=TRUE))
  claims[[length(claims)+1L]]<-data.frame(stage=stage,task_id=id,http_id=r$id,question_id=qid,scope='request_text_claim',text=m$content,stringsAsFactors=FALSE)
 if(is.character(r$text)&&grepl('ground truth|champ.dataset',r$text,ignore.case=TRUE,perl=TRUE))
  claims[[length(claims)+1L]]<-data.frame(stage=stage,task_id=id,http_id=r$id,question_id=qid,scope='response_text_claim',text=r$text,stringsAsFactors=FALSE)
}
sources<-if(length(rows))unique(do.call(rbind,rows))else data.frame()
write.csv(sources,file.path(out,'search_sources_all_stages.csv'),row.names=FALSE)
if(length(claims))write.csv(do.call(rbind,claims),file.path(out,'benchmark_narrative_claims.csv'),row.names=FALSE)
for(stage in c('original','combined')){
 z<-if(stage=='original')sources[sources$stage=='original',]else sources
 flagged<-if(nrow(z))sort(unique(z$question_id[z$benchmark_risk]))else character()
 write.csv(data.frame(question_id=flagged),file.path(out,paste0('benchmark_risk_questions_',stage,'.csv')),row.names=FALSE)
 tm_write(list(scope=stage,pattern=pattern,flagged_questions=flagged,question_count=length(flagged),
 method='Same URL/title criterion as facts except CHAMP replaces SimpleQA. Scan all original/recovery attempts, including unselected or incomplete ones, plus inherited native baseline search blocks; exclude every task of any flagged question. Same-question donor exposure is therefore included.',
 limits='Risk screen, not confirmed copying. CHAMP may appear in unrelated titles, and unflagged pages may still contain answers. Model narrative claims are separately exported. No web refetch was performed.'),file.path(out,paste0('source_screen_',stage,'.json')))
}
cat('Source-risk screen completed; whole-question exclusion lists saved.\n')
