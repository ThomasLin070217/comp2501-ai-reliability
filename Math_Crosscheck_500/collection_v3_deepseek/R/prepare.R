suppressPackageStartupMessages({library(jsonlite);library(digest)})
root <- 'Math_Crosscheck_500'
bank <- file.path(root,'question_review_v3')
out <- file.path(root,'collection_v3_deepseek')
q <- read.csv(file.path(bank,'model_inputs_500.csv'),stringsAsFactors=FALSE,check.names=FALSE)
k <- read.csv(file.path(bank,'scoring_key_500.csv'),stringsAsFactors=FALSE,check.names=FALSE)
stopifnot(nrow(q)==500L,nrow(k)==500L,identical(q$eval_id,k$eval_id),!anyDuplicated(q$eval_id),
  !anyDuplicated(k$seed_id),all(k$answer_kind=='numeric'),all(nzchar(q$input_text)))
set.seed(25011013L)
tasks <- list(); n<-0L
for(batch in c('first_100','remaining_400')){
 ix<-if(batch=='first_100')which(k$planned_batch=='first_100') else which(k$planned_batch!='first_100')
 stopifnot(length(ix)==if(batch=='first_100')100L else 400L)
 for(i in sample(ix)){
  n<-n+1L
  tasks[[n]]<-data.frame(task_id=paste('math_v3_deepseek_initial',q$eval_id[i],sep=':'),
   task_order=n,batch=batch,question_order=q$question_order[i],eval_id=q$eval_id[i],
   provider='deepseek',model='deepseek-v4-pro',repeat_id=1L,origin='independent_initial',
   input_text=q$input_text[i],stringsAsFactors=FALSE)
 }
}
t<-do.call(rbind,tasks)
stopifnot(nrow(t)==500L,!anyDuplicated(t$task_id),all(table(t$batch)==c(first_100=100,remaining_400=400)),
  !any(c('reference_answer','source_solution','grade','category')%in%names(t)))
write.csv(t,file.path(out,'protocol/tasks_deepseek_500.csv'),row.names=FALSE,na='')
sha<-function(p)digest(file=p,algo='sha256')
write_json(list(title='COMP2501 Math Initial Response Accuracy, GSM-Plus source-restored v3',
 edition='question_review_v3',created_at=format(Sys.time(),tz='UTC',usetz=TRUE),
 model='deepseek-v4-pro',provider='deepseek',target_responses=500L,repeats_per_question=1L,
 task_order_seed=25011013L,batches=list(first_100=100L,remaining_400=400L),
 user_message_rule='Send input_text verbatim as the only user message in a fresh conversation; no added system message or output format.',
 tools=list(native_web_search='available; model chooses whether to use it'),
 generation=list(temperature=0.6,max_tokens=2048L,stream=FALSE,thinking='disabled',concurrency_total_max=2L,concurrency_per_provider_max=2L),
 transport=list(max_attempts=2L,retry_only='One retry after a known HTTP 5xx response with identical payload.',
  unknown_delivery='Stop collection; reconcile before resending.',quota='Stop on HTTP 401, 402, 403 or 429; do not automatically continue after provider failure.',
  content_based_retry=FALSE,abstention='Retain as an outcome; never retry based on answer content.',
  incomplete='Retain raw stop reason and classify separately; continue same assistant turn only through a frozen native-history continuation protocol.'),
 cost_tracking=list(monetary_cap='No new numeric spend cap was specified in this request.',
  accounting='Record actual input/output/cache tokens and native search counts. Calculate a conservative DeepSeek usage guard separately from any invoice; stop on auth or quota failures.'),
 hashes=list(question_input=sha(file.path(bank,'model_inputs_500.csv')),
  scoring_key=sha(file.path(bank,'scoring_key_500.csv')),
  review_manifest=sha(file.path(bank,'review_manifest.json')),
  task_manifest=sha(file.path(out,'protocol/tasks_deepseek_500.csv')),
  collector_code=sha(file.path(out,'R/collect.R')),prepare_code=sha(file.path(out,'R/prepare.R')),
  provider_settings=sha(file.path('Two_Model_Collection/protocol/models.json')))),
 file.path(out,'protocol/run_manifest.json'),auto_unbox=TRUE,pretty=TRUE)
cat('Prepared and froze',nrow(t),'DeepSeek-only tasks;',sum(t$batch=='first_100'),'first stage; no API calls in prepare step.\n')
