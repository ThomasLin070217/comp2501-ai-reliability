# Codex decisions after reading the fixed recovery queue. Post-collection only.
source('Two_Model_Collection/R/runtime.R')
main<-'Two_Model_Collection/math';root<-file.path(main,'recovery/derived');out<-file.path(root,'reports')
d<-read.csv(file.path(out,'json_recovery_sensitivity.csv'),stringsAsFactors=FALSE)
p<-read.csv(file.path(root,'provenance.csv'),stringsAsFactors=FALSE)
queue<-read.csv(file.path(out,'recovery_review_queue.csv'),stringsAsFactors=FALSE)
stopifnot(nrow(queue)==58L,sum(queue$review_selection=='all_new_complete_noncorrect_or_unresolved')==18L)
old<-read.csv(file.path(main,'reports/codex_semantic_decisions.csv'),stringsAsFactors=FALSE)
# Carry an old semantic decision only when the exact original observation remains selected.
old<-old[old$id%in%p$id[p$source=='original'],]
old$observation_source<-'original';old$selected_recovery_attempt<-NA_integer_;old$http_id<-p$http_id[match(old$id,p$id)]
new<-list();id<-function(q,p,r,c)paste0('two_math:CHAMP:P_',q,':',p,':r',r,':',c)
issues<-list()
issues[[id('Sequence_19','minimax',2,'A0_AI')]]<-c('error','Claims period 8 although its listed recurrence values have period 7; -1 happens to be the correct requested term.')
issues[[id('Number-Theory_27','minimax',1,'misconception_initial')]]<-c('error','Applies Euler theorem to base 10 modulo even 1982 despite gcd not equal to 1, and falsely claims the even power is congruent to 1 modulo 1982. Correct argument uses modulo 991, then evenness.')
issues[[id('Sequence_28','minimax',1,'A1_AI')]]<-c('error','Names (1,-1) as the decaying eigendirection, but A(1,-1)=(0,-1/3), not (1,-1)/6. Correct eigendirection is (-3,2); final limit difference 0 is correct.')
issues[[id('Inequality_24','minimax',1,'misconception_initial')]]<-c('minor_error','First expanded line duplicates the -a^2 b^3 term, but the next line and exact final factorization are correct.')
issues[[id('Sequence_21','minimax',1,'A0_AI')]]<-c('proof_gap','Verifies a_n=n^2 is a solution but does not establish uniqueness from a_1=1. The missing recurrence induction is supplied in the researcher reference; final 2500 is correct.')
for(i in seq_len(nrow(queue))){
 z<-queue[i,];label<-z$semantic_grade;quality<-'no_clear_error_in_short_reason';why<-'Read the final answer and concise reason against the independently checked researcher reference.'
 if(z$review_selection=='all_new_complete_noncorrect_or_unresolved'){
  label<-'incorrect';quality<-'error';q<-sub('CHAMP:P_','',z$question_id)
  why<-switch(q,
   Sequence_40=if(z$recovered_answer=='123')'Omits the two full circular shifts; 123 cycle matchings plus 2 shifts gives 125.'else if(z$recovered_answer=='165')'Incorrectly treats shifted remaining positions and values as an ordinary band problem. Exactly one wrap corner forces the full shift, so the correct count is 89+2+34=125.'else'Claims an unsupported numerical count. Cycle matchings plus the two full shifts give 125; the proposed count is false.',
   Sequence_21='At m=n the left side is a_(2m)+a_0, not 2a_(2m). The false substitution contradicts a_1=1; correct a_50=2500.',
   Combinatorics_20='The state recurrence/base counts do not enumerate the legal tilings. T_0=1,T_1=1,T_2=5 with T_n=T_(n-1)+4T_(n-2)+2T_(n-3) gives 87.',
   Polynomial_11=if(z$recovered_answer=='24')'Labels a six-term residue cycle period five, producing 24 instead of 20.'else'Incorrect modular recurrence values and period 10 produce 15; the actual six-term cycle gives 20.',
   Combinatorics_21='Confuses the 24 cube rotations with inequivalent colourings. Six distinct colours give 6!/24=30 colourings.',
   `Number-Theory_42`=if(z$recovered_answer=='impossible')'Impossible is a definite mathematical assertion, not abstention. Alternating signs yield triples with both one and two negative entries; the indistinguishable witness is false. All 50 queries determine the product.'else'False claim that linear combinations over a field are never unique. The invertible cyclic triple matrix forces all 50 queries; proposed 25-query construction is not valid.',
   Sequence_42='The survivor recurrence is incorrectly applied. J(1324)=2(1324-1024)+1=601, not 1057.',
   Sequence_19='Claims period 6 despite the stated recurrence giving period 7; 1964 mod 7=4 gives -1.',
   stop('Unreviewed exception: ',z$id))
 }
 if(z$id%in%names(issues)){quality<-issues[[z$id]][1];why<-issues[[z$id]][2]}
 new[[i]]<-data.frame(id=z$id,semantic_label=label,reason_quality=quality,decision_reason=why,reviewer='Codex',scope=z$review_selection,reviewed_at_utc=tm_now(),observation_source='technical_recovery_appendix',selected_recovery_attempt=z$selected_recovery_attempt,http_id=z$http_id,stringsAsFactors=FALSE)
}
new<-do.call(rbind,new);all<-rbind(old,new);stopifnot(!anyDuplicated(all$id))
d$final_semantic_grade<-d$semantic_grade;ix<-match(all$id,d$id);stopifnot(!anyNA(ix));d$final_semantic_grade[ix]<-all$semantic_label
write.csv(new,file.path(out,'recovery_semantic_decisions.csv'),row.names=FALSE)
write.csv(all,file.path(out,'codex_semantic_decisions.csv'),row.names=FALSE)
write.csv(d,file.path(out,'semantic_final_responses.csv'),row.names=FALSE)
tm_write(list(selected_records=nrow(d),old_observation_reviews_retained=nrow(old),new_distinct_observations_reviewed=nrow(new),new_wrong_or_unresolved_reviewed=18L,new_correct_sample=40L,
 new_correct_sample_quality=as.list(table(new$reason_quality[new$scope=='fixed_seed_new_correct_sample'])),semantic_counts=as.list(table(d$final_semantic_grade)),
 scope='All newly selected complete noncorrect or unresolved final answers, plus a seed-25011005 sample of 40 newly selected correct answers, were read by Codex. Original retained observations carry 115 prior decisions. No claim of independent human review or full reasoning validation of every response. Correct final answers with flawed reasons retain the correct final-answer label and receive a separate reasoning flag.'),file.path(out,'semantic_review_summary.json'))
cat('Supplemented semantic decisions:',nrow(all),'observations;',nrow(new),'new recovery observations.\n')
