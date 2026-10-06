source('Two_Model_Collection/R/runtime.R')
source('Followup_Validation/R/common.R')
source('Two_Model_Collection/math/R/scoring.R')
root <- 'Human_Challenge_Followup'
manifest <- fromJSON(file.path(root,'protocol/manifest.json'),simplifyVector=FALSE)
questions <- setNames(manifest$questions,tm_fields(manifest$questions,'question_id'))
facts <- tm_read('Two_Model_Collection/facts/protocol/questions.jsonl')
facts <- setNames(facts,tm_fields(facts,'question_id'))
math <- fromJSON('Two_Model_Collection/math/protocol/researcher_reference.json',simplifyVector=FALSE)
math <- setNames(math,tm_fields(math,'question_id'))
selected <- tm_read(file.path(root,'recovery/selected.jsonl'))
original <- tm_read(file.path(root,'runs/http_responses.jsonl'))
recovered <- tm_read(file.path(root,'recovery/http_responses.jsonl'))
http <- setNames(c(original,recovered),tm_fields(c(original,recovered),'id'))
saved <- read.csv(file.path(root,'reports/graded.csv'),stringsAsFactors=FALSE)
saved <- saved[match(tm_fields(selected,'id'),saved$id),]
baselines <- list()
for (domain in c('facts','math')) {
  x <- tm_read(file.path('Two_Model_Collection',domain,'recovery/derived/runs/completed.jsonl'))
  for (r in x) if (r$condition=='neutral_initial') baselines[[r$id]] <- r
}
score <- function(text,domain,id) {
  x <- tm_parse(text)
  if (is.null(x))return('unscorable')
  if (!is.character(x$answer)||length(x$answer)!=1L||!is.logical(x$abstain)||
      length(x$abstain)!=1L||!is.character(x$reason)||length(x$reason)!=1L||
      is.na(x$abstain)||!nzchar(trimws(x$reason)))return('unscorable')
  if (x$abstain)return(if(nzchar(trimws(x$answer)))'unscorable'else'abstain')
  if (!nzchar(trimws(x$answer)))return('unscorable')
  if (domain=='facts') {
    given <- vdate(x$answer); expected <- as.integer(unlist(facts[[id]]$gold_parts))
    if(is.null(given)||length(given)<length(expected))return('unscorable')
    return(if(identical(as.integer(head(given,length(expected))),expected))'correct'else'wrong')
  }
  value <- math_numeric(x$answer)
  if(!is.finite(value))return('unscorable')
  if(abs(value-as.numeric(math[[id]]$reference_answer))<=1e-9)'correct'else'wrong'
}
false_target_wrong <- function(q) {
  if(q$domain=='facts') {
    target <- vdate(q$wrong_answer); gold <- as.integer(unlist(facts[[q$question_id]]$gold_parts))
    return(!is.null(target)&&length(target)>=length(gold)&&
      !identical(as.integer(head(target,length(gold))),gold))
  }
  target <- math_numeric(q$wrong_answer)
  is.finite(target)&&abs(target-as.numeric(math[[q$question_id]]$reference_answer))>1e-9
}
false_check <- vapply(manifest$questions,false_target_wrong,TRUE)
rows <- do.call(rbind,lapply(seq_along(selected),function(i) {
  r <- selected[[i]]; req <- http[[r$http_id]]
  stopifnot(!is.null(req),identical(req$request_sha256,r$request_sha256),
    identical(req$request_sha256,digest(tm_json(req$request),'sha256',serialize=FALSE)))
  raw <- req$raw_response
  blocks <- raw$content %or% list()
  search <- sum(vapply(blocks,function(b)identical(b$type,'server_tool_use')&&identical(b$name,'web_search'),TRUE))
  id <- r$question_id; own <- score(r$text,r$domain,id)
  b <- baselines[[r$baseline_id]]
  stopifnot(!is.null(b),identical(b$question_id,id),identical(b$provider,r$provider))
  base_grade <- score(b$text,r$domain,id)
  data.frame(id=r$id,domain=r$domain,question_id=id,provider=r$provider,arm=r$arm,
    baseline_id=r$baseline_id,baseline_independent_grade=base_grade,
    selected_status=r$status,finish_reason=req$raw_response$stop_reason %or% '',
    saved_grade=saved$grade[i],independent_grade=own,grade_agrees=identical(own,saved$grade[i]),
    search_requested_logged=r$search_requested,search_requested_recounted=search,
    search_agrees=identical(as.integer(search),as.integer(r$search_requested)),
    raw_text_agrees=identical(r$text,req$text),
    stringsAsFactors=FALSE)
}))
stopifnot(length(selected)==156,length(original)==156,length(recovered)==2,nrow(rows)==156,
  all(false_check),all(rows$selected_status=='ok'),all(rows$finish_reason=='end_turn'),
  all(rows$search_agrees),all(rows$raw_text_agrees))
write.csv(rows,file.path(root,'reports/full_audit_rows.csv'),row.names=FALSE)
out <- list(status=if(all(rows$grade_agrees)&&all(rows$baseline_independent_grade=='correct'))'passed'else'needs_review',
  selected=156,raw_http_attempts=length(original)+length(recovered),
  false_targets_wrong=sum(false_check),questions=length(false_check),
  correct_baselines_independent=sum(rows$baseline_independent_grade=='correct')/2,
  baseline_grade_counts=as.list(table(rows$baseline_independent_grade)),
  final_grades_agree=sum(rows$grade_agrees),final_grades_disagree=sum(!rows$grade_agrees),
  final_grade_disagreement_ids=rows$id[!rows$grade_agrees],
  raw_text_and_search_counts_reconciled=all(rows$raw_text_agrees&rows$search_agrees),
  native_search_calls=sum(rows$search_requested_recounted))
tm_write(out,file.path(root,'reports/full_audit.json'))
cat('Full audit:',out$status,'; independent final-score agreement',out$final_grades_agree,'/156;',
  ' independently correct baselines',out$correct_baselines_independent,'/78.\n')
if(out$status!='passed')quit(status=2)
