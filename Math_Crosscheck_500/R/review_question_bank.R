# Independent file checks and source-solution arithmetic checks; no model calls.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
bank <- 'Reasoning_Math_500'; out <- 'Math_Crosscheck_500/question_review_v2'
dir.create(out,recursive=TRUE,showWarnings=FALSE)
q <- read.csv(file.path(bank,'model_inputs_500.csv'),stringsAsFactors=FALSE)
k <- read.csv(file.path(bank,'scoring_key_500.csv'),stringsAsFactors=FALSE)
first <- read.csv(file.path(bank,'first_batch_100.csv'),stringsAsFactors=FALSE)
manifest <- fromJSON(file.path(bank,'selection_manifest.json'),simplifyVector=FALSE)
normalize <- function(x) tolower(gsub('[^[:alnum:]]+',' ',trimws(x)))
stopifnot(nrow(q)==500L,nrow(k)==500L,identical(q$eval_id,k$eval_id),
  identical(q$question_order,1:500),identical(first,q[1:100,]),
  !anyDuplicated(q$eval_id),!anyDuplicated(normalize(q$input_text)),!anyDuplicated(k$seed_id),
  all(nzchar(q$input_text)),all(nchar(q$input_text)<=300L),
  sum(k$answer_kind=='numeric')==350L,sum(k$answer_kind=='insufficient_information')==150L)
src <- tempfile(fileext='.jsonl')
download.file(manifest$source_url,src,quiet=TRUE,mode='wb')
stopifnot(identical(digest(file=src,algo='sha256'),manifest$source_sha256))
s <- stream_in(file(src),verbose=FALSE)
stopifnot(all(q$input_text==s$question[k$source_row]),all(k$reference_answer==s$answer[k$source_row]),
  all(k$source_solution==s$solution[k$source_row]),all(k$perturbation_type==s$perturbation_type[k$source_row]))
unlinked <- unlink(src)
safe_number <- function(x) {
  x <- gsub(',','',trimws(x),fixed=TRUE)
  if(!grepl('^[0-9. ()+*/^%-]+$',x) || nchar(x)>200L) return(NA_real_)
  z <- tryCatch(parse(text=x),error=function(e)NULL)
  valid <- function(y) {
    if(is.numeric(y)) return(length(y)==1L)
    if(!is.call(y)) return(FALSE)
    if(!as.character(y[[1]]) %in% c('(','+','-','*','/','^','%%')) return(FALSE)
    all(vapply(as.list(y)[-1],valid,TRUE))
  }
  if(length(z)!=1L || !valid(z[[1]])) return(NA_real_)
  v <- tryCatch(eval(z[[1]],envir=baseenv()),error=function(e)NA_real_)
  if(length(v)!=1L || !is.finite(v)) NA_real_ else as.numeric(v)
}
equations <- list(); final_source <- character(500L)
for(i in seq_len(nrow(k))) {
  hits <- regmatches(k$source_solution[i],gregexpr('<<[^<>]+>>',k$source_solution[i],perl=TRUE))[[1]]
  for(h in hits) {
    e <- strsplit(sub('>>$','',sub('^<<','',h)),'=',fixed=TRUE)[[1]]
    lhs <- if(length(e)==2L) safe_number(e[1]) else NA_real_
    rhs <- if(length(e)==2L) safe_number(e[2]) else NA_real_
    equations[[length(equations)+1L]] <- data.frame(eval_id=k$eval_id[i],equation=h,lhs=lhs,rhs=rhs,
      arithmetic_status=if(!is.finite(lhs)||!is.finite(rhs)) 'not_machine_checked' else if(abs(lhs-rhs)<=1e-8*max(1,abs(rhs))) 'consistent' else 'mismatch',stringsAsFactors=FALSE)
  }
  lines <- strsplit(k$source_solution[i],'\n',fixed=TRUE)[[1]]
  tails <- grep('^####',trimws(lines),value=TRUE)
  final_source[i] <- if(length(tails)) trimws(sub('^####','',tail(tails,1))) else ''
}
eq <- if(length(equations)) do.call(rbind,equations) else data.frame()
write.csv(eq,file.path(out,'source_equation_checks.csv'),row.names=FALSE,na='')
review <- data.frame(question_order=q$question_order,eval_id=q$eval_id,question_text=q$input_text,
  category=k$perturbation_type,answer_kind=k$answer_kind,source_reference=k$reference_answer,
  source_final=final_source,source_final_matches=final_source==k$reference_answer,
  arithmetic_equations=vapply(k$eval_id,function(id)sum(eq$eval_id==id),0L),
  arithmetic_mismatches=vapply(k$eval_id,function(id)sum(eq$eval_id==id & eq$arithmetic_status=='mismatch'),0L),
  stringsAsFactors=FALSE)
write.csv(review,file.path(out,'machine_audit.csv'),row.names=FALSE)
write_json(list(status='file_and_arithmetic_checked_not_full_mathematical_proof',questions=500,
  distinct_base_problems=length(unique(k$seed_id)),categories=as.list(table(k$perturbation_type)),
  numeric_reference_answers=350,missing_information_reference_answers=150,
  first_batch_categories=as.list(table(k$perturbation_type[1:100])),
  source_equations=nrow(eq),equations_consistent=sum(eq$arithmetic_status=='consistent'),
  equations_mismatched=sum(eq$arithmetic_status=='mismatch'),equations_not_checked=sum(eq$arithmetic_status=='not_machine_checked'),
  source_final_mismatch=sum(!review$source_final_matches),
  input_sha256=digest(file=file.path(bank,'model_inputs_500.csv'),algo='sha256'),
  key_sha256=digest(file=file.path(bank,'scoring_key_500.csv'),algo='sha256'),
  manifest_sha256=digest(file=file.path(bank,'selection_manifest.json'),algo='sha256'),
  source_sha256=manifest$source_sha256),file.path(out,'machine_audit.json'),auto_unbox=TRUE,pretty=TRUE)
cat('500 file/source records checked;',nrow(eq),'source equations;',sum(eq$arithmetic_status=='mismatch'),'arithmetic mismatches; source-final mismatches',sum(!review$source_final_matches),'\n')
