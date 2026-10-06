# Descriptive reclassification requested on 2026-10-06.
# Run from repository root. Existing records and frozen scoring stay unchanged.
# No model calls. All selection and arithmetic use R.
library(jsonlite)
library(digest)
task_out <- 'Crosscheck_Outcome_Analysis'
dir.create(task_out, recursive=TRUE, showWarnings=FALSE)
source_file <- 'All_Experiment_Data/question_comparison_pairs.csv'
p <- read.csv(source_file,stringsAsFactors=FALSE)
x <- subset(p,experiment %in% c('two_model_math','two_model_facts') &
  comparison_id=='initial_vs_natural_peer' & receiving_model=='minimax')
stopifnot(!anyDuplicated(x$receiver_pair_key),all(x$left_grade==x$receiver_initial_grade))
x$case_class <- ifelse(x$left_grade=='incorrect' & x$right_donor_grade=='correct',
  'initial_wrong__peer_correct',ifelse(x$left_grade=='correct' & x$right_donor_grade=='incorrect',
  'initial_correct__peer_wrong',ifelse(x$left_grade=='correct' & x$right_donor_grade=='correct',
  'both_correct',ifelse(x$left_grade=='incorrect' & x$right_donor_grade=='incorrect',
  'both_wrong','other_including_abstention'))))
write.csv(x,file.path(task_out,'minimax_matched_pairs.csv'),row.names=FALSE,na='')
cond_rows <- list(); overall_rows <- list()
rate <- function(num,den) if(den>0) num/den else NA_real_
for(task_domain in c('facts','math')){
 z <- subset(x,domain==task_domain)
 for(case_name in c('initial_wrong__peer_correct','initial_correct__peer_wrong','both_correct','both_wrong','other_including_abstention')){
  a <- subset(z,case_class==case_name)
  n <- nrow(a); cc <- sum(a$right_grade=='correct'); ww <- sum(a$right_grade=='incorrect'); aa <- sum(a$right_grade=='abstain')
  stopifnot(n==cc+ww+aa)
  cond_rows[[length(cond_rows)+1L]] <- data.frame(domain=task_domain,case_class=case_name,
   matched_cells=n,unique_questions=length(unique(a$question_id)),cross_correct=cc,cross_wrong=ww,cross_abstain=aa,
   cross_error_rate=rate(ww,n),cross_non_correct_rate=rate(ww+aa,n),
   error_correction_rate=if(case_name=='initial_wrong__peer_correct')rate(cc,n)else NA_real_,
   error_elimination_including_abstention_rate=if(case_name=='initial_wrong__peer_correct')rate(cc+aa,n)else NA_real_,
   correct_to_wrong_rate=if(case_name=='initial_correct__peer_wrong')rate(ww,n)else NA_real_)
 }
 q <- aggregate(cbind(left_wrong,right_wrong,left_abstain,right_abstain)~question_id,z,mean)
 v <- colMeans(q[,c('left_wrong','right_wrong','left_abstain','right_abstain')])
 iw <- sum(z$left_wrong); cw <- sum(z$right_wrong)
 gross_fixed <- sum(z$left_grade=='incorrect' & z$right_grade=='correct')
 wrong_to_abstain <- sum(z$left_grade=='incorrect' & z$right_grade=='abstain')
 introduced_wrong <- sum(z$left_grade!='incorrect' & z$right_grade=='incorrect')
 stopifnot(iw-cw==gross_fixed+wrong_to_abstain-introduced_wrong)
 overall_rows[[length(overall_rows)+1L]] <- data.frame(domain=task_domain,
  matched_cells=nrow(z),unique_questions=nrow(q),initial_wrong=iw,cross_wrong=cw,
  initial_abstain=sum(z$left_abstain),cross_abstain=sum(z$right_abstain),
  wrong_to_correct=gross_fixed,wrong_to_abstain=wrong_to_abstain,new_wrong_from_non_error=introduced_wrong,net_fewer_wrong=iw-cw,
  count_based_relative_error_reduction=rate(iw-cw,iw),
  count_based_error_reduction_pp=100*(iw-cw)/nrow(z),
  question_weighted_initial_error_rate=unname(v[1]),question_weighted_cross_error_rate=unname(v[2]),
  question_weighted_error_reduction_pp=100*unname(v[1]-v[2]),
  question_weighted_initial_non_correct_rate=unname(v[1]+v[3]),
  question_weighted_cross_non_correct_rate=unname(v[2]+v[4]))
}
cs <- do.call(rbind,cond_rows); os <- do.call(rbind,overall_rows)
write.csv(cs,file.path(task_out,'conditional_summary.csv'),row.names=FALSE,na='')
write.csv(os,file.path(task_out,'overall_summary.csv'),row.names=FALSE,na='')
math_fix <- subset(cs,domain=='math' & case_class=='initial_wrong__peer_correct')
math_all <- subset(os,domain=='math')
stopifnot(math_fix$matched_cells==18,math_fix$cross_correct==14,math_fix$cross_wrong==4,
 math_all$matched_cells==82,math_all$initial_wrong==20,math_all$cross_wrong==6,
 sum(subset(cs,case_class=='initial_correct__peer_wrong')$matched_cells)==0)
write_json(list(source=source_file,source_sha256=digest(file=source_file,algo='sha256'),
 analysis='Post-hoc descriptive MiniMax initial-vs-natural-cross comparison, completed-data semantic/recovery overlay.',
 conditional_denominator='Eligible question x MiniMax x repetition cells. Repetitions are not independent questions.',
 overall_weighting='Question-weighted rates average repeats within question. Count-based rates are separately labelled; the two coincide for the complete mathematics pairs.',
 missing_risk_evidence='No naturally incorrect DeepSeek donor following a correct MiniMax initial answer in this eligible set. Risk is unestimated, not zero.',
 synthetic_wrong_peer='Proposed controlled extension. No fabricated donor response is in these observed-data exports; no new model calls.',
 original_scoring_changed=FALSE),file.path(task_out,'audit.json'),pretty=TRUE,auto_unbox=TRUE)
print(cs[,c('domain','case_class','matched_cells','unique_questions','cross_correct','cross_wrong','cross_abstain')],row.names=FALSE)
print(os,row.names=FALSE)
