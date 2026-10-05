# Independent, read-only verification of the original scheduled collection.
# Technical recovery is a separate appendix and is not substituted here.
source('Two_Model_Collection/R/runtime.R')
out <- file.path(tm_root, 'reports')
dir.create(out, recursive=TRUE, showWarnings=FALSE)
summaries <- list()
for (domain in c('facts','math')) {
  root <- file.path(tm_root, domain)
  tasks <- read.csv(file.path(root,'protocol/tasks.csv'), stringsAsFactors=FALSE, na.strings=NULL)
  records <- tm_read(file.path(root,'runs/completed.jsonl'))
  http <- tm_read(file.path(root,'runs/http_responses.jsonl'))
  attempts <- tm_read(file.path(root,'runs/attempts.jsonl'))
  skips <- tm_read(file.path(root,'runs/skipped.jsonl'))
  ids <- tm_fields(records,'id'); skip_ids <- tm_fields(skips,'id')
  stopifnot(!anyDuplicated(ids), !anyDuplicated(skip_ids), !length(intersect(ids,skip_ids)),
    setequal(c(ids,skip_ids),tasks$id),
    setequal(tm_fields(attempts,'id'),tm_fields(http,'id')),
    setequal(ids,tm_fields(http,'task_id')))
  h <- setNames(http,tm_fields(http,'task_id'))
  for (r in records) {
    stopifnot(identical(r$request_sha256,h[[r$id]]$request_sha256),
      identical(r$request_sha256,digest(tm_json(h[[r$id]]$request),'sha256',serialize=FALSE)),
      identical(r$status,h[[r$id]]$status))
  }
  freeze <- fromJSON(file.path(root,'protocol/freeze.json'),simplifyVector=FALSE)
  for(p in names(freeze$files_sha256)) stopifnot(digest(file=p,algo='sha256')==freeze$files_sha256[[p]])
  paired_check <- 'analysis not yet current'
  grades_file <- file.path(root,'reports/graded_responses.csv')
  if(file.exists(grades_file)) {
    d <- read.csv(grades_file,stringsAsFactors=FALSE)
    if(setequal(d$id,ids)) {
      a <- subset(d,condition=='self_check' & !is.na(error))
      b <- subset(d,condition=='A0_AI' & !is.na(error))
      p <- merge(a,b,by=c('question_id','provider','repeat_id'),suffixes=c('_a','_b'))
      if(nrow(p)) {
        q <- aggregate(cbind(error_a,error_b)~question_id+provider,p,mean)
        m <- aggregate(cbind(error_a,error_b)~provider,q,mean)
        e <- subset(read.csv(file.path(root,'reports/paired_effects.csv')),comparison=='natural_crosscheck')
        stopifnot(nrow(e)==1L,e$pairs==nrow(p),
          abs(mean(m$error_a)-e$error_a)<1e-10,abs(mean(m$error_b)-e$error_b)<1e-10)
      }
      paired_check <- 'passed: re-averaged repetitions, questions and models from graded records'
    }
  }
  status_counts <- table(tm_fields(records,'status'))
  summaries[[domain]] <- list(planned=nrow(tasks),recorded=length(records),
    dependency_skipped=length(skips),pending=0L,status_counts=as.list(status_counts),
    guard_cny=sum(vapply(http,function(r)r$guard_cny,0)),paired_estimator_check=paired_check,
    audit='All task IDs terminal, attempts accounted for, request hashes matched, original frozen protocol unchanged.')
}
tm_write(list(time=tm_now(),status='passed',scope='Original scheduled runs only; terminal tasks are not all valid answers.',
  domains=summaries),file.path(out,'original_completion_audit.json'))
cat('Original completion audit passed.\n')
