# Codex annotations after reading every incorrect mathematical N0 response.
# Separate from field scoring; no labels or original text are overwritten.
source('Followup_Validation/R/common.R')
p<-file.path(VROOT,'baseline_review');g<-read.csv(file.path(p,'responses.csv'));z<-g[g$grade=='incorrect',]
notes<-list(
 'P_Polynomial_47'=c('algebraic_sign','Expansion of (y-1)^k must retain (-1)^(k-2). DeepSeek reverses the numerator sign; MiniMax drops that factor. Both differ from a correct derivation followed only by a wrong answer field.'),
 'P_Sequence_40'=c('omitted_cases','Disjoint adjacent swaps do not exhaust circular permutations: the two full-cycle one-step rotations are also allowed. 123 matchings plus two rotations gives 125.'),
 'P_Number-Theory_71'=c('false_arithmetic_and_inconsistent_minimum','The response lists |12-5|=7 but concludes the minimum is 19, and treats 7 as a power of 5 in its small-case list. It also mishandles the sign of the absolute difference in modular exclusions.'),
 'P_Combinatorics_20'=c('invalid_counting_recurrence','DeepSeek claims two triominoes fill four cells. Kimi proposes an unsupported recurrence giving A_2=4, but a 2x2 board has five tilings (all singles or one L in four orientations).'),
 'P_Number-Theory_42'=c('invalid_identifiability_argument','Two unseen signs can have product +1 or -1; (+1,-1) and (-1,+1) were omitted. Flipping two signs preserves rather than changes the total product. GF(2) rank proves all 50 triple products are required.'),
 'P_Number-Theory_27'=c('false_modular_CRT','991 is odd and 0 modulo 991, so it satisfies neither the stated 0 modulo 2 nor 1 modulo 991 constraints. The CRT residue is 992; the original number is 0 modulo 1982.'),
 'P_Inequality_49'=c('contradictory_bound_and_false_claims','The output exhibits value 0 but announces a minimum of 4. Its sign resolution and assertion that intermediate values cannot occur are false. This is internally inconsistent reasoning, not a fully correct solution with a mistyped final field.'),
 'P_Sequence_42'=c('indexing_convention','2L+1 is already the one-based Josephus survivor; adding another 1 produces 602 instead of 601. Its small-case checks contradict that extra conversion.'),
 'P_Combinatorics_7'=c('ignored_adjacency_constraint','The child in the last seat can swap only with the adjacent child, not any of n-1 children. The recurrence is A_n=A_(n-1)+A_(n-2), yielding 144.'),
 'P_Combinatorics_31'=c('distinguishable_vs_identical','8^3 counts labeled cookies. The question says identical cookies, so nonnegative solutions to x_1+...+x_8=3 give choose(10,3)=120.'),
 'P_Sequence_21'=c('incorrect_substitution','For m=n the left side is a_(2n)+a_0, not 2*a_(2n). The false substitution creates the claimed zero even terms.')
)
ids<-sub('^CHAMP:','',z$question_id);stopifnot(all(ids%in%names(notes)),nrow(z)==16)
a<-data.frame(task_id=z$task_id,reasoning='incorrect',field_only_artifact=FALSE,error_type=vapply(ids,function(id)notes[[id]][1],''),evidence=vapply(ids,function(id)notes[[id]][2],''),reviewer='Codex AI; unmasked targeted review')
write.csv(a,file.path(p,'codex_annotations.csv'),row.names=FALSE)
permanent<-function(allowed){n<-nrow(allowed);dp<-numeric(2^n);dp[1]<-1;for(mask in 0:(2^n-2)){i<-sum(as.integer(intToBits(mask))[seq_len(n)])+1;if(!dp[mask+1]||i>n)next;for(j in which(allowed[i,]))if(!bitwAnd(mask,bitwShiftL(1L,j-1)))dp[bitwOr(mask,bitwShiftL(1L,j-1))+1]<-dp[bitwOr(mask,bitwShiftL(1L,j-1))+1]+dp[mask+1]};dp[2^n]}
gf2rank<-function(a){nr<-nrow(a);nc<-ncol(a);rank<-0L;for(j in seq_len(nc)){ix<-which(a[,j]==1&seq_len(nr)>rank);if(!length(ix))next;rank<-rank+1L;k<-ix[1];tmp<-a[rank,];a[rank,]<-a[k,];a[k,]<-tmp;for(i in which(a[,j]==1&seq_len(nr)!=rank))a[i,]<-(a[i,]+a[rank,])%%2};rank}
d<-abs(outer(1:10,1:10,'-'));circ<-permanent(pmin(d,10-d)<=1)
line<-permanent(abs(outer(1:11,1:11,'-'))<=1)
A<-matrix(0,50,50);for(i in 1:50)A[i,((i-1+0:2)%%50)+1]<-1
r<-0;for(i in 1:1980)r<-(10*r+2)%%1982
j<-0;for(n in 2:1324)j<-(j+2)%%n
checks<-list(circular_permutations=circ==125,line_permutations=line==144,circular_triple_products_full_rank=gf2rank(A)==50&&all(colSums(A)%%2==1),repeated_twos_mod=r==0,Josephus_one_based=j+1==601,polynomial_coefficient=sum(choose(2:9,2))==120,identical_cookies=choose(10,3)==120)
stopifnot(all(unlist(checks)));write_json(list(time=now(),checks=checks,model_calls=0,scope='Independent exact R arithmetic/enumeration for selected displayed mistakes; not a formal verification of all reference proofs.'),file.path(p,'exact_checks.json'))
writeLines(c('# Mathematical baseline reasoning inspection','',
 'All 16 automatically incorrect, scorable N0 mathematical responses were read by Codex while the already-frozen branches continued. All 16 contain a substantive mathematical false step or logical inconsistency. None is classified as a completely correct displayed solution followed only by an incorrect answer field. This is a targeted AI inspection, not blind human annotation, and it does not validate all correct-number responses or unscorable outputs.', '',
 'The corresponding raw outputs are in responses.csv and wrong_packet_*.md. Annotations are in codex_annotations.csv. Seven independent R arithmetic/enumeration checks are in exact_checks.json. Selection and collection were not changed in response to these results.', '',
 'The 16 responses come from 11 questions, with repeated mistakes sharing the same mathematical structure. They are not 16 independent mathematical weaknesses. This initial-answer audit does not establish that cross-checking fixes them; that requires the later paired N1/N2 results.'),file.path(p,'README.md'))
cat('Annotated 16 wrong baseline responses; seven exact R checks passed.\n')
