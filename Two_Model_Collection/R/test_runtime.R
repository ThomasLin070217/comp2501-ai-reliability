source('Two_Model_Collection/R/runtime.R')
stopifnot(is.null(tm_parse('{"answer":"x","answer":"y","reason":"test","abstain":false}')))
cfgs<-fromJSON('Two_Model_Collection/protocol/models.json',simplifyVector=FALSE)
budget<-fromJSON('Two_Model_Collection/protocol/budget.json',simplifyVector=FALSE)
stopifnot(sum(unlist(budget$domain_caps))+budget$prior_guard_cny+budget$prior_unresolved_reservation_cny+budget$unallocated_safety_margin_cny==500)
stopifnot(setequal(names(cfgs),c('minimax','deepseek')))
tests<-list(disjoint_budget_caps=TRUE,only_two_models=TRUE)
for(domain in c('facts','math')){
 tasks<-read.csv(file.path(tm_root,domain,'protocol/tasks.csv'),stringsAsFactors=FALSE,na.strings=NULL)
 prompts<-fromJSON(file.path(tm_root,domain,'protocol/prompts.json'),simplifyVector=FALSE)$questions
 p<-prompts[[1]]
 for(i in seq_len(nrow(tasks)))for(dep in c(tasks$baseline_id[i],tasks$donor_id[i]))if(nzchar(dep))stopifnot(match(dep,tasks$id)<i)
 for(prompt in prompts){
  t<-list(id='SYNTHETIC_ONLY',condition='neutral_initial',provider='minimax',question_id=prompt$question_id,repeat_id=1)
  pay<-tm_payload(t,prompt,list(),cfgs$minimax,domain)
  stopifnot(identical(pay$messages[[1]]$content,prompt$question),is.null(pay$tool_choice),length(pay$tools)==1,identical(pay$system,prompt$system))
  t$condition<-'misconception_initial';pay<-tm_payload(t,prompt,list(),cfgs$minimax,domain)
  stopifnot(identical(pay$messages[[1]]$content,prompt$prompts$misconception_initial))
 }
 qid<-p$question_id
 text<-tm_json(list(answer='TEST ONLY',abstain=FALSE,reason='TEST ONLY: uncertain claim with retained citation.'))
 content<-list(list(type='server_tool_use',id='TEST_SEARCH',name='web_search',input=list(query='TEST_QUERY')),
   list(type='web_search_tool_result',tool_use_id='TEST_SEARCH',content=list()),list(type='text',text=text))
 base<-list(status='ok',text=text,question_id=qid,provider='minimax',repeat_id=1L,condition='neutral_initial',transcript=list(list(role='assistant',content=content)))
 donor<-base;donor$provider<-'deepseek';donor$transcript<-NULL
 d1<-donor;d1$condition<-'misconception_initial'
 done<-list(b=base,d=donor,d1=d1)
 t<-list(id='SYNTHETIC_ONLY',condition='A0_AI',provider='minimax',question_id=qid,repeat_id=1L,baseline_id='b',donor_id='d')
 ai<-tm_payload(t,p,done,cfgs$minimax,domain);t$condition<-'A0_Human';hu<-tm_payload(t,p,done,cfgs$minimax,domain)
 stopifnot(identical(ai$messages[[2]],base$transcript[[1]]),identical(ai$messages[1:2],hu$messages[1:2]),
  identical(sub('^[^\n]*\n','',ai$messages[[3]]$content),sub('^[^\n]*\n','',hu$messages[[3]]$content)))
 t$condition<-'A1_AI';t$donor_id<-'d1';a1<-tm_payload(t,p,done,cfgs$minimax,domain)
 stopifnot(identical(a1$messages[[3]]$content,ai$messages[[3]]$content))
 t$repeat_id<-2L
 stopifnot(inherits(tryCatch(tm_payload(t,p,done,cfgs$minimax,domain),error=function(e)e),'error'))
 tests[[paste0(domain,'_dependencies_stems_tools_attribution_histories_repeat_isolation')]]<-TRUE
}
stopifnot(identical(tm_parse('```json\n{"answer":"x","reason":"A {brace} and \\\"quote\\\"","abstain":false}\n```')$answer,'x'))
stopifnot(is.null(tm_parse('{"answer":"x","reason":"one","abstain":false} {"answer":"y","reason":"two","abstain":false}')))
stopifnot(!tm_usable(list(status='ok',text='{"answer":"x","reason":"test","abstain":"false"}')))
stopifnot(tm_usable(list(status='ok',text='{"answer":"","reason":"I cannot determine it.","abstain":true}')))
tests$schema_conflicts_braces_quotes_abstention<-TRUE
tm_write(list(status='pass',groups=tests,model_calls=0,fixtures='Synthetic only; never written to experiment runs.'),'Two_Model_Collection/protocol/runtime_checks.json')
cat('Runtime offline checks pass; no HTTP calls.\n')
