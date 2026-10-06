suppressPackageStartupMessages({library(jsonlite); library(digest)})
mc_root <- 'Math_Crosscheck_500'
mc_args <- function(args=commandArgs(trailingOnly=TRUE)) {
  out <- list(index=file.path(mc_root,'inputs/baseline_index.csv'),
              questions=file.path(mc_root,'question_review_v2/model_inputs_500.csv'), materials=NULL)
  if(length(args) %% 2L) stop('Arguments must be --index, --questions or --materials followed by a path.')
  if(length(args)) for(i in seq(1,length(args),by=2)) {
    key <- sub('^--','',args[i])
    if(!key %in% names(out)) stop('Unknown option.')
    out[[key]] <- args[i+1L]
  }
  out
}
mc_json <- function(x,p) write_json(x,p,auto_unbox=TRUE,pretty=TRUE,null='null')
mc_hash <- function(p) digest(file=p,algo='sha256')
mc_read_csv <- function(p) read.csv(p,stringsAsFactors=FALSE,check.names=FALSE,na.strings=character())
mc_check <- function(index,questions) {
  reviewed_path <- file.path(mc_root,'question_review_v2/model_inputs_500.csv')
  if(identical(questions,reviewed_path)) {
    manifest <- fromJSON(file.path(mc_root,'question_review_v2/review_manifest.json'),simplifyVector=FALSE)
    for(p in names(manifest$sha256)) if(!identical(mc_hash(p),manifest$sha256[[p]]))
      stop('Reviewed bank or source evidence changed after the review freeze: ',p)
    plan <- fromJSON(file.path(mc_root,'protocol/v2/plan_freeze.json'),simplifyVector=FALSE)
    for(p in names(plan$sha256)) if(!identical(mc_hash(p),plan$sha256[[p]]))
      stop('The v2 offline protocol changed after its design freeze: ',p)
  } else stop('This study is bound to the reviewed v2 bank. A different bank requires an explicit protocol amendment.')
  if(!file.exists(index)) return(list(ready=FALSE,phase='waiting_for_initial_collection',
    expected_initial_tasks=1000L,index_exists=FALSE,reason='No finalized baseline index.',
    question_bank_sha256=mc_hash(questions),
    scoring_key_sha256=mc_hash(file.path(mc_root,'question_review_v2/scoring_key_500.csv'))))
  if(!file.exists(questions)) stop('The actual frozen question input file is required.')
  b <- mc_read_csv(index); q <- mc_read_csv(questions)
  needed <- c('question_id','question_text','family_id','model','initial_record_id','origin',
              'status','grade','answer_text','settings_id','conversation_path','grade_evidence')
  if(!all(needed %in% names(b)) || !all(c('eval_id','input_text') %in% names(q)))
    stop('Baseline or question schema is incomplete; see inputs/README.md.')
  if(nrow(q)!=500L || anyDuplicated(q$eval_id) || any(!nzchar(q$eval_id)) || any(!nzchar(q$input_text)))
    stop('The frozen bank must contain exactly 500 unique, nonempty question IDs/texts.')
  if(any(!b$model %in% c('minimax','deepseek')) ||
     anyDuplicated(paste(b$question_id,b$model,sep=':')) ||
     anyDuplicated(b$initial_record_id) || any(!nzchar(b$initial_record_id)))
    stop('Invalid provider, repeated question/model cell or repeated/missing initial observation ID.')
  if(any(!b$question_id %in% q$eval_id) || any(b$question_text != q$input_text[match(b$question_id,q$eval_id)]))
    stop('Initial question IDs/texts do not match the bound frozen bank.')
  if(any(b$origin!='independent_initial') || any(!nzchar(b$family_id)))
    stop('Only independent initial responses with base-family IDs are allowed.')
  terminal <- c('complete','technical_failure','incomplete','unscorable')
  grades <- c('correct','incorrect','abstention','unscorable','missing')
  if(any(!b$grade %in% grades)) stop('Invalid or unresolved initial grade.')
  if(any(!b$status %in% terminal) || nrow(b)!=1000L ||
     any(table(factor(b$model,levels=c('minimax','deepseek'))) != 500L))
    return(list(ready=FALSE,phase='waiting_for_initial_collection',index_exists=TRUE,
      expected_initial_tasks=1000L,observed_initial_tasks=nrow(b),reason='Incomplete terminal task coverage.'))
  if(!identical(sort(b$question_id[b$model=='minimax']),sort(b$question_id[b$model=='deepseek'])))
    stop('The two models do not cover the same 500 questions.')
  mm <- b[b$model=='minimax',]; ds <- b[b$model=='deepseek',]
  if(any(mm$family_id != ds$family_id[match(mm$question_id,ds$question_id)])) stop('Base-family labels disagree across models.')
  scorable <- b$grade %in% c('correct','incorrect','abstention')
  if(any(scorable & b$status!='complete') || any(!scorable & b$status=='complete'))
    stop('Completion status and final score label conflict.')
  if(any(!nzchar(b$answer_text[scorable])) || any(!nzchar(b$settings_id[scorable])) ||
     any(!nzchar(b$grade_evidence[scorable])) || any(!file.exists(b$conversation_path[scorable])))
    stop('A scorable initial response lacks its answer, settings, grade evidence or replay file.')
  for(p in unique(b$conversation_path[scorable])) {
    c <- fromJSON(p,simplifyVector=FALSE)
    if(is.null(c$request_template) || is.null(c$request_template$model) || !length(c$messages) ||
       !identical(c$messages[[length(c$messages)]]$role,'assistant') ||
       sum(vapply(c$messages,function(m)identical(m$role,'user'),TRUE))!=1L)
      stop('Replay must be a complete initial conversation with exactly one user question.')
    if(any(c('headers','api_key','access_token','authorization','x-api-key') %in% names(c$request_template)))
      stop('Replay template must not contain authentication fields.')
  }
  for(i in which(scorable)) {
    c <- fromJSON(b$conversation_path[i],simplifyVector=FALSE)
    first_user <- Filter(function(m)identical(m$role,'user'),c$messages)[[1L]]$content
    if(is.list(first_user)) first_user <- paste(vapply(Filter(function(z)identical(z$type,'text'),first_user),function(z)z$text,''),collapse='\n')
    if(!identical(as.character(first_user),b$question_text[i])) stop('Replay question does not match indexed question.')
  }
  ds <- ds[match(mm$question_id,ds$question_id),]
  natural <- mm$grade %in% c('correct','incorrect','abstention') & ds$grade %in% c('correct','incorrect','abstention')
  list(ready=TRUE,phase='ready_for_followup_preparation',expected_initial_tasks=1000L,
    observed_initial_tasks=nrow(b),scorable_initial_tasks=sum(scorable),
    self_check_eligible=sum(mm$grade %in% c('correct','incorrect','abstention')),
    natural_crosscheck_eligible=sum(natural),
    correction_opportunities=sum(natural & mm$grade=='incorrect' & ds$grade=='correct'),
    natural_incorrect_peer_opportunities=sum(natural & mm$grade=='correct' & ds$grade=='incorrect'),
    controlled_correct_initial_candidates=sum(mm$grade=='correct'),
    missing_or_unscorable_initial_tasks=sum(!scorable),
    index_sha256=mc_hash(index),question_bank_sha256=mc_hash(questions),
    scoring_key_sha256=mc_hash(file.path(mc_root,'question_review_v2/scoring_key_500.csv')))
}
