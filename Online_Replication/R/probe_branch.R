source('Online_Replication/R/http.R')
cfgs<-read_json(file.path(OROOT,'protocol/models.json'))
records<-indexed(oread(file.path(OROOT,'runs/responses.jsonl')),'id')
for(p in names(cfgs)){
 cfg<-cfgs[[p]];initial<-records[[paste0('probe:native:',p,':',if(p=='kimi')2 else 1)]]
 payload<-initial$request
 payload$messages<-c(payload$messages,list(if(cfg$protocol=='anthropic')list(role='assistant',content=initial$raw_response$content)else initial$raw_response$choices[[1]]$message),
   list(list(role='user',content='Please check your answer again.')))
 for(turn in 1:4){
  id<-paste0('probe:branch:',p,':',turn);old<-records[[id]]
  r<-if(is.null(old))ohttp(payload,cfg,id,'probe',2,budget=20)else old
  cat(p,turn,r$http_status%||%'transport',r$status,'search',r$search$requested%||%0,'guard',r$guard_cny,'\n');flush.console()
  if(r$status!='tool_call'||p!='kimi')break
  msg<-r$raw_response$choices[[1]]$message;payload$messages<-c(payload$messages,list(msg))
  for(tc in msg$tool_calls){stopifnot(tc[['function']]$name=='$web_search');payload$messages<-c(payload$messages,list(list(role='tool',tool_call_id=tc$id,name='$web_search',content=tc[['function']]$arguments)))}
 }
}
