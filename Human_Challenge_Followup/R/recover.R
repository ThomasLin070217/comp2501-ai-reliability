source('Two_Model_Collection/R/runtime.R')
root <- 'Human_Challenge_Followup'
run <- file.path(root,'runs')
recdir <- file.path(root,'recovery')
dir.create(recdir,recursive=TRUE,showWarnings=FALSE)
cfgs <- fromJSON('Two_Model_Collection/protocol/models.json',simplifyVector=FALSE)
orig <- tm_read(file.path(run,'completed.jsonl'))
tasks <- fromJSON(file.path(root,'protocol/manifest.json'),simplifyVector=FALSE)$tasks
stopifnot(length(orig)==length(tasks),setequal(tm_fields(orig,'id'),tm_fields(tasks,'id')))
orig_http <- tm_read(file.path(run,'http_responses.jsonl'))
by_http <- setNames(orig_http,tm_fields(orig_http,'task_id'))
technical <- c('transport_error','incomplete','http_error','invalid_json_response')
plan_path <- file.path(recdir,'plan.json')
if (!file.exists(plan_path)) {
  failed <- Filter(function(x)x$status%in%technical,orig)
  tm_write(list(original_completed_sha256=digest(file=file.path(run,'completed.jsonl'),algo='sha256'),
    original_http_sha256=digest(file=file.path(run,'http_responses.jsonl'),algo='sha256'),
    failed_ids=tm_fields(failed,'id'),maximum_extra_attempts=2L,
    selection='Use first status=ok technical retry; otherwise last allowed attempt. No retry for valid but wrong, abstaining, or malformed response.'),plan_path)
}
plan <- fromJSON(plan_path,simplifyVector=FALSE)
stopifnot(identical(plan$original_completed_sha256,digest(file=file.path(run,'completed.jsonl'),algo='sha256')),
  identical(plan$original_http_sha256,digest(file=file.path(run,'http_responses.jsonl'),algo='sha256')),
  setequal(unlist(plan$failed_ids),tm_fields(Filter(function(x)x$status%in%technical,orig),'id')))
tm_load_credentials()
ap <- file.path(recdir,'attempts.jsonl'); rp <- file.path(recdir,'http_responses.jsonl')
attempts <- tm_read(ap); results <- tm_read(rp)
stopifnot(!length(setdiff(tm_fields(attempts,'id'),tm_fields(results,'id'))))
for (round in seq_len(plan$maximum_extra_attempts)) {
  jobs <- list()
  for (id in unlist(plan$failed_ids)) {
    older <- Filter(function(x) startsWith(x$task_id,paste0(id,':technical_retry')),results)
    if (any(vapply(older,function(x)identical(x$status,'ok'),TRUE))) next
    tid <- paste0(id,':technical_retry',round)
    if (any(tm_fields(results,'task_id')==tid)) next
    original <- by_http[[id]]
    stopifnot(!is.null(original),identical(original$request_sha256,
      digest(tm_json(original$request),'sha256',serialize=FALSE)))
    t <- Filter(function(z)identical(z$id,id),tasks)[[1]]
    t$id <- tid
    jobs[[length(jobs)+1L]] <- list(task=t,payload=original$request)
  }
  if (length(jobs)) for (start in seq(1L,length(jobs),by=4L)) {
    batch <- jobs[start:min(length(jobs),start+3L)]
    rr <- tm_http_batch(batch,cfgs,ap,rp,0,Inf)
    results <- c(results,rr)
    cat('Technical retry',round,'completed',min(start+3L,length(jobs)),'/',length(jobs),'\n')
  }
}
selected <- orig
for (i in seq_along(selected)) {
  id <- selected[[i]]$id
  if (!id%in%unlist(plan$failed_ids)) next
  attempts <- Filter(function(x)startsWith(x$task_id,paste0(id,':technical_retry')),results)
  if (!length(attempts)) next
  successful <- Filter(function(x)identical(x$status,'ok'),attempts)
  picked <- if (length(successful))successful[[1]] else tail(attempts,1)[[1]]
  selected[[i]]$status <- picked$status
  selected[[i]]$text <- picked$text %or% ''
  selected[[i]]$http_id <- picked$id
  selected[[i]]$guard_cny <- picked$guard_cny
  selected[[i]]$search_requested <- picked$search_requested %or% 0
  selected[[i]]$finish_reason <- picked$finish_reason %or% NULL
  selected[[i]]$request_sha256 <- picked$request_sha256
  selected[[i]]$technical_retry <- picked$task_id
}
out <- file.path(recdir,'selected.jsonl')
if(file.exists(out))unlink(out)
for(x in selected)tm_append(x,out)
cat('Selected',length(selected),'records; technically ok',sum(vapply(selected,function(x)x$status=='ok',TRUE)),'\n')
