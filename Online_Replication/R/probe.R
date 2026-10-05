source('Online_Replication/R/http.R')
cfgs<-read_json(file.path(OROOT,'protocol/models.json'))
# Connectivity only, outside the formal question bank; no search instruction.
q<-list(domain='facts',question='Who won the 2025 Nobel Prize in Physics?')
for(p in names(cfgs)){
 cfg<-cfgs[[p]];payload<-opayload(list(list(role='system',content='Answer the question concisely.'),list(role='user',content=q$question)),q,cfg)
 for(turn in 1:4){
  id<-paste0('probe:native:',p,':',turn)
  old<-indexed(oread(file.path(OROOT,'runs/responses.jsonl')),'id')[[id]]
  out<-if(is.null(old))ohttp(payload,cfg,id,'probe',2,budget=15)else old
  cat(p,turn,out$http_status%||%'transport',out$status,'search requests',out$search$requested%||%0,'guard',out$guard_cny,'\n');flush.console()
  if(out$status!='tool_call')break
  if(p!='kimi')break
  msg<-out$raw_response$choices[[1]]$message
  payload$messages<-c(payload$messages,list(msg))
  for(tc in msg$tool_calls){
   stopifnot(identical(tc[['function']]$name,'$web_search'))
   payload$messages<-c(payload$messages,list(list(role='tool',tool_call_id=tc$id,name='$web_search',content=tc[['function']]$arguments)))
  }
 }
}
