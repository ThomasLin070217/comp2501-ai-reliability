# Offline, post-hoc inspection of all reviewer flags and 24 fixed-seed valid controls.
# These explicit judgments are AI annotations, not human or formal verification.
source('Followup_Validation/R/common.R')
d<-file.path(VROOT,'review');p<-file.path(VROOT,'reports')
a<-read.csv(file.path(d,'annotations.csv'));controls<-read.csv(file.path(d,'valid_control_selection.csv'))
flag<-a[a$reasoning%in%c('incorrect','uncertain')|a$reference_problem%in%TRUE|a$answer_reason_consistent%in%FALSE,]
z<-rbind(flag,controls);stopifnot(nrow(z)==52,!anyDuplicated(z$task_id))
z$selection<-c(rep('all_reviewer_flags',nrow(flag)),rep('seeded_reviewer_valid_control',nrow(controls)))
z$codex_reasoning<-z$reasoning;z$codex_evidence<-NA_character_
note<-function(id,label,evidence){i<-match(paste0('CHAMP:',id),z$task_id);stopifnot(!is.na(i));z$codex_reasoning[i]<<-label;z$codex_evidence[i]<<-evidence}
note('P_Inequality_49:deepseek:r2:N2','incorrect','Claim that E=0 for all nonnegative variables fails at (1,1,3), where E=2. The reviewer counterexample (1,1,-1) was miscomputed: E=2, not 0.')
for(id in c('P_Sequence_40:kimi:r2:N1','P_Sequence_40:deepseek:r1:N1','P_Sequence_40:kimi:r1:N2','P_Sequence_40:deepseek:r2:N1','P_Sequence_40:kimi:r1:N1','P_Sequence_40:deepseek:r2:N2'))note(id,'incorrect','Counting only cyclic adjacent swaps omits the two whole-cycle rotations. The total is 125, not 123.')
note('P_Inequality_8:deepseek:r2:N1','incomplete','Convexity of the one-variable function and symmetry do not alone justify minimization with the varying product. The claimed conclusion needs a Jensen/AM-GM argument; no concrete false inequality is established here.')
note('P_Number-Theory_71:deepseek:r1:N1','incorrect','The response exhibits |12-5|=7 yet concludes the minimum is 19; absolute-value modular restrictions are also misused.')
note('P_Polynomial_11:minimax:r2:N1','incomplete','Period 12 is valid as a multiple of the fundamental period 6; residues 2,4,8,10 modulo 12 are correct. The displayed response stops without completing the count. Reviewer incorrectly rejects period 12.')
note('P_Inequality_15:kimi:r1:N1','valid','The sum-of-squares identity expands exactly to sum(a^4)-abc(a+b+c). At (1,2,3), both sides are 62; the reviewer arithmetic giving 60.5 is wrong.')
note('P_Inequality_8:kimi:r2:N1','valid','The final Jensen bound sum(x_i^(n+1)) >= S^(n+1)/n^n and AM-GM bound P*S <= S^(n+1)/n^n prove the result; equality holds when all variables equal. Earlier trial statement is explicitly withdrawn.')
note('P_Sequence_28:minimax:r2:N2','incorrect','The iteration matrix has eigenvalues 1 and 1/6, not 2/3 and 1/2. The reviewer calls it column-stochastic, but it is row-stochastic; that reviewer explanation is also erroneous.')
note('P_Number-Theory_13:minimax:r1:N1','incorrect','Saying 1 is too small does not rule it out; the modular treatment of the absolute difference is invalid and smaller candidates are not excluded.')
note('P_Inequality_49:deepseek:r1:N1','valid','Nonnegative cases and global sign reversal reduce the remaining case to z=-w; E>=2w>=0, with zero attained. The reviewer incorrectly treats this stronger bound as a gap. The harmless >0 notation includes an all-zero boundary handled by the same absolute-value equality.')
note('P_Inequality_49:deepseek:r2:N1','incorrect','All-same-sign E=0 fails at (1,1,3); the claimed mixed-sign minimum 2 fails by positive scaling. Reviewer counterexample (-1,-1,-1) was itself miscomputed: E=0.')
note('P_Polynomial_17:minimax:r2:N1','incorrect','A polynomial degree upper bound does not establish attainability. A continuous f with no fixed point lies strictly on one side of x everywhere, precluding a two-cycle.')
for(id in c('P_Combinatorics_7:minimax:r1:N1','P_Combinatorics_7:minimax:r1:N2'))note(id,'incorrect','Counting all n-1 adjacent swaps includes swaps that do not make the designated symbols adjacent; the case enumeration is invalid.')
note('P_Combinatorics_20:deepseek:r2:N1','incorrect','Two L-triominoes cannot fill a 2x2 square (area 6 versus 4). The resulting base case and recurrence are false.')
note('P_Number-Theory_42:deepseek:r1:N1','incorrect','An unobserved adjacent pair can contain different signs, so its two-sign flip need not change the total sum. The proposed indistinguishability proof fails.')
note('P_Polynomial_47:minimax:r2:N1','incorrect','The coefficient calculation drops the alternating sign from (1+x)^-2 and obtains -20 rather than 120.')
note('P_Polynomial_1:minimax:r2:N2','incorrect','The derivative argument for the final answer is sound, but the additional claimed quotient Q=n*sum(x^k) is false, already for n=2. The review rule counts explicit false subsidiary mathematical claims.')
note('P_Number-Theory_67:kimi:r2:N1','incorrect','2^((n-1)/2) is integral for every odd n, not just n=1 modulo 4. The claim that all n=3 modulo 4 give divisibility by 5 also fails, e.g. n=15.')
note('P_Number-Theory_27:minimax:r1:N1','incorrect','The CRT solution for 10^990 modulo 1982 is 992, not 991 (which is odd). This produces the wrong remainder 220; digitwise modular evaluation gives 0.')
note('P_Sequence_21:minimax:r1:N1','incorrect','Substituting m=n on the left gives a_(2n)+a_0, not 2*a_(2n); the derived recurrence is false.')
note('P_Number-Theory_27:kimi:r1:N2','incorrect','The response adopts the donor wrong CRT residue 991 instead of 992 and changes the answer to 220. Its further claim that division by 9 requires divisibility by 991^2 is false.')
note('P_Polynomial_47:deepseek:r1:N1','incorrect','An alternating-sign error in the expansion leads to -120 instead of the coefficient 120.')
# Individually inspected controls, not blanket acceptance of uninspected reviewer-valid outputs.
ev<-c('Sound Fermat argument modulo 991 plus parity gives remainder zero.',
 'Correct sum-of-squares identity and equality at a=b=c=3.',
 'Correct gradient and positive-definite Hessian establish the global minimum.',
 'Complete digit/factor case enumeration finds a=7,b=4.',
 'Correct decomposition into singletons and neighboring swaps gives Fibonacci count 89.',
 'Core no-two-cycle argument is sound, but the added claim that odd degree never permits no fixed point fails for degree 1: f(x)=x+1.',
 'The monotonic reduction and elementary reciprocal bound prove the nonpositive upper bound, attained at zero.',
 'Correct order-two recurrence, period 6 and count 20.',
 'Correct evaluation at the six nontrivial seventh roots and degree bound prove remainder 7.',
 'Correct constraint bound ab+bc+ac<=27 and attainable minimum -9.',
 'The claimed common numerator -2AB is false; it equals -AB(A+B+2). At A=B=1 these are -2 and -4. Final maximum 0 is still correct.',
 'Correct seven-term periodic sequence and reduction of index 1964 modulo 7.',
 'Valid x^5=1 modulo f(x) reduces all five terms to 1.',
 'For fixed sum, the convex reciprocal sum attains its maximum at an endpoint; this correctly proves the bound 0.',
 'The mistaken intermediate modular manipulation is explicitly corrected; the final invertible cancellation gives 2^32=-1 modulo 641.',
 'Correct eigenvalues 1 and 1/6 and eigenspace decomposition prove equal limits.',
 'Both the independent-set recurrence and binomial sum give 144 correctly.',
 'Correct stars-and-bars enumeration C(2001,2)=2001000.',
 'The crucial exclusion of difference 1 is asserted through small checks without proof; modular restrictions stated do not finish that case. No explicit false claim is identified; essential justification is missing.',
 'Correct stars-and-bars enumeration C(2001,2)=2001000.',
 'Correct squared-difference identity with attainable equality.',
 'Correct positive-definite quadratic and stationary point a=b=1.',
 'Correct roots-of-unity and modular arguments both give remainder 7.',
 'Correct modulo-5 recurrence and two residues in each of ten periods.')
stopifnot(length(ev)==nrow(controls))
for(i in seq_len(nrow(controls)))note(sub('^CHAMP:','',controls$task_id[i]),if(i%in%c(6,11))'incorrect'else if(i==19)'incomplete'else'valid',ev[i])
stopifnot(!anyNA(z$codex_evidence));z$label_changed<-z$codex_reasoning!=z$reasoning
write.csv(z,file.path(d,'codex_reasoning_annotations.csv'),row.names=FALSE)
# Exact integer arithmetic checks on the identified reviewer disagreements. Finite grids
# corroborate the algebraic identities described above; they are not general proofs.
grid<-expand.grid(a=-4:4,b=-4:4,c=-4:4)
with(grid,stopifnot(all(a^4+b^4+c^4-a*b*c*(a+b+c)==((a^2-b^2)^2+(b^2-c^2)^2+(c^2-a^2)^2+a^2*(b-c)^2+b^2*(c-a)^2+c^2*(a-b)^2)/2)))
ab<-expand.grid(A=0:12,B=0:12)
with(ab,stopifnot(all((A+B)*(1+A)*(1+B)-A*(1+A+B)*(1+B)-B*(1+A+B)*(1+A)==-A*B*(A+B+2))))
seqmod<-c(2,1);for(i in 3:122)seqmod[i]<-(seqmod[i-1]-seqmod[i-2])%%5
stopifnot(all(seqmod[1:110]==seqmod[13:122]))
stopifnot(all(abs(sort(eigen(matrix(c(1/2,1/2,1/3,2/3),2,byrow=TRUE))$values)-c(1/6,1))<1e-12))
xx<--20:20;stopifnot(all((xx+1)-xx==1),all(((xx+1)+1)-xx==2))
write_json(list(checks_passed=5,label_changes=sum(z$label_changed),reviewed=nrow(z),all_flags=nrow(flag),seeded_valid_controls=nrow(controls),scope='Unmasked targeted AI audit plus seeded control sample; not complete independent verification.'),file.path(d,'codex_reasoning_validation.json'))
# Matched analysis of displayed reasoning, independent of final-field parseability.
# Unreviewed Kimi labels stay unchanged in the partial-audit sensitivity; not ground truth.
ans<-list();pairs<-list()
for(version in c('original_kimi','partial_codex_audit')){
 b<-a;b$label<-b$reasoning
 if(version=='partial_codex_audit'){ix<-match(z$task_id,b$task_id);b$label[ix]<-z$codex_reasoning}
 x<-b[b$condition=='N1',c('cell_id','question_id','label')];y<-b[b$condition=='N2',c('cell_id','label')]
 q<-merge(x,y,by='cell_id',suffixes=c('_N1','_N2'));q<-q[!is.na(q$label_N1)&!is.na(q$label_N2),]
 pairs[[version]]<-cbind(version=version,q)
 for(target in c('incorrect','incomplete','valid','uncertain')){
  delta<-(q$label_N2==target)-(q$label_N1==target);ids<-unique(q$question_id)
  sums<-vapply(ids,function(id)sum(delta[q$question_id==id]),0);sizes<-vapply(ids,function(id)sum(q$question_id==id),0)
  set.seed(25011010);boot<-replicate(5000,{ix<-sample(seq_along(ids),length(ids),replace=TRUE);100*sum(sums[ix])/sum(sizes[ix])});ci<-quantile(boot,c(.025,.975),names=FALSE)
  ans[[length(ans)+1]]<-data.frame(version=version,label=target,pairs=nrow(q),questions=length(ids),N1=sum(q$label_N1==target),N2=sum(q$label_N2==target),difference_pp=100*mean(delta),ci_low=ci[1],ci_high=ci[2])
 }
}
res<-do.call(rbind,ans);write.csv(res,file.path(p,'reasoning_paired_sensitivity.csv'),row.names=FALSE)
write.csv(do.call(rbind,pairs),file.path(p,'reasoning_pairs.csv'),row.names=FALSE)
tablemd<-function(x)paste(capture.output(print(knitr::kable(x,format='pipe',row.names=FALSE))),collapse='\n')
writeLines(c('# Audit of the mathematical reasoning reviewer','',
 'Kimi supplied labels for 432 complete mathematical N1/N2 responses. Codex read all 28 flagged outputs and 24 fixed-seed reviewer-valid controls (52 distinct outputs). This audit was unmasked, targeted and conducted after outcomes. It does not establish error-free labels for the remaining 380 outputs. Explicitly withdrawn exploratory errors do not invalidate the final solution; an unwithdrawn false subsidiary mathematical claim does, under the stated reviewer rule.','',
 sprintf('Codex disagrees with %d labels: %d among the 28 flags and %d among the 24 valid controls. The original Kimi annotations and raw responses are retained; separate Codex evidence is in `codex_reasoning_annotations.csv`.',sum(z$label_changed),sum(z$label_changed&z$selection=='all_reviewer_flags'),sum(z$label_changed&z$selection=='seeded_reviewer_valid_control')),'',
 'Examples: the reviewer miscalculates a correct sum-of-squares identity; it treats a valid nonminimal period 12 as wrong; it misses an incorrect common-denominator numerator and an unjustified exclusion of a Diophantine candidate. Five R checks corroborate identities, a recurrence period, eigenvalues and a degree-one counterexample. These checks are not a formal proof of all mathematical annotations.','',
 '## Matched, exploratory comparison','',tablemd(res),'',
 'Only pairs with both complete reviewed responses enter this table; field-unscorable but complete mathematical text may enter. Therefore its denominator differs from final-answer analysis. Raw condition totals (N1=224, N2=208) must not be compared as if they were matched. Question-cluster bootstrap uses 5,000 draws, seed 25011010; intervals are exploratory and ignore annotation uncertainty.','',
 'The partial-audit sensitivity changes only the 52 inspected labels, preserving the remaining original labels. Finding false negatives among the controls means these revised counts cannot be presented as verified population reasoning-error rates. Keep the primary final-answer endpoint separate, and use individually checked repair/failure examples as illustrative evidence.','',
 'This review supports the existence of genuine mathematical mistakes and of both successful corrections and peer-induced failures. It does not justify an unqualified claim that cross-model checking improves logical rigor across all problems.'),file.path(d,'codex_review_notes.md'))
print(res);cat('Audited',nrow(z),'responses;',sum(z$label_changed),'label disagreements.\n')
