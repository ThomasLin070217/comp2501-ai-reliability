# Offline task and protocol freeze; this script makes no provider requests.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
root <- 'Math_Crosscheck_500'
bank <- file.path(root,'question_review_v2')
out <- file.path(root,'protocol/v2')
hash <- function(p) digest(file=p,algo='sha256')
manifest <- fromJSON(file.path(bank,'review_manifest.json'),simplifyVector=FALSE)
for(p in names(manifest$sha256)) stopifnot(identical(hash(p),manifest$sha256[[p]]))
q <- read.csv(file.path(bank,'model_inputs_500.csv'),stringsAsFactors=FALSE)
k <- read.csv(file.path(bank,'scoring_key_500.csv'),stringsAsFactors=FALSE)
stopifnot(nrow(q)==500L,identical(q$eval_id,k$eval_id),!anyDuplicated(k$seed_id))
set.seed(25011011L)
tasks <- list(); n <- 0L
for(batch in c('first_100','remaining_400')) {
  ii <- which(if(batch=='first_100') k$planned_batch=='first_100' else k$planned_batch!='first_100')
  for(i in sample(ii,length(ii))) for(model in sample(c('minimax','deepseek'),2L)) {
    n <- n+1L
    tasks[[n]] <- data.frame(task_id=paste('math_v2_initial',q$eval_id[i],model,sep=':'),
      run_order=n,batch=batch,question_order=q$question_order[i],question_id=q$eval_id[i],
      family_id=k$seed_id[i],model=model,settings_id=paste0('math_v2_',model),
      origin='independent_initial',input_text=q$input_text[i],
      stringsAsFactors=FALSE)
  }
}
t <- do.call(rbind,tasks)
stopifnot(nrow(t)==1000L,!anyDuplicated(t$task_id),all(table(t$model)==500L),
  sum(t$batch=='first_100')==200L,!any(c('reference_answer','source_solution','grade') %in% names(t)))
generation <- list(temperature=0.6,max_tokens=2048L,thinking=list(type='disabled'),stream=FALSE)
settings <- list(status='design_candidate_not_live_adapter_certification',
  provenance='Model IDs/endpoints read from local Two_Model_Collection/protocol/models.json; 2048-token/native-search settings from local fact collector. No claim of current public pricing or provider capability verification.',
  minimax=list(settings_id='math_v2_minimax',endpoint='http://www.bio8.cs.hku.hk:8080/v1/messages',
    model='MiniMax-M3',generation=generation),
  deepseek=list(settings_id='math_v2_deepseek',endpoint='https://api.deepseek.com/anthropic/v1/messages',
    model='deepseek-v4-pro',generation=generation),
  proposed_native_tools=list(list(type='web_search_20250305',name='web_search')),
  prompt_policy='Fresh session; one user message containing exact input_text only; no extra system message. No answer key or peer advice.',
  concurrency=list(total_max=4L,per_provider_max=2L),
  transport=list(connect_timeout_seconds=20L,request_timeout_seconds=240L,
    max_attempts_per_task=2L,max_pause_turn_continuations=3L,
    retry_only='Known transient transport failure or 5xx; identical payload. Unknown in-flight outcome needs reconciliation. Never retry a completed wrong answer or abstention.'),
  gate=list(before_initial='Certify actual native-tool adapter against local replay fixtures; resolve budget/quota cap from applicable current authorization; freeze live collector and effective settings before any model calls.',
    before_followup='All 1000 baseline tasks terminal, scored and frozen; all controlled materials reviewed and frozen before any follow-up response is inspected.'),
  expenditure=list(status='No new paid calls made; exact total cap is unresolved in this design artifact',
    currency='CNY',total_cap=NULL,
    guard_only_deepseek_per_million=list(input=20,output=50),
    minimax_note='Course quota, price unknown; zero in older config is not proof of free unlimited use',
    estimate_formula='Sum input_tokens*input_guard + output_tokens*output_guard, divide by 1e6; add native-tool costs if charged; record authoritative provider invoice separately.'))
dir.create(out,recursive=TRUE,showWarnings=FALSE)
write.csv(t,file.path(out,'initial_tasks_1000.csv'),row.names=FALSE)
write_json(settings,file.path(out,'collection_settings_candidate.json'),auto_unbox=TRUE,pretty=TRUE,null='null')
files <- c(file.path(bank,c('model_inputs_500.csv','scoring_key_500.csv','review_manifest.json')),
  file.path(root,'protocol/prompts.json'),file.path(out,c('initial_tasks_1000.csv','collection_settings_candidate.json')),
  file.path(root,'R',c('certify_plan.R','common.R','preflight.R','prepare.R','build_reviewed_bank.R','prepare_initial_plan.R')),
  file.path(root,c('EXPERIMENT_V2.md','COLLECTION_PLAN_V2.md')))
files <- files[file.exists(files)]
write_json(list(status='offline_design_frozen_execution_not_started',edition=manifest$edition,
  seed=25011011L,initial_tasks=1000L,self_check_target=500L,natural_crosscheck_target=500L,
  manipulated_target='C = number of initially correct MiniMax responses with approved materials; at most 500',
  sha256=setNames(as.list(vapply(files,hash,'')),files)),file.path(out,'plan_freeze.json'),auto_unbox=TRUE,pretty=TRUE)
cat('Offline initial plan: 1000 tasks, first stage 200, remaining stage 800; zero model calls.\n')
