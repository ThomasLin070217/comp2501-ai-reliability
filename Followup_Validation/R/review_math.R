# Secondary masked AI review. Requires KIMI_API_KEY only when run with 'collect'.
# Preparation/scoring use R; no original field grades are changed.
source('Followup_Validation/R/common.R')
library(curl)
args<-commandArgs(trailingOnly=TRUE);mode<-if(length(args))args[1]else'prepare'
dir<-file.path(VROOT,'review');dir.create(dir,recursive=TRUE,showWarnings=FALSE)
PROMPT<-paste('You are auditing the displayed mathematical reasoning of anonymized assistant responses.',
 'Use the supplied problem and reference, checking the reasoning yourself; the source reference may contain typographical mistakes noted in the vetted correction.',
 'Do not infer reasoning validity from a matching final answer. Do not infer provider or experimental condition.',
 'For each response return reasoning="valid" if the displayed solution has sound sufficient key steps,',
 '"incomplete" if no false step is identified but essential support is missing (including an unsupported answer or an abstention without a solution),',
 '"incorrect" if at least one explicit mathematical or logical claim is false, or "uncertain" if you cannot judge reliably.',
 'Routine omitted algebra is acceptable when the stated key argument is sufficient; do not require a long proof.',
 'Set answer_reason_consistent to true/false when determinable, otherwise null.',
 'Provide evidence of at most 35 words identifying a concrete step, missing justification, or contradiction.',
 'Set reference_problem=true only when a substantive unresolved reference issue prevents reliable assessment.',
 'Return only JSON {"judgments":[{"id":"...","reasoning":"...","answer_reason_consistent":true,"evidence":"...","reference_problem":false}, ...]}, once per supplied id. Do not rewrite answers.')
if(mode=='prepare'){
 qs<-indexed(read_jsonl(file.path(VROOT,'protocol/questions.jsonl')),'question_id')
 g<-read.csv(file.path(VROOT,'reports/graded_responses.csv'))
 g<-g[g$domain=='mathematics'&g$condition%in%c('N1','N2')&g$response_status=='ok',]
 g$blind_id<-vapply(seq_len(nrow(g)),function(i)substr(digest::digest(paste(g$task_id[i],g$response_text[i],sep='\n'),algo='sha256',serialize=FALSE),1,20),'')
 stopifnot(!anyDuplicated(g$blind_id))
 write.csv(g[,c('blind_id','task_id','cell_id','question_id','provider','condition','grade')],file.path(dir,'mask_map.csv'),row.names=FALSE)
 notes<-readLines(file.path(VROOT,'sources/reference_review.md'),warn=FALSE)
 jobs<-list();set.seed(25011007)
 for(id in sort(unique(g$question_id))){
  z<-g[g$question_id==id,];z<-z[sample(nrow(z)),];q<-qs[[id]]
  note<-grep(paste0('^- ',q$source_id,':'),notes,value=TRUE)
  body<-list(problem=q$question,reference_answer=q$gold,reference_solution=q$reference_solution,vetted_correction=paste(note,collapse='\n'),responses=lapply(seq_len(nrow(z)),function(i)list(id=z$blind_id[i],text=z$response_text[i])))
  jobs[[length(jobs)+1L]]<-list(question_id=id,ids=z$blind_id,request=list(model='kimi-k2.6',temperature=0,max_tokens=3000,thinking=list(type='disabled'),messages=list(list(role='system',content=PROMPT),list(role='user',content=vjson(body)))))
 }
 write_jsonl(jobs,file.path(dir,'requests.jsonl'))
 write_json(list(time=now(),system_prompt=PROMPT,reviewed_conditions=c('N1','N2'),masked_fields=c('model','provider','condition','automatic_grade'),reviewer_model='kimi-k2.6',cap_cny=8,scope='All available mathematical N1/N2 responses, not whole corpus; secondary AI assessment, not human proof validation.',jobs=length(jobs),outputs=nrow(g)),file.path(dir,'protocol.json'))
 cat('Prepared',length(jobs),'masked jobs,',nrow(g),'responses.\n')
}else if(mode=='collect'){
 stopifnot(nzchar(Sys.getenv('KIMI_API_KEY')))
 jobs<-read_jsonl(file.path(dir,'requests.jsonl'));rp<-file.path(dir,'responses.jsonl')
 old<-if(file.exists(rp))read_jsonl(rp)else list();done<-field(old,'question_id');used<-sum(vapply(old,function(r)r$cost_guard_cny,0))
 jobs<-Filter(function(j)!j$question_id%in%done,jobs)
 while(length(jobs)){
  batch<-head(jobs,3);jobs<-tail(jobs,-length(batch));reserves<-vapply(batch,function(j)(nchar(vjson(j$request),type='bytes')*20+3000*50)/1e6,0)
  if(used+sum(reserves)>8){if(length(batch)>1){jobs<-c(batch[-1],jobs);batch<-batch[1];reserves<-reserves[1]};if(used+sum(reserves)>8)stop('AI review budget guard reached')}
  pool<-new_pool(total_con=3,host_con=3);results<-vector('list',length(batch))
  for(k in seq_along(batch))local({
   kk<-k;j<-batch[[kk]];reserve<-reserves[kk];started<-Sys.time()
   finish<-function(res=NULL){
    r<-list(question_id=j$question_id,time=now(),request=j$request,status='transport_error',cost_guard_cny=reserve,latency_seconds=as.numeric(difftime(Sys.time(),started,units='secs')))
    if(!is.null(res)){r$http_status<-res$status_code;if(res$status_code==200){raw<-tryCatch(jsonlite::fromJSON(rawToChar(res$content),simplifyVector=FALSE),error=function(e)NULL);if(!is.null(raw)){r$raw_response<-raw;r$text<-raw$choices[[1]]$message$content;r$finish_reason<-raw$choices[[1]]$finish_reason;r$status<-if(r$finish_reason=='stop')'ok'else'incomplete';r$usage<-raw$usage;r$cost_guard_cny<-(raw$usage$prompt_tokens*20+raw$usage$completion_tokens*50)/1e6}}}
    mappend(r,rp);results[[kk]]<<-r
   }
   h<-new_handle();handle_setheaders(h,'Content-Type'='application/json',Authorization=paste('Bearer',Sys.getenv('KIMI_API_KEY')));handle_setopt(h,postfields=vjson(j$request),timeout=180,connecttimeout=20,followlocation=FALSE)
   curl_fetch_multi('https://api.moonshot.cn/v1/chat/completions',done=function(r)finish(r),fail=function(e)finish(),pool=pool,handle=h)
  })
  multi_run(pool=pool);used<-used+sum(vapply(results,function(r)r$cost_guard_cny,0));cat('Masked review remaining',length(jobs),'guard',round(used,4),'\n');flush.console()
  if(any(vapply(results,function(r)!identical(r$status,'ok'),TRUE)))stop('Review batch has an incomplete/error response; no automatic resampling')
 }
 write_json(list(time=now(),status='collection_complete',guard_cny=used),file.path(dir,'collection.done.json'))
}else if(mode=='analyse'){
 map<-read.csv(file.path(dir,'mask_map.csv'));requests<-indexed(read_jsonl(file.path(dir,'requests.jsonl')),'question_id');rs<-read_jsonl(file.path(dir,'responses.jsonl'))
 js<-list();invalid<-list()
 for(r in rs){
  a<-parse_json(r$text%||%'');expected<-unlist(requests[[r$question_id]]$ids)
  good<-r$status=='ok'&&is.list(a$judgments)&&length(a$judgments)==length(expected)
  if(good)good<-setequal(field(a$judgments,'id'),expected)&&!anyDuplicated(field(a$judgments,'id'))&&all(field(a$judgments,'reasoning')%in%c('valid','incomplete','incorrect','uncertain'))
  if(!good){invalid[[length(invalid)+1]]<-list(question_id=r$question_id,status='review_invalid');next}
  for(j in a$judgments)js[[length(js)+1]]<-data.frame(blind_id=j$id,reasoning=j$reasoning,answer_reason_consistent=j$answer_reason_consistent%||%NA,evidence=j$evidence%||%'',reference_problem=j$reference_problem%||%FALSE)
 }
 ann<-merge(map,do.call(rbind,js),by='blind_id',all.x=TRUE);write.csv(ann,file.path(dir,'annotations.csv'),row.names=FALSE)
 write_json(invalid,file.path(dir,'invalid_jobs.json'))
 counts<-as.data.frame(table(ann$condition,ann$reasoning,useNA='ifany'));names(counts)<-c('condition','reasoning','n');write.csv(counts,file.path(dir,'reasoning_counts.csv'),row.names=FALSE)
 cat('Reviewed',sum(!is.na(ann$reasoning)),'of',nrow(ann),'available mathematical responses.\n');print(counts)
 flagged<-ann[ann$reasoning%in%c('incorrect','uncertain')|ann$reference_problem%in%TRUE|ann$answer_reason_consistent%in%FALSE,]
 g<-read.csv(file.path(VROOT,'reports/graded_responses.csv'));flagged$response_text<-g$response_text[match(flagged$task_id,g$task_id)]
 qs<-indexed(read_jsonl(file.path(VROOT,'protocol/questions.jsonl')),'question_id')
 packets<-split(seq_len(nrow(flagged)),ceiling(seq_len(nrow(flagged))/15))
 for(i in seq_along(packets)){z<-flagged[packets[[i]],];writeLines(unlist(lapply(seq_len(nrow(z)),function(k)c(paste0('## ',z$task_id[k]),qs[[z$question_id[k]]]$question,paste('Gold:',qs[[z$question_id[k]]]$gold),paste('Reviewer:',z$reasoning[k],z$evidence[k]),z$response_text[k],''))),file.path(dir,sprintf('flagged_packet_%02d.md',i)))}
}else stop('Unknown mode')
