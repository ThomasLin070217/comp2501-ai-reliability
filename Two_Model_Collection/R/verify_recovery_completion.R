source('Two_Model_Collection/R/runtime.R')
audit <- list(); ledger <- list()
for(domain in c('facts','math')) {
  root <- file.path(tm_root,domain)
  rroot <- file.path(root,'recovery')
  stopifnot(fromJSON(file.path(rroot,'runs/status.json'))$status=='finished')
  original <- tm_read(file.path(root,'runs/completed.jsonl'))
  recovered <- tm_read(file.path(rroot,'runs/completed.jsonl'))
  recovered <- recovered[!duplicated(tm_fields(recovered,'id'),fromLast=TRUE)]
  derived <- tm_read(file.path(rroot,'derived/runs/completed.jsonl'))
  expected <- setNames(original,tm_fields(original,'id'))
  for(r in recovered) expected[[r$id]] <- r
  stopifnot(!anyDuplicated(tm_fields(derived,'id')),
    setequal(tm_fields(derived,'id'),names(expected)))
  for(r in derived) for(f in c('text','status','request_sha256'))
    stopifnot(identical(r[[f]],expected[[r$id]][[f]]))
  freeze <- fromJSON(file.path(rroot,'protocol/freeze.json'),simplifyVector=FALSE)
  for(p in names(freeze$files_sha256)) stopifnot(digest(file=p,algo='sha256')==freeze$files_sha256[[p]])
  rh <- tm_read(file.path(rroot,'runs/http_responses.jsonl'))
  ra <- tm_read(file.path(rroot,'runs/attempts.jsonl'))
  stopifnot(setequal(tm_fields(rh,'id'),tm_fields(ra,'id')))
  for(h in rh) stopifnot(identical(h$request_sha256,digest(tm_json(h$request),'sha256',serialize=FALSE)))
  tasks <- read.csv(file.path(root,'protocol/tasks.csv'),stringsAsFactors=FALSE)
  audit[[domain]] <- list(planned=nrow(tasks),unique_overlay_records=length(derived),
    still_uncollected=nrow(tasks)-length(derived),recovery_targets=length(recovered),
    recovery_attempts=length(rh),recovery_final_statuses=as.list(table(tm_fields(recovered,'status'))),
    overlay_statuses=as.list(table(tm_fields(derived,'status'))),
    frozen_recovery_hashes_unchanged=TRUE,overlay_matches_original_plus_last_recovery=TRUE)
  for(layer in c('runs','recovery/runs')) {
    h <- tm_read(file.path(root,layer,'http_responses.jsonl'))
    has_usage <- vapply(h,function(r)!is.null(r$input_tokens),TRUE)
    ledger[[paste(domain,layer)]] <- data.frame(domain=domain,layer=layer,attempts=length(h),
      usage_based_guard_cny=sum(vapply(h[has_usage],function(r)r$guard_cny,0)),
      unknown_charge_reserve_cny=sum(vapply(h[!has_usage],function(r)r$guard_cny,0)),
      total_guard_cny=sum(vapply(h,function(r)r$guard_cny,0)))
  }
}
tm_write(list(time=tm_now(),status='passed',domains=audit,
  caveat='Complete native responses still require semantic grading; an ok status is not a correctness claim.'),
  file.path(tm_root,'reports/recovery_completion_audit.json'))
write.csv(do.call(rbind,ledger),file.path(tm_root,'reports/collection_cost_ledger.csv'),row.names=FALSE)
cat('Recovery overlays, hashes and attempt accounting verified.\n')
