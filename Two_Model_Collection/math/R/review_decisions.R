# Codex post-collection decisions after reading the actual final fields/reasons.
# No changes to frozen strict scores or original responses; no paid review calls.
library(jsonlite)
root<-'Two_Model_Collection/math';out<-file.path(root,'reports')
d<-read.csv(file.path(out,'json_recovery_sensitivity.csv'),stringsAsFactors=FALSE)
k<-read.csv(file.path(out,'semantic_review_key.csv'),stringsAsFactors=FALSE)
diagnosis<-c(
 'CHAMP:P_Inequality_13'='Drops the -(a+b+c)=-9 term when evaluating the constrained minimum; the true minimum is -9.',
 'CHAMP:P_Combinatorics_21'='Confuses the order of the rotation group with the number of color orbits; 6!/24=30.',
 'CHAMP:P_Polynomial_11'='Misstates/calculates the residue cycle. The period is six, with two residues 4 per period, giving 20 indices.',
 'CHAMP:P_Sequence_19'='Claims period six for a sequence whose actual period is seven; a_1964=-1.',
 'CHAMP:P_Sequence_42'='Loses the moving starting position in Josephus elimination; 2*(1324-1024)+1=601.',
 'CHAMP:P_Inequality_8'='The proposed negative witness is an arithmetic error: 1+8-2*3=3, not -1. The expression is nonnegative and attains 0.',
 'CHAMP:P_Sequence_40'='Either omits the two complete rotations or applies an unrelated OEIS sequence; the exact count is 125.',
 'CHAMP:P_Number-Theory_24'='Modular arithmetic is incorrect; 2^32+1 is divisible by 641, remainder 0.',
 'CHAMP:P_Combinatorics_7'='Counts overlapping adjacent pairs and invents two swap directions; the Fibonacci count is 144.',
 'CHAMP:P_Polynomial_47'='Correct combinatorial expression is miscalculated: C(10,3)=120, not 40.',
 'CHAMP:P_Number-Theory_42'='The query matrix has full rank 50 over F2 and total parity requires all 50 rows; 25 queries do not suffice.',
 'CHAMP:P_Combinatorics_38'='Counts selected children but omits the 3! assignments of distinct toys: 40*6=240.'
)
wrong<-d[d$semantic_grade=='incorrect',]
stopifnot(nrow(wrong)==23L,all(wrong$question_id%in%names(diagnosis)))
review<-data.frame(id=wrong$id,semantic_label='incorrect',reason_quality='error',decision_reason=unname(diagnosis[wrong$question_id]),reviewer='Codex',scope='Read recovered final answer and complete JSON reason; checked against frozen argument.',stringsAsFactors=FALSE)
special<-data.frame(
 id=c('two_math:CHAMP:P_Polynomial_17:minimax:r2:neutral_initial','two_math:CHAMP:P_Polynomial_17:minimax:r1:neutral_initial','two_math:CHAMP:P_Number-Theory_42:minimax:r2:neutral_initial','two_math:CHAMP:P_Polynomial_17:minimax:r1:self_check'),
 semantic_label=c('incorrect','incorrect','incorrect','correct'),reason_quality=c('error','error','error','valid_final_reason'),
 decision_reason=c('n^2-1 is a definite wrong maximum. Continuity forces f(x)-x to keep one sign, so f(f(x)) cannot equal x; maximum is 0.',
 'n^2-n is a definite wrong maximum. The alleged real two-cycles contradict the no-fixed-point premise for a continuous function.',
 'Impossible is a definite mathematical claim, not abstention. Its alternating-sign witness does not give identical triple products; full-rank parity reasoning gives 50.',
 'The complete response explicitly retracts an earlier abstention after further search and ends with a second JSON answer 0 plus the correct continuity argument. The unique-object parser properly rejects this in strict/recovery scoring; final-assertion sensitivity uses the final explicitly adopted conclusion. Search text states it found CHAMP ground truth, so benchmark contamination risk is flagged.'),
 reviewer='Codex',scope='Read the complete model text and reference argument.',stringsAsFactors=FALSE)
review<-rbind(review,special)
sample<-k[k$grade=='correct',]
sample<-data.frame(id=sample$id,semantic_label='correct',reason_quality='no_clear_error_in_short_reason',decision_reason='Final answer matches reference; the sampled concise reason was read and checked.',reviewer='Codex',scope='Fixed predeclared sample of 40 strict-correct responses; concise reason review only.',review_id=sample$review_id,stringsAsFactors=FALSE)
issues<-list(
 MREV0040=c('error','Incorrect subset-count base cases a(1)=1,a(2)=2; actual counts are 2 and 3. Final Fibonacci value is nevertheless correct.'),
 MREV0082=c('error','Contains multiple incorrect numeric evaluations and infers a global lower bound from examples; final 0 alone is correct.'),
 MREV0087=c('proof_gap','Invokes symmetry and a vaguely named inequality without a complete general lower-bound argument. Correct final answer, proof completeness unestablished.'),
 MREV0093=c('error','Several modular cases and candidate residues are wrong, although the final check 76^2=5776 is valid.'),
 MREV0097=c('proof_gap','Only finitely many exponent pairs are searched; this does not establish a minimum over all positive exponents.'),
 MREV0098=c('error','Incorrectly turns an absolute difference congruent to plus/minus 1 modulo 4 into only 3 modulo 4, excluding possible signs without justification.'),
 MREV0127=c('error','The initial displayed Sophie Germain factorization uses an incorrect exponent; the later factorization is correct but does not repair the earlier false identity explicitly.'),
 MREV0133=c('error','Incorrectly states 12^m-1 is -1 modulo 11; it is 0. The claimed modular exclusion is not valid as written.'),
 MREV0136=c('proof_gap','One sign of the difference-one equation is left to an unexplained similar argument; final value correct, complete proof not supplied.'),
 MREV0167=c('minor_error','Describes nonidentity fifth roots as primitive and non-primitive; all nonidentity fifth roots are primitive because five is prime. The remainder argument is unaffected.'),
 MREV0197=c('error','Says x_101 is doubly exponentially small while also asserting its reciprocal is negligible; x_101 is large. Final floor remains correct.'),
 MREV0202=c('error','Claims period eight, but the actual period is seven. The final -1 happens to agree for the queried index.')
)
for(id in names(issues)){i<-match(id,sample$review_id);stopifnot(!is.na(i));sample$reason_quality[i]<-issues[[id]][1];sample$decision_reason[i]<-issues[[id]][2]}
sample$review_id<-NULL;review<-rbind(review,sample)
review$reviewed_at_utc<-format(Sys.time(),tz='UTC',usetz=TRUE)
write.csv(review,file.path(out,'codex_semantic_decisions.csv'),row.names=FALSE)
final<-d;final$final_semantic_grade<-final$semantic_grade
ix<-match(review$id,final$id);stopifnot(!anyNA(ix));final$final_semantic_grade[ix]<-review$semantic_label
write.csv(final,file.path(out,'semantic_final_responses.csv'),row.names=FALSE)
write_json(list(reviewed_responses=nrow(review),wrong_recovered_reviewed=23L,unresolved_complete_reviewed=4L,strict_correct_sample=40L,
 sample_reason_quality=as.list(table(sample$reason_quality)),final_semantic_counts=as.list(table(final$final_semantic_grade)),
 limitations='Codex review, not independent human verification. Full prose/reasoning of all 321 records was not independently checked. Technical/incomplete outputs remain unavailable. The correct-answer sample is not an unbiased estimate for all responses or models.'),file.path(out,'semantic_review_summary.json'),pretty=TRUE,auto_unbox=TRUE)
cat('Saved 67 Codex review decisions; strict scores preserved.\n')
