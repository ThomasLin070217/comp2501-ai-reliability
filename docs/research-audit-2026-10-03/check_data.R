# Read-only research audit. Run from the repository root with Rscript.
# Recompute scores from raw logs; never modify frozen inputs or main results.
source('Natural_Crosscheck/R/common.R')
out <- 'docs/research-audit-2026-10-03'
dir.create(out, recursive=TRUE, showWarnings=FALSE)
checks <- list()
check <- function(name, ok) {stopifnot(isTRUE(ok)); checks[[name]] <<- TRUE}
valid <- c('correct','incorrect','abstain')

# Old factual raw data, requests, scoring and final counts.
root <- 'Peer_Misleading_Study'
a <- assemble(root)
qs <- read_jsonl(file.path(root,'data/main_questions.jsonl'))
decisions <- read_json(file.path(root,'data/main_adjudications.json'))
branch <- audit_branches(qs, read_json(file.path(root,'data/main_frozen/materials.json')), a$records, a$manifest)
old <- score_records(qs,a$records,decisions)
og <- quality_filter(old)$grades
saved <- read.csv(file.path(root,'reports/main_r/graded_responses.csv'))
ix <- match(og$task_id,saved$task_id)
check('BC_raw_grades_match_5033_saved', nrow(og)==5033 && !anyNA(ix) && identical(og$grade,saved$grade[ix]))
oc <- make_cells(og)
check('BC_719_complete_units_120_questions', nrow(oc)==719 && length(unique(oc$question_id))==120)
old_counts <- do.call(rbind,lapply(CONDITIONS,function(k){v<-oc[[k]];data.frame(module='BC',condition=k,n=length(v),correct=sum(v=='correct'),wrong=sum(v=='incorrect'),abstain=sum(v=='abstain'))}))
tt <- subset(read.csv(file.path(root,'reports/main_r/tables.csv')),provider=='pooled')
check('BC_all_reported_counts_match', all(old_counts$correct==tt$correct[match(old_counts$condition,tt$condition)]) && all(old_counts$wrong==tt$incorrect[match(old_counts$condition,tt$condition)]) && all(old_counts$abstain==tt$abstain[match(old_counts$condition,tt$condition)]))

# Original mathematics supplement: raw scoring and complete-unit count.
mq <- indexed(read_jsonl('Math_Supplement/protocol/questions.jsonl'),'question_id')
mr <- unlist(lapply(MODELS,function(p)read_jsonl(file.path('Math_Supplement/runs',p,'responses.jsonl'))),recursive=FALSE)
mr <- Filter(function(r)r$stage=='receive' && r$split=='supplementary',mr)
mg <- read.csv('Math_Supplement/reports/supplementary/graded_responses.csv')
regraded <- vapply(mr,function(r)if(r$status=='ok')math_grade(r$text,mq[[r$question_id]]) else 'unscorable','')
mix <- match(field(mr,'task_id'),mg$task_id)
check('old_math_all_546_raw_grades_match_71_complete_units',length(mr)==546 && !anyNA(mix) && identical(unname(regraded),mg$grade[mix]) && length(unique(mg$cell_id[mg$complete_pair]))==71)

# A raw logs and full reconstruction of requests, not just hashes.
nqs <- indexed(read_jsonl('Natural_Crosscheck/protocol/questions.jsonl'),'question_id')
freeze <- read_json('Natural_Crosscheck/protocol/freeze.json')
check('A_all_frozen_hashes_match', all(vapply(names(freeze$files_sha256),function(p)file_sha(p)==freeze$files_sha256[[p]],TRUE)))
nr <- unlist(lapply(MODELS,function(p)read_jsonl(file.path('Natural_Crosscheck/runs',p,'responses.jsonl'))),recursive=FALSE)
ni <- indexed(nr,'task_id')
ng <- read.csv('Natural_Crosscheck/reports/graded_responses.csv')
check('A_573_unique_returned_588_planned',length(nr)==573 && !anyDuplicated(field(nr,'task_id')) && nrow(ng)==588)
check('A_all_returned_HTTP_success',all(field(nr,'status')=='ok'))
for(r in nr){
  q <- nqs[[r$question_id]]
  if(r$condition=='N0') expected <- nmessages(q) else {
    base <- ni[[ntask(r$question_id,r$provider,'N0')]]
    donor <- if(r$condition%in%c('N2','N3'))ni[[r$donor_task]] else NULL
    if(!is.null(donor))stopifnot(donor$provider!=r$provider,donor$condition=='N0',donor$question_id==r$question_id)
    expected <- nmessages(q,r$condition,base$text,if(is.null(donor))NULL else donor$text)
  }
  actual <- r$request$messages
  if(!is.null(r$request$system))actual<-c(list(list(role='system',content=r$request$system)),actual)
  stopifnot(identical(actual,expected))
  stopifnot(identical(nscore(r$text,q),ng$grade[match(r$task_id,ng$task_id)]))
}
check('A_all_raw_scores_match_saved',TRUE)
check('A_all_requests_match_question_own_baseline_and_other_model_donor',TRUE)
check('A_missing_not_coded_abstain',all(ng$grade[ng$response_status=='not_requested']=='not_scorable'))
# Independently evaluated mathematical references for all 13 retained items.
math_expected <- list('M-integer-1-trap'=answer('no_integer_solution'),
 'M-kiwi-1-control'=answer('numeric',36+47+2*36-7),'M-kiwi-1-trap'=answer('numeric',36+47+2*36),
 'M-kiwi-2-control'=answer('numeric',52+61+2*52-9),'M-kiwi-2-trap'=answer('numeric',52+61+2*52),
 'M-month-1-control'=answer('numeric',60+60/2),'M-month-2-control'=answer('numeric',72+72/2),
 'M-month-1-trap'=answer('insufficient_information'),'M-month-2-trap'=answer('insufficient_information'),
 'M-triangle-1-control'=answer('numeric',sqrt(3)/4*12^2),'M-triangle-2-control'=answer('numeric',sqrt(3)/4*14^2),
 'M-triangle-1-trap'=answer('inconsistent'),'M-triangle-2-trap'=answer('inconsistent'))
# Discriminant 29 is nonsquare; the requested April+June total lacks June data;
# a positive equilateral side cannot equal its height since sqrt(3)/2 != 1.
check('A_all_13_mathematical_references',all(vapply(names(math_expected),function(id)match_answer(math_expected[[id]],nqs[[id]]$gold,1e-10),TRUE)))
nc <- read.csv('Natural_Crosscheck/reports/cells.csv')
ncounts <- do.call(rbind,lapply(c('facts','mathematics'),function(d)do.call(rbind,lapply(NCOND,function(k){v<-nc[nc$domain==d & nc$complete,k];data.frame(module=paste0('A_',d),condition=k,n=length(v),correct=sum(v=='correct'),wrong=sum(v=='incorrect'),abstain=sum(v=='abstain'))}))))
counts <- rbind(old_counts,ncounts)
counts$error_pct <- 100*counts$wrong/counts$n
counts$correct_pct <- 100*counts$correct/counts$n
counts$abstain_pct <- 100*counts$abstain/counts$n
counts$answered_error_pct <- 100*counts$wrong/(counts$wrong+counts$correct)
write.csv(counts,file.path(out,'outcome_counts.csv'),row.names=FALSE)

# Recompute every A point estimate and sample size, independently of its bootstrap.
ae <- read.csv('Natural_Crosscheck/reports/effects.csv')
for(i in seq_len(nrow(ae))){
  e<-ae[i,]; cc<-strsplit(e$comparison,'-',fixed=TRUE)[[1]]
  z<-nc[nc$domain==e$domain & (e$provider=='pooled' | nc$provider==e$provider),]
  z<-z[z[[cc[1]]]%in%valid & z[[cc[2]]]%in%valid,]
  target<-switch(e$metric,error='incorrect',correct='correct',abstain='abstain')
  stopifnot(nrow(z)==e$n,abs(100*mean((z[[cc[1]]]==target)-(z[[cc[2]]]==target))-e$difference_pp)<1e-10)
}
check('A_all_effect_point_estimates_and_pair_denominators',TRUE)
be <- subset(read.csv('Peer_Misleading_Study/reports/interaction_posthoc/effects.csv'),variant=='primary' & provider=='pooled' & metric=='error')
for(i in seq_len(nrow(be))){e<-be[i,];cc<-strsplit(e$comparison,'_vs_',fixed=TRUE)[[1]];stopifnot(abs(100*mean((oc[[cc[1]]]=='incorrect')-(oc[[cc[2]]]=='incorrect'))-e$difference_pp)<1e-10)}
check('BC_all_five_primary_error_differences',TRUE)

# Are observed gains correct answers or withdrawals? Same denominator per pair.
pair_metrics <- function(z,a,b,module){z<-z[z[[a]]%in%valid & z[[b]]%in%valid,];data.frame(module=module,comparison=paste(a,b,sep='-'),n=nrow(z),wrong_before=sum(z[[b]]=='incorrect'),wrong_after=sum(z[[a]]=='incorrect'),correct_before=sum(z[[b]]=='correct'),correct_after=sum(z[[a]]=='correct'),abstain_before=sum(z[[b]]=='abstain'),abstain_after=sum(z[[a]]=='abstain'),wrong_to_correct=sum(z[[b]]=='incorrect'&z[[a]]=='correct'),wrong_to_abstain=sum(z[[b]]=='incorrect'&z[[a]]=='abstain'),correct_to_wrong=sum(z[[b]]=='correct'&z[[a]]=='incorrect'),abstain_to_wrong=sum(z[[b]]=='abstain'&z[[a]]=='incorrect'))}
pm <- rbind(pair_metrics(subset(nc,domain=='facts'),'N2','N1','A_facts'),pair_metrics(subset(nc,domain=='facts'),'N3','N2','A_facts'),pair_metrics(subset(nc,domain=='mathematics'),'N2','N1','A_math'),pair_metrics(oc,'C3','C2','BC'),pair_metrics(oc,'C5','C4','BC'))
write.csv(pm,file.path(out,'paired_changes.csv'),row.names=FALSE)

# Descriptive donor-state strata: not randomized truth assignments or causal effects.
ds <- read.csv('Natural_Crosscheck/reports/donor_states.csv')
z <- merge(nc,ds[,c('cell_id','donor_initial')],by='cell_id')
strata <- do.call(rbind,lapply(split(z,interaction(z$domain,z$donor_initial,drop=TRUE)),function(d){r<-pair_metrics(d,'N2','N1',d$domain[1]);r$donor_initial<-d$donor_initial[1];r}))
write.csv(strata,file.path(out,'descriptive_donor_strata.csv'),row.names=FALSE)

# Model identity as returned by API; no access to actual weights, and no API calls.
meta <- function(r,module){raw<-r$raw_response;if(is.character(raw))raw<-tryCatch(jsonlite::fromJSON(raw,simplifyVector=FALSE),error=function(e)list());data.frame(module=module,provider=r$provider,requested=r$request$model,returned=r$model_returned%||%raw$model%||%'unavailable',finish=r$finish_reason%||%'unavailable')}
metadata <- do.call(rbind,c(lapply(nr,meta,module='A'),lapply(a$records,meta,module='BC')))
metadata <- aggregate(rep(1L,nrow(metadata)),metadata,sum);names(metadata)[ncol(metadata)]<-'responses'
write.csv(metadata,file.path(out,'api_metadata_counts.csv'),row.names=FALSE)

# Recorded field/reason conflicts: supplementary unblinded review, not fresh labels.
ann <- read.csv('Natural_Crosscheck/reports/ai_review_annotations.csv')
ann_counts <- aggregate(list(n=ann$task_id),ann[c('domain','condition','finding')],length)
write.csv(ann_counts,file.path(out,'review_finding_counts.csv'),row.names=FALSE)
inputs <- c('Submission_Pack/report.Rmd','Natural_Crosscheck/protocol/freeze.json','Natural_Crosscheck/reports/effects.csv','Peer_Misleading_Study/reports/interaction_posthoc/effects.csv',file.path('Natural_Crosscheck/runs',MODELS,'responses.jsonl'),'Peer_Misleading_Study/runs/main_receivers/responses.jsonl')
write_json(list(scope='Raw record, request linkage, score and arithmetic audit; semantic/source truth not certified by these checks.',model_calls=0,checks=checks,checks_passed=length(checks),BC_branch_audit=branch,input_sha256=setNames(lapply(inputs,file_sha),inputs)),file.path(out,'checks.json'))
cat('Passed',length(checks),'audit checks. Original inputs/results unchanged.\n')
print(pm,row.names=FALSE)
print(metadata,row.names=FALSE)
