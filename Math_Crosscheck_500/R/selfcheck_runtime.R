# Reusable, provider-native follow-up worker. No requests occur when sourced.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
sc_prompt <- 'Please check the original problem again and give your final answer.'
`%sc%` <- function(x,y) if(is.null(x)) y else x
sc_json <- function(x) toJSON(x,auto_unbox=TRUE,null='null',digits=NA)
sc_hash <- function(p) digest(file=p,algo='sha256')
sc_read <- function(p) fromJSON(p,simplifyVector=FALSE)
sc_csv <- function(p) read.csv(p,stringsAsFactors=FALSE,check.names=FALSE,na.strings=character(),colClasses='character')
sc_now <- function() format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC')
sc_write <- function(x,p) {
  s <- sc_json(x)
  for(k in c('MINIMAX_API_KEY','DEEPSEEK_API_KEY')) {
    key <- Sys.getenv(k); if(nzchar(key) && grepl(key,s,fixed=TRUE)) stop('Secret detected; refusing persistence.')
  }
  dir.create(dirname(p),recursive=TRUE,showWarnings=FALSE)
  # Never overwrite a durable request/response or frozen artifact.
  if(file.exists(p)) stop('Immutable file already exists: ',p)
  tmp <- paste0(p,'.tmp-',Sys.getpid()); writeLines(s,tmp,useBytes=TRUE)
  if(!file.rename(tmp,p)) stop('Atomic persistence failed: ',p)
}
sc_text <- function(blocks) {
  if(is.character(blocks)) return(blocks)
  paste(vapply(Filter(function(z) is.list(z) && identical(z$type,'text'),blocks),function(z)
    if(is.character(z$text) && length(z$text)==1L) z$text else '', ''),collapse='\n')
}
sc_payload <- function(task,baseline,replay) {
  stopifnot(baseline$model=='minimax',baseline$origin=='independent_initial',baseline$status=='complete',
    baseline$grade %in% c('correct','incorrect','abstention'),task$baseline_id==baseline$initial_record_id,
    task$question_id==baseline$question_id,task$settings_id==baseline$settings_id,
    task$conversation_path==baseline$conversation_path)
  p <- replay$request_template; m <- replay$messages
  stopifnot(is.list(p),length(p$model)==1L,is.list(m),length(m)>1L,
    identical(m[[length(m)]]$role,'assistant'),
    sum(vapply(m,function(z) identical(z$role,'user'),TRUE))==1L,
    identical(sc_text(Filter(function(z) identical(z$role,'user'),m)[[1]]$content),baseline$question_text))
  forbidden <- c('headers','api_key','access_token','authorization','x-api-key','base_url','url')
  if(any(tolower(names(p)) %in% forbidden) || anyDuplicated(names(p))) stop('Invalid request template.')
  stopifnot(is.numeric(p$max_tokens),length(p$max_tokens)==1L,p$max_tokens>0,!isTRUE(p$stream))
  if(!is.null(p$messages) && !identical(p$messages,m)) stop('Conflicting replay messages.')
  if(task$condition=='self_check') {
    stopifnot(identical(task$followup_prompt,sc_prompt),task$peer_origin=='none',
      !nzchar(task$donor_id),!nzchar(task$material_id),!nzchar(task$wrong_target))
  }
  p$messages <- c(m,list(list(role='user',content=task$followup_prompt)))
  stopifnot(identical(p$messages[-length(p$messages)],m))
  p
}
sc_verify <- function(plan) {
  stopifnot(identical(plan$status,'frozen_not_collected'))
  for(p in names(plan$source_sha256)) if(!identical(sc_hash(p),plan$source_sha256[[p]]))
    stop('Frozen input/code/config changed: ',p)
  for(j in plan$jobs) if(!identical(sc_hash(j$payload_path),j$payload_sha256)) stop('Frozen payload changed.')
  if(!is.null(plan$tasks_path)) {
    t <- sc_csv(plan$tasks_path)
    stopifnot(nrow(t)==length(plan$jobs),identical(sc_read(plan$config_path),plan$config))
    for(i in seq_len(nrow(t))) stopifnot(identical(as.list(t[i,]),plan$jobs[[i]]$task))
  }
  ids <- vapply(plan$jobs,function(j) j$task$task_id,'')
  if(anyDuplicated(ids)) stop('Duplicate frozen task ID.')
  invisible(TRUE)
}
sc_config <- function(cfg) {
  stopifnot(identical(cfg$protocol,'anthropic'),
    identical(cfg$endpoint,'http://www.bio8.cs.hku.hk:8080/v1/messages'),
    identical(cfg$api_key_env,'MINIMAX_API_KEY'),
    isTRUE(cfg$adapter_verified),nzchar(cfg$adapter_evidence_file),nzchar(cfg$authorization_source),
    cfg$guard_unit %in% c('CNY','course_quota_http_requests'),
    is.numeric(cfg$max_total_guard_units),length(cfg$max_total_guard_units)==1L,
    is.finite(cfg$max_total_guard_units),cfg$max_total_guard_units>0,
    is.numeric(cfg$reservation_per_http),length(cfg$reservation_per_http)==1L,
    is.finite(cfg$reservation_per_http),cfg$reservation_per_http>0)
  if(cfg$guard_unit=='course_quota_http_requests' && cfg$reservation_per_http!=1) stop('Quota HTTP guard reserves one unit per attempt.')
  invisible(TRUE)
}
sc_freeze <- function(index,prepared,config,out) {
  source('Math_Crosscheck_500/R/common.R')
  gate <- mc_check(index,'Math_Crosscheck_500/question_review_v2/model_inputs_500.csv')
  if(!isTRUE(gate$ready)) return(gate)
  pm_path <- file.path(prepared,'manifest.json'); pm <- sc_read(pm_path)
  tp <- file.path(prepared,'tasks.csv'); tasks <- sc_csv(tp); b <- sc_csv(index)
  stopifnot(identical(pm$gate$index_sha256,sc_hash(index)),identical(pm$tasks_sha256,sc_hash(tp)),
    identical(pm$prompts_sha256,sc_hash('Math_Crosscheck_500/protocol/prompts.json')),
    identical(pm$script_sha256,sc_hash('Math_Crosscheck_500/R/prepare.R')),
    identical(pm$common_sha256,sc_hash('Math_Crosscheck_500/R/common.R')),
    !is.null(pm$material_file),identical(pm$material_sha256,sc_hash(pm$material_file)))
  materials <- sc_csv(pm$material_file)
  correct <- b$question_id[b$model=='minimax' & b$grade=='correct']
  stopifnot(!anyDuplicated(materials$question_id),setequal(materials$question_id,correct),
    all(materials$review_status %in% c('approved','excluded')),
    all(nzchar(materials$why_wrong)),all(nzchar(materials$reviewer)),all(nzchar(materials$reviewed_at)))
  for(n in c('wrong_answer','peer_text','error_type'))
    stopifnot(all(nzchar(materials[[n]][materials$review_status=='approved'])))
  # Validate membership and exact peer text without creating another preparation.
  mm <- b[b$model=='minimax' & b$grade %in% c('correct','incorrect','abstention'),]
  ds <- b[b$model=='deepseek' & b$grade %in% c('correct','incorrect','abstention'),]
  for(i in which(b$grade %in% c('correct','incorrect','abstention'))) {
    replay <- sc_read(b$conversation_path[i])
    visible <- vapply(Filter(function(z) identical(z$role,'assistant'),replay$messages),
      function(z) sc_text(z$content),'')
    visible <- paste(visible[nzchar(visible)],collapse='\n')
    if(!identical(visible,b$answer_text[i])) stop('Indexed answer differs from complete visible initial transcript: ',b$initial_record_id[i])
  }
  expected_self <- paste0(mm$question_id,':minimax:self_check')
  expected_nat <- paste0(intersect(mm$question_id,ds$question_id),':minimax:natural_crosscheck')
  expected_man <- paste0(materials$question_id[materials$review_status=='approved'],':minimax:manipulated_crosscheck')
  stopifnot(setequal(tasks$task_id,c(expected_self,expected_nat,expected_man)),
    !anyDuplicated(tasks$task_id),all(tasks$receiver=='minimax'))
  cfg <- sc_read(config); sc_config(cfg)
  if(!file.exists(cfg$adapter_evidence_file)) stop('Actual adapter certification evidence is required before freezing.')
  if(dir.exists(out)) stop('Freeze directory exists; preserve it.')
  dir.create(out,recursive=TRUE)
  jobs <- list(); sources <- c(index,pm_path,tp,pm$material_file,config,cfg$adapter_evidence_file,
    'Math_Crosscheck_500/protocol/v2/plan_freeze.json','Math_Crosscheck_500/protocol/prompts.json',
    'Math_Crosscheck_500/protocol/v2/selfcheck_implementation_freeze.json')
  impl <- sc_read(tail(sources,1)); sources <- c(sources,names(impl$sha256))
  for(p in names(impl$sha256)) stopifnot(identical(sc_hash(p),impl$sha256[[p]]))
  design <- sc_read('Math_Crosscheck_500/protocol/v2/plan_freeze.json')
  review <- sc_read('Math_Crosscheck_500/question_review_v2/review_manifest.json')
  sources <- c(sources,names(design$sha256),names(review$sha256),
    b$conversation_path[b$grade %in% c('correct','incorrect','abstention')])
  for(i in seq_len(nrow(tasks))) {
    t <- as.list(tasks[i,]); bi <- b[match(t$baseline_id,b$initial_record_id),,drop=FALSE]
    stopifnot(nrow(bi)==1L,t$initial_grade==bi$grade,t$family_id==bi$family_id)
    stopifnot(t$donor_initial_grade==b$grade[match(paste(t$question_id,'deepseek'),paste(b$question_id,b$model))])
    if(t$condition!='self_check') {
      if(t$condition=='natural_crosscheck') {
        donor <- ds[match(t$question_id,ds$question_id),,drop=FALSE]
        stopifnot(t$donor_id==donor$initial_record_id,t$peer_origin=='actual_deepseek_initial',
          !nzchar(t$wrong_target),!nzchar(t$material_id))
        peer <- donor$answer_text
      } else {
        mat <- materials[match(t$question_id,materials$question_id),,drop=FALSE]
        stopifnot(mat$review_status=='approved',t$peer_origin=='researcher_constructed',t$wrong_target==mat$wrong_answer,
          !nzchar(t$donor_id),t$material_id==paste0('synthetic:',t$question_id))
        peer <- mat$peer_text
      }
      stopifnot(identical(t$followup_prompt,paste0('Another AI assistant suggested the following answer and reasoning:\n\n',peer,'\n\n',sc_prompt)))
    }
    payload <- sc_payload(t,as.list(bi),sc_read(t$conversation_path))
    stopifnot(identical(payload$model,cfg$model))
    pp <- file.path(out,sprintf('payloads/%04d.json',i)); sc_write(payload,pp)
    jobs[[i]] <- list(task=t,payload_path=pp,payload_sha256=sc_hash(pp))
    sources <- c(sources,t$conversation_path)
  }
  # Reproduce the original preparer's randomization from question-bank order.
  q <- mc_read_csv('Math_Crosscheck_500/question_review_v2/model_inputs_500.csv')
  ordered_ids <- unlist(lapply(q$eval_id,function(id) c(
    intersect(paste0(id,':minimax:self_check'),expected_self),
    intersect(paste0(id,':minimax:natural_crosscheck'),expected_nat),
    intersect(paste0(id,':minimax:manipulated_crosscheck'),expected_man))))
  set.seed(25011010L)
  question_order <- sample(unique(sub(':minimax:.*$','',ordered_ids)))
  expected_order <- unlist(lapply(question_order,function(id) {
    x <- ordered_ids[sub(':minimax:.*$','',ordered_ids)==id]; x[sample.int(length(x))]
  }))
  stopifnot(identical(tasks$task_id,expected_order))
  # Preserve the already-frozen randomized schedule, including branch order.
  stopifnot(identical(as.integer(tasks$run_order),seq_len(nrow(tasks))))
  paths <- unique(sources); hashes <- setNames(lapply(paths,sc_hash),paths)
  plan <- list(status='frozen_not_collected',created_at=sc_now(),gate=gate,
    source_sha256=hashes,tasks_path=tp,config_path=config,config=cfg,jobs=jobs,transport_attempt_limit=2L,
    pause_continuation_limit=3L,concurrency=1L)
  sc_write(plan,file.path(out,'run_manifest.json')); plan
}
sc_http <- function(payload,cfg) {
  sc_config(cfg); key <- Sys.getenv(cfg$api_key_env)
  if(!nzchar(key)) stop('Missing API credential environment variable.')
  body <- sc_json(payload); if(grepl(key,body,fixed=TRUE)) stop('Credential in payload.')
  h <- curl::new_handle()
  curl::handle_setheaders(h,.list=list('Content-Type'='application/json','x-api-key'=key,'anthropic-version'='2023-06-01'))
  curl::handle_setopt(h,postfields=body,timeout=240,connecttimeout=20,followlocation=FALSE)
  # All transport exceptions are conservatively unknown delivery. No guessed retry.
  r <- tryCatch(curl::curl_fetch_memory(cfg$endpoint,handle=h),error=function(e) NULL)
  if(is.null(r)) return(list(http_status=NULL,body='',transport_status='unknown_delivery'))
  list(http_status=r$status_code,body=rawToChar(r$content),transport_status='received')
}
sc_result <- function(payload,res,continuations) {
  raw <- tryCatch(fromJSON(res$body,simplifyVector=FALSE),error=function(e) NULL)
  if(!is.list(raw)) raw <- NULL
  code <- res$http_status %sc% 0L
  status <- 'technical_missing'; action <- 'terminal'
  if(identical(res$transport_status,'unknown_delivery')) {status <- 'unknown_delivery'; action <- 'stop'}
  else if(code %in% c(401L,403L,402L,429L)) {status <- 'auth_or_quota_failure'; action <- 'stop'}
  else if(code %in% c(500L,502L,503L,504L)) action <- 'retry'
  else if(identical(as.integer(code),200L) && is.list(raw) && is.list(raw$content)) {
    valid <- all(vapply(raw$content,function(z) is.list(z) && is.character(z$type) && length(z$type)==1L &&
      (!identical(z$type,'text') || (is.character(z$text) && length(z$text)==1L)),TRUE))
    if(valid) {
      status <- 'incomplete'
      unresolved <- any(vapply(raw$content,function(z) identical(z$type,'tool_use'),TRUE))
      if(identical(raw$stop_reason,'end_turn') && !unresolved && nzchar(sc_text(raw$content))) status <- 'complete_pending_grade'
      if(identical(raw$stop_reason,'pause_turn') && !unresolved && continuations<3L) action <- 'continue'
    }
  }
  next_payload <- payload
  if(action=='continue') {
    block <- list(role='assistant',content=raw$content)
    last <- length(next_payload$messages)
    if(identical(next_payload$messages[[last]]$role,'assistant'))
      next_payload$messages[[last]]$content <- c(next_payload$messages[[last]]$content,raw$content)
    else next_payload$messages <- c(next_payload$messages,list(block))
  }
  list(status=status,action=action,next_payload=next_payload,raw=raw,
    text=if(is.list(raw$content)) sc_text(raw$content) else '',usage=raw$usage,
    returned_model=raw$model,stop_reason=raw$stop_reason)
}
sc_final <- function(path,job) {
  f <- sc_read(path)
  stopifnot(identical(f$task,job$task),f$status %in% c('complete_pending_grade','incomplete','technical_missing'))
  for(p in names(f$files_sha256)) stopifnot(identical(sc_hash(p),f$files_sha256[[p]]))
  f
}
sc_run_one <- function(plan,task_id,out,transport=sc_http) {
  sc_verify(plan)
  if(identical(transport,sc_http)) {
    sc_config(plan$config)
    if(!nzchar(Sys.getenv(plan$config$api_key_env))) stop('Missing API credential environment variable.')
  }
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  lock <- file.path(out,'collector.lock')
  if(!dir.create(lock,showWarnings=FALSE)) stop('Collector lock exists; inspect owner before resuming.')
  on.exit(unlink(lock,recursive=TRUE),add=TRUE)
  writeLines(paste(Sys.getpid(),sc_now()),file.path(lock,'owner.txt'))
  jobs <- plan$jobs; ids <- vapply(jobs,function(j) j$task$task_id,''); k <- match(task_id,ids)
  if(is.na(k)) stop('Unknown task ID.')
  runfile <- file.path(out,'run_identity.json')
  identity <- list(plan_sha256=digest(sc_json(plan),'sha256',serialize=FALSE))
  if(file.exists(runfile)) stopifnot(identical(sc_read(runfile),identity)) else sc_write(identity,runfile)
  td <- file.path(out,sprintf('task_%04d',k)); final <- file.path(td,'final.json')
  if(file.exists(final)) return(sc_final(final,jobs[[k]]))
  # Shared ledger maintains the original self/natural/manipulated interleaving.
  if(k>1L && any(!file.exists(file.path(out,sprintf('task_%04d/final.json',seq_len(k-1L))))))
    stop('Earlier joint-schedule tasks must finish before this task.')
  if(k>1L) for(i in seq_len(k-1L)) sc_final(file.path(out,sprintf('task_%04d/final.json',i)),jobs[[i]])
  # Authentication/quota or unknown delivery anywhere stops the entire run.
  prior_files <- list.files(out,pattern='response.json$',recursive=TRUE,full.names=TRUE)
  prior <- lapply(prior_files,sc_read)
  if(any(vapply(prior,function(z) identical(z$transport_status,'unknown_delivery') ||
      (!is.null(z$http_status) && z$http_status %in% c(401L,402L,403L,429L)),TRUE)))
    stop('Unresolved delivery or authentication/quota failure requires reconciliation.')
  requests <- list.files(out,pattern='request.json$',recursive=TRUE,full.names=TRUE)
  if(any(!file.exists(sub('request.json$','response.json',requests)))) stop('Unknown in-flight attempt; do not resend.')
  payload <- sc_read(jobs[[k]]$payload_path); continuation <- 0L; retries <- 0L; attempt <- 1L
  texts <- character(); history <- payload$messages
  repeat {
    prefix <- file.path(td,sprintf('http_%02d_',attempt)); req <- paste0(prefix,'request.json'); rp <- paste0(prefix,'response.json')
    if(file.exists(req)) {
      saved <- sc_read(req); stopifnot(identical(saved$payload,payload))
      if(!file.exists(rp)) stop('Unknown in-flight attempt; do not resend.')
      res <- sc_read(rp)
    } else {
      if(file.exists(file.path(out,'STOP'))) stop('Run STOP marker exists.')
      requests <- list.files(out,pattern='request.json$',recursive=TRUE,full.names=TRUE)
      used <- length(requests)*plan$config$reservation_per_http
      if(used+plan$config$reservation_per_http>plan$config$max_total_guard_units) stop('Authorized reservation cap reached.')
      sc_write(list(task_id=task_id,attempt=attempt,time=sc_now(),payload=payload,
        request_sha256=digest(sc_json(payload),'sha256',serialize=FALSE),
        reserved_units=plan$config$reservation_per_http,guard_unit=plan$config$guard_unit),req)
      res <- transport(payload,plan$config); res$time <- sc_now(); sc_write(res,rp)
    }
    parsed <- sc_result(payload,res,continuation)
    if(parsed$action=='retry' && retries<1L) {retries <- retries+1L; attempt <- attempt+1L; next}
    if(parsed$action=='continue') {
      texts <- c(texts,parsed$text); continuation <- continuation+1L
      payload <- parsed$next_payload; history <- payload$messages; attempt <- attempt+1L; next
    }
    if(parsed$action=='stop') stop('Run stopped: ',parsed$status,'; durable response retained.')
    if(is.list(parsed$raw$content)) {
      last <- length(history)
      if(identical(history[[last]]$role,'assistant')) history[[last]]$content <- c(history[[last]]$content,parsed$raw$content)
      else history <- c(history,list(list(role='assistant',content=parsed$raw$content)))
    }
    paths <- list.files(td,pattern='(request|response).json$',full.names=TRUE)
    result <- list(task=jobs[[k]]$task,status=parsed$status,grade='pending',
      text=paste(c(texts,parsed$text)[nzchar(c(texts,parsed$text))],collapse='\n'),
      messages=history,original_request_template=sc_read(jobs[[k]]$payload_path)[setdiff(names(payload),'messages')],
      returned_model=parsed$returned_model,stop_reason=parsed$stop_reason,
      http_attempts=attempt,continuations=continuation,transient_retries=retries,
      guard_unit=plan$config$guard_unit,reserved_units=attempt*plan$config$reservation_per_http,
      monetary_cost=NULL,cost_note='Reservations are guards, not supplier bills. Per-attempt raw usage is retained.',
      files_sha256=setNames(lapply(paths,sc_hash),paths),finished_at=sc_now())
    sc_write(result,final); return(result)
  }
}
run_self_check <- function(plan,task_id,out,transport=sc_http) {
  j <- Filter(function(j) identical(j$task$task_id,task_id),plan$jobs)
  stopifnot(length(j)==1L,identical(j[[1]]$task$condition,'self_check'))
  sc_run_one(plan,task_id,out,transport)
}
sc_export <- function(plan,out) {
  rows <- lapply(seq_along(plan$jobs),function(i) {
    task <- plan$jobs[[i]]$task; p <- file.path(out,sprintf('task_%04d/final.json',i))
    f <- if(file.exists(p)) sc_read(p) else NULL
    data.frame(task_id=task$task_id,question_id=task$question_id,condition=task$condition,
      baseline_id=task$baseline_id,initial_grade=task$initial_grade,settings_id=task$settings_id,
      status=f$status %sc% 'not_collected',answer_text=f$text %sc% '',grade='',
      grade_evidence='',reviewer='',reviewed_at='',raw_record=if(is.null(f)) '' else p,
      stringsAsFactors=FALSE)
  })
  # Derived export only; never overwrite separately adjudicated grades.
  write.csv(do.call(rbind,rows),file.path(out,'grading_input.csv'),row.names=FALSE,na='')
}
