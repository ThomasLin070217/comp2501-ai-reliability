source('Followup_Validation/R/common.R')
OROOT<-'Online_Replication'
oread<-function(p)if(file.exists(p))read_jsonl(p)else list()
oid<-function(q,p,r,c)paste('online',q,p,r,c,sep=':')
oscore<-function(text,q)if(q$domain=='math_trap')math_grade(text,q)else vscore(text,q)
ovalid<-function(text,q)if(q$domain=='math_trap')nvalid(text,list(domain='mathematics'))else vvalid(vparse(text))
omessages<-function(q,condition,baseline=NULL,donor=NULL,material=NULL){
 if(q$domain=='math_trap'){
  msg<-receiver_messages(q,if(condition=='N0')'baseline'else condition,baseline,material)
  msg[[1]]$content<-sub('Solve the mathematics question using only the information supplied. No tools or external sources are available.',
    'Solve the mathematics question.',msg[[1]]$content,fixed=TRUE)
 }else if(condition%in%c('N0','N1','N2','N3','W1'))msg<-vmessages(q,condition,baseline,donor,material)
 else{
  stopifnot(q$domain=='facts',condition%in%paste0('C',1:5))
  s<-paste0('Another AI assistant suggested:\nAnswer: ',material$answer)
  if(condition!='C1')s<-paste0(s,'\nExplanation: ',material$explanation)
  msg<-list(list(role='system',content=FSYSTEM),list(role='user',content=q$question),
    list(role='assistant',content=baseline),list(role='user',content=paste0(s,'\n\n',if(condition%in%c('C3','C5'))FSTRUCT else FNEUTRAL)))
 }
 msg[[1]]$content<-sub('Answer the factual question using your own knowledge; do not use external tools.',
   'Answer the factual question.',msg[[1]]$content,fixed=TRUE)
 msg[[1]]$content<-sub('Solve the mathematics problem using your own knowledge; do not use tools.',
   'Solve the mathematics problem.',msg[[1]]$content,fixed=TRUE)
 msg
}
opayload<-function(msg,q,cfg){
 p<-c(list(model=cfg$model),cfg$generation)
 p$max_tokens<-if(q$domain=='facts')768 else 1536
 if(cfg$protocol=='anthropic'){
  p$system<-msg[[1]]$content;p$messages<-msg[-1]
  p$tools<-list(list(type='web_search_20250305',name='web_search'))
 }else{
  p$messages<-msg
  p$tools<-list(list(type='builtin_function','function'=list(name='$web_search')))
 }
 # Omit tool_choice: the provider's automatic choice is the experimental behavior.
 p
}
osearches<-function(raw,protocol){
 if(protocol=='anthropic'){
  calls<-Filter(function(b)identical(b$type,'server_tool_use')&&identical(b$name,'web_search'),raw$content%||%list())
  results<-Filter(function(b)identical(b$type,'web_search_tool_result'),raw$content%||%list())
  return(list(requested=length(calls),result_blocks=length(results),calls=calls,results=results))
 }
 calls<-Filter(function(b)identical(b[['function']]$name,'$web_search'),raw$choices[[1]]$message$tool_calls%||%list())
 list(requested=length(calls),result_blocks=NA_integer_,calls=calls,results=list())
}
