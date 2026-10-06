# Integrity/coverage checks for the design artifacts; no API calls.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
root <- 'Math_Crosscheck_500'; bank <- file.path(root,'question_review_v2')
for(f in c(file.path(bank,'review_manifest.json'),file.path(root,'protocol/v2/plan_freeze.json'))) {
  m <- fromJSON(f,simplifyVector=FALSE)
  for(p in names(m$sha256)) stopifnot(identical(digest(file=p,algo='sha256'),m$sha256[[p]]))
}
q <- read.csv(file.path(bank,'model_inputs_500.csv'),stringsAsFactors=FALSE)
k <- read.csv(file.path(bank,'scoring_key_500.csv'),stringsAsFactors=FALSE)
t <- read.csv(file.path(root,'protocol/v2/initial_tasks_1000.csv'),stringsAsFactors=FALSE)
r <- read.csv(file.path(bank,'revisions.csv'),stringsAsFactors=FALSE)
stopifnot(nrow(q)==500L,nrow(t)==1000L,identical(q$eval_id,k$eval_id),
  all(nchar(q$input_text)<=300L),all(t$input_text==q$input_text[match(t$question_id,q$eval_id)]),
  all(table(t$model)==500L),all(table(paste(t$model,t$question_id))==1L),
  sum(t$batch=='first_100')==200L,!anyDuplicated(k$seed_id),
  sum(k$reference_answer=='None')==150L,all(abs(as.numeric(k$reference_answer[k$answer_kind=='numeric']))<=1000),
  all(k$max_number_in_question<=1000),all(k$question_chars==nchar(q$input_text)),
  sum(r$original_reference!=r$reviewed_reference)==7L,
  !any(c('reference_answer','source_solution','grade','perturbation_type') %in% names(t)))
expected <- c(`87`=12-6,`136`=24+(2/3)*24-6+4*12,
  `186`=(60-60*2/3)/2/2,`290`=26-(26/2-10),
  `357`=300+300/2+150,`442`=(10*15+75)*(1-0.4)-40,`456`=60-10)
stopifnot(all(as.numeric(k$reference_answer[as.integer(names(expected))])==unname(expected)))
cat('PASS: reviewed-bank hashes, 500 unique families, 1000 unique initial cells, 200/800 stage split, no evaluator fields in model task manifest.\n')
