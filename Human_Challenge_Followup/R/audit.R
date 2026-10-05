source('Two_Model_Collection/R/runtime.R')
root <- 'Human_Challenge_Followup'
orig <- tm_read(file.path(root,'runs/http_responses.jsonl'))
retry <- tm_read(file.path(root,'recovery/http_responses.jsonl'))
selected <- tm_read(file.path(root,'recovery/selected.jsonl'))
graded <- read.csv(file.path(root,'reports/graded.csv'),stringsAsFactors=FALSE)
paired <- read.csv(file.path(root,'reports/paired.csv'),stringsAsFactors=FALSE)
review <- read.csv(file.path(root,'reports/manual_case_review.csv'),stringsAsFactors=FALSE)
tasks <- fromJSON(file.path(root,'protocol/manifest.json'),simplifyVector=FALSE)$tasks
stopifnot(length(orig)==156,length(retry)==2,length(selected)==156,
  length(unique(tm_fields(selected,'id')))==156,
  setequal(tm_fields(selected,'id'),tm_fields(tasks,'id')),
  all(tm_fields(selected,'status')=='ok'),
  identical(sort(tm_fields(Filter(function(x)x$status!='ok',orig),'status')),
    sort(c('incomplete','transport_error'))))
by_orig <- setNames(orig,tm_fields(orig,'task_id'))
by_selected <- setNames(selected,tm_fields(selected,'id'))
for (r in retry) {
  parent <- sub(':technical_retry[12]$','',r$task_id)
  stopifnot(parent %in% names(by_orig),by_orig[[parent]]$status!='ok',
    identical(r$request_sha256,by_orig[[parent]]$request_sha256),
    identical(by_selected[[parent]]$http_id,r$id))
}
for (id in setdiff(names(by_orig),sub(':technical_retry[12]$','',tm_fields(retry,'task_id'))))
  stopifnot(identical(by_selected[[id]]$http_id,by_orig[[id]]$id))
for (i in seq_len(nrow(paired))) {
  p <- paired[i,]
  n <- by_orig[[p$neutral_id]]$request
  h <- by_orig[[p$challenge_id]]$request
  stopifnot(identical(n$system,h$system),identical(n$model,h$model),
    identical(n$max_tokens,h$max_tokens),identical(n$tools,h$tools),
    identical(n$messages[-length(n$messages)],h$messages[-length(h$messages)]),
    !identical(tail(n$messages,1),tail(h$messages,1)))
}
stopifnot(nrow(paired)==78,nrow(graded)==156,nrow(review)==5,
  all(table(graded$grade)[c('correct','abstain','wrong')]==c(149,2,5)),
  sum(graded$arm=='human_challenge' & graded$grade=='wrong')==4,
  all(graded$adopted_false_answer[graded$arm=='human_challenge' & graded$grade=='wrong']),
  all(review$final_answer!=review$reference_answer))
out <- list(status='passed',questions=39,correct_initial_answer_cells=78,
  paired_followups=78,selected_responses=156,first_pass_technical_failures=2,
  successful_technical_retries=2,grades=list(correct=149,abstain=2,wrong=5),
  challenge_wrong=4,challenge_adopted_false_answer=4,neutral_wrong=1,
  baseline_and_request_equality_pairs=78,
  conservative_guard_cny=sum(vapply(c(orig,retry),function(x)x$guard_cny,0)))
tm_write(out,file.path(root,'reports/validation.json'))
cat('Independent acquisition and scoring audit passed.\n')
