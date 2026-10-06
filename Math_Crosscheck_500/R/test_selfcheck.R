#!/usr/bin/env Rscript
entry <- sub('^--file=','',grep('^--file=',commandArgs(),value=TRUE))
entry <- gsub('~+~',' ',entry,fixed=TRUE)
setwd(normalizePath(file.path(dirname(entry),'../..')))
repo <- getwd()
source('Math_Crosscheck_500/R/selfcheck_runtime.R')
source('Math_Crosscheck_500/R/common.R')
checks <- character()
check <- function(name,expr) {stopifnot(isTRUE(expr)); checks <<- c(checks,name)}
fails <- function(expr) inherits(tryCatch({force(expr); NULL},error=identity),'error')
work <- tempfile('selfcheck-offline-'); dir.create(work)
on_cleanup <- function() {setwd(repo); unlink(work,recursive=TRUE)}
tryCatch({
  baseline <- list(model='minimax',origin='independent_initial',status='complete',grade='correct',
    question_id='fixture1',initial_record_id='initial1',question_text='What is 2 + 2?',
    settings_id='fixture-settings',conversation_path='fixture-replay.json')
  task <- list(task_id='fixture1:minimax:self_check',question_id='fixture1',baseline_id='initial1',
    initial_grade='correct',family_id='fixture1',
    condition='self_check',settings_id='fixture-settings',conversation_path='fixture-replay.json',
    peer_origin='none',donor_id='',material_id='',wrong_target='',followup_prompt=sc_prompt)
  native <- list(list(type='server_tool_use',id='search1',name='web_search',input=list(query='2+2')),
    list(type='web_search_tool_result',tool_use_id='search1',content=list()),list(type='text',text='4'))
  replay <- list(request_template=list(model='MiniMax-M3',max_tokens=2048L,temperature=0.6,
    thinking=list(type='disabled'),tools=list(list(type='web_search_20250305',name='web_search')),
    system='Fixture original system.'),messages=list(list(role='user',content=baseline$question_text),
    list(role='assistant',content=native)))
  p <- sc_payload(task,baseline,replay)
  check('complete native history retained',identical(p$messages[-3L],replay$messages))
  check('exact original parameters retained',identical(p[setdiff(names(p),'messages')],replay$request_template))
  check('only neutral suffix appended',identical(p$messages[[3]]$content,sc_prompt))
  for(g in c('correct','incorrect','abstention')) {b <- baseline; b$grade <- g; check(paste('eligible',g),is.list(sc_payload(task,b,replay)))}
  bad <- task; bad$followup_prompt <- 'You are wrong. It is 5.'
  check('reject changed self prompt',fails(sc_payload(bad,baseline,replay)))
  bad <- replay; bad$request_template$headers <- list(authorization='fixture-secret')
  check('reject authentication in replay',fails(sc_payload(task,baseline,bad)))
  bad <- replay; bad$messages <- c(bad$messages,list(list(role='user',content='another followup'),list(role='assistant',content='4')))
  check('reject chained follow-up baseline',fails(sc_payload(task,baseline,bad)))
  cfg <- list(reservation_per_http=1,max_total_guard_units=20,guard_unit='course_quota_http_requests')
  pp <- file.path(work,'payload.json'); sc_write(p,pp)
  mini <- list(status='frozen_not_collected',source_sha256=list(),config=cfg,
    jobs=list(list(task=task,payload_path=pp,payload_sha256=sc_hash(pp))))
  response <- function(stop='end_turn',text='4',blocks=NULL,code=200L) list(http_status=code,
    transport_status='received',body=sc_json(list(model='fixture-returned-model',stop_reason=stop,
      content=blocks %sc% list(list(type='text',text=text)),usage=list(input_tokens=50L,output_tokens=10L))))
  calls <- 0L; good <- function(payload,cfg) {calls <<- calls+1L; response()}
  out <- file.path(work,'idempotent'); r <- run_self_check(mini,task$task_id,out,good)
  run_self_check(mini,task$task_id,out,good)
  check('completed task is not sent twice',calls==1L && r$status=='complete_pending_grade')
  check('no automatic semantic grading',r$grade=='pending')
  sc_export(mini,out); handoff <- sc_csv(file.path(out,'grading_input.csv'))
  check('grading handoff preserves raw text',handoff$answer_text=='4' && handoff$grade=='')
  unlink(file.path(out,'task_0001/final.json'))
  run_self_check(mini,task$task_id,out,good)
  check('response-to-final crash recovery without dispatch',calls==1L)
  mutate <- mini; mutate$jobs[[1]]$payload_sha256 <- 'tampered'
  check('reject payload tampering',fails(sc_verify(mutate)))
  calls <- 0L; paused <- function(payload,cfg) {
    calls <<- calls+1L
    if(calls==1L) response('pause_turn',blocks=native) else {
      check('pause continues without another user message',sum(vapply(payload$messages,function(m) m$role=='user',TRUE))==2L)
      check('paused native blocks retained',identical(payload$messages[[4]]$content,native))
      response(text='Final answer: 4')
    }
  }
  r <- run_self_check(mini,task$task_id,file.path(work,'pause'),paused)
  check('bounded same-turn continuation',calls==2L && r$continuations==1L && r$status=='complete_pending_grade')
  calls <- 0L; always_pause <- function(payload,cfg) {calls <<- calls+1L; response('pause_turn',blocks=native)}
  r <- run_self_check(mini,task$task_id,file.path(work,'pause-limit'),always_pause)
  check('pause cap is three continuations',calls==4L && r$status=='incomplete')
  calls <- 0L; transient <- function(payload,cfg) {calls <<- calls+1L; if(calls==1L) response(code=503L) else response(text='5')}
  r <- run_self_check(mini,task$task_id,file.path(work,'retry'),transient)
  check('one transient retry and no answer-dependent retry',calls==2L && r$text=='5' && r$transient_retries==1L)
  calls <- 0L; fail500 <- function(payload,cfg) {calls <<- calls+1L; response(code=500L)}
  r <- run_self_check(mini,task$task_id,file.path(work,'retry-limit'),fail500)
  check('transient retry cap',calls==2L && r$status=='technical_missing')
  r <- run_self_check(mini,task$task_id,file.path(work,'truncated'),function(p,c) response('max_tokens'))
  check('truncation remains incomplete',r$status=='incomplete' && r$grade=='pending')
  r <- run_self_check(mini,task$task_id,file.path(work,'client-tool'),function(p,c) response(blocks=list(list(type='tool_use',id='client1',name='unknown',input=list()))))
  check('client tool is not fabricated',r$status=='incomplete')
  r <- run_self_check(mini,task$task_id,file.path(work,'malformed'),function(p,c) list(http_status=200L,transport_status='received',body='invalid json'))
  check('malformed output is technical missing',r$status=='technical_missing')
  r <- run_self_check(mini,task$task_id,file.path(work,'malformed-block'),function(p,c)
    response(blocks=list(list(type='text'))))
  check('malformed content block is technical missing',r$status=='technical_missing')
  for(code in c(401L,403L,429L)) {
    calls <- 0L; auth <- function(p,c) {calls <<- calls+1L; response(code=code)}
    d <- file.path(work,paste0('auth',code))
    check(paste('stop on HTTP',code),fails(run_self_check(mini,task$task_id,d,auth)))
    check(paste('no retry on HTTP',code),fails(run_self_check(mini,task$task_id,d,auth)) && calls==1L)
  }
  calls <- 0L; unknown <- function(p,c) {calls <<- calls+1L; list(http_status=NULL,transport_status='unknown_delivery',body='')}
  d <- file.path(work,'unknown')
  check('unknown delivery stops',fails(run_self_check(mini,task$task_id,d,unknown)))
  check('unknown delivery is not resent',fails(run_self_check(mini,task$task_id,d,unknown)) && calls==1L)
  d <- file.path(work,'inflight'); dir.create(file.path(d,'task_0001'),recursive=TRUE)
  sc_write(list(payload=p),file.path(d,'task_0001/http_01_request.json'))
  check('crash-before-response prevents dispatch',fails(run_self_check(mini,task$task_id,d,good)))
  capped <- mini; capped$config$max_total_guard_units <- 1
  calls <- 0L
  check('continuation respects remaining reservation cap',fails(run_self_check(capped,task$task_id,file.path(work,'cap'),always_pause)) && calls==1L)
  other <- mini; j <- other$jobs[[1]]; j$task$task_id <- 'fixture2:minimax:self_check'; other$jobs[[2]] <- j
  check('joint task order cannot be bypassed',fails(run_self_check(other,j$task$task_id,file.path(work,'order'),good)))
  check('absent baseline waits',!mc_check(file.path(work,'absent.csv'),'Math_Crosscheck_500/question_review_v2/model_inputs_500.csv')$ready)
  setwd(work)
  rc <- system2('/usr/local/bin/Rscript',c(shQuote(file.path(repo,'Math_Crosscheck_500/R/run_selfcheck.R')),
    '--mode','check','--index',shQuote(file.path(work,'absent.csv'))),stdout=TRUE,stderr=TRUE)
  setwd(repo)
  check('absolute CLI path works outside repository',is.null(attr(rc,'status')) && any(grepl('No model requests.',rc,fixed=TRUE)))
  # End-to-end gate/freeze using the exact reviewed texts, never real observations.
  temp_repo <- file.path(work,'repo'); dir.create(temp_repo)
  stopifnot(file.copy(file.path(repo,'Math_Crosscheck_500'),temp_repo,recursive=TRUE),
    file.symlink(file.path(repo,'Reasoning_Math_500'),file.path(temp_repo,'Reasoning_Math_500')))
  setwd(temp_repo)
  unlink(c('Math_Crosscheck_500/prepared','Math_Crosscheck_500/runs'),recursive=TRUE)
  q <- mc_read_csv('Math_Crosscheck_500/question_review_v2/model_inputs_500.csv')
  rows <- list()
  for(model in c('minimax','deepseek')) for(i in seq_len(nrow(q))) {
    id <- q$eval_id[i]; path <- paste0('fixture/',model,'_',i,'.json')
    rp <- replay; rp$messages[[1]]$content <- q$input_text[i]
    rp$request_template$model <- if(model=='minimax') 'MiniMax-M3' else 'deepseek-v4-pro'
    sc_write(rp,path)
    grade <- if(model=='deepseek' || i==1L) 'correct' else if(i==2L) 'abstention' else 'incorrect'
    rows[[length(rows)+1L]] <- data.frame(question_id=id,question_text=q$input_text[i],family_id=id,
      model=model,initial_record_id=paste(id,model,sep=':'),origin='independent_initial',status='complete',
      grade=grade,answer_text='4',settings_id='explicitly_synthetic_fixture',conversation_path=path,
      grade_evidence='Offline test fixture, not an observed answer.',stringsAsFactors=FALSE)
  }
  index <- 'Math_Crosscheck_500/inputs/baseline_index.csv'
  write.csv(do.call(rbind,rows),index,row.names=FALSE)
  materials <- 'Math_Crosscheck_500/inputs/synthetic_materials.csv'
  write.csv(data.frame(question_id=q$eval_id[1],wrong_answer='999',peer_text='Fixture wrong reasoning leads to 999.',
    error_type='fixture',why_wrong='Offline only, no mathematical review claim.',review_status='approved',
    reviewer='offline fixture',reviewed_at='2026-10-06'),materials,row.names=FALSE)
  rc <- system2('/usr/local/bin/Rscript',c('Math_Crosscheck_500/R/prepare.R','--materials',materials),stdout=TRUE,stderr=TRUE)
  check('full 1000-initial preparation succeeds',is.null(attr(rc,'status')))
  cfg <- sc_read('Math_Crosscheck_500/protocol/v2/selfcheck_transport.example.json')
  cfg$adapter_verified <- TRUE; cfg$adapter_evidence_file <- 'fixture/adapter-evidence.txt'
  writeLines('OFFLINE FIXTURE ONLY: not live certification.',cfg$adapter_evidence_file)
  cfg$authorization_source <- 'OFFLINE FIXTURE ONLY'; cfg$max_total_guard_units <- 10L
  config <- 'fixture/config.json'; sc_write(cfg,config)
  plan <- sc_freeze(index,'Math_Crosscheck_500/prepared/with_controlled',config,'fixture/execution')
  sc_verify(sc_read('fixture/execution/run_manifest.json'))
  conditions <- vapply(plan$jobs,function(j) j$task$condition,'')
  check('full freeze has exactly 500 self,500 natural,1 controlled',
    sum(conditions=='self_check')==500L && sum(conditions=='natural_crosscheck')==500L && sum(conditions=='manipulated_crosscheck')==1L)
  self <- plan$jobs[conditions=='self_check']
  check('all frozen self payloads append exact neutral message',all(vapply(self,function(j) {
    x <- sc_read(j$payload_path); identical(x$messages[[length(x$messages)]]$content,sc_prompt)
  },TRUE)))
  cfg$max_total_guard_units <- 11L; write_json(cfg,config,auto_unbox=TRUE)
  check('frozen config tampering fails',fails(sc_verify(plan)))
  setwd(repo)
  report <- list(status='passed',checks=length(checks),check_names=checks,
    provider_requests=0L,fixture_scope='Temporary synthetic fixture only; removed after tests.',tested_at=sc_now())
  write_json(report,'Math_Crosscheck_500/protocol/v2/selfcheck_offline_checks.json',pretty=TRUE,auto_unbox=TRUE)
  cat(length(checks),'offline checks passed; zero provider requests.\n')
},finally=on_cleanup())
