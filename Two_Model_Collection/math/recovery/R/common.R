source('Two_Model_Collection/R/runtime.R')
REC<-'Two_Model_Collection/math/recovery'
MAIN<-'Two_Model_Collection/math'
recovery_eligible<-function(r){
 if(is.null(r))return(FALSE)
 r$status%in%c('transport_error','interrupted_unknown','incomplete') ||
 (identical(r$status,'http_error')&&!is.null(r$http_status)&&r$http_status>=500L&&r$http_status<=599L)
}
# Copy the reviewed transport implementation into a local function. Only timeout
# changes; endpoint/auth, raw retention, cost accounting and native tools remain.
recovery_http_batch<-tm_http_batch
b<-paste(deparse(body(recovery_http_batch)),collapse='\n')
stopifnot(grepl('timeout = 240',b,fixed=TRUE))
b<-sub('timeout = 240','timeout = 600',b,fixed=TRUE)
body(recovery_http_batch)<-parse(text=b)[[1]]
recovery_payload<-function(task,main_http,latest,done,prompts,cfgs){
 prior<-if(length(latest))tail(latest,1)[[1]] else main_http[[task$id]]
 if(!is.null(prior)){
  payload<-unserialize(serialize(prior$request,NULL))
  if(identical(prior$status,'incomplete')&&identical(prior$finish_reason,'max_tokens'))payload$max_tokens<-6144L
  mode<-if(payload$max_tokens==6144L)'token_limit_6144_secondary'else'exact_original_payload_retry'
 }else{
  payload<-tm_payload(task,prompts[[task$question_id]],done,cfgs[[task$provider]],'math')
  mode<-'previously_skipped_dependency_now_available'
 }
 list(payload=payload,mode=mode)
}
