source('Natural_Crosscheck/R/common.R')
qs<-read_jsonl(file.path(NROOT,'protocol/questions.jsonl'));f<-Filter(function(q)q$domain=='facts',qs)[[1]];m<-Filter(function(q)q$domain=='mathematics',qs)[[1]]
goodf<-mjson(list(answer=f$gold,abstain=FALSE,reason='Known date.'))
unknown<-mjson(list(answer='',abstain=TRUE,reason='I cannot confirm.'))
stopifnot(nvalid(goodf,f),nscore(goodf,f)=='correct',nscore(unknown,f)=='abstain')
bad<-mjson(list(answer=f$gold,abstain=TRUE,reason='Conflict.'));stopifnot(!nvalid(bad,f),!nvalid('{',f))
goodm<-mjson(c(m$gold,list(reason='Proof uses {braces} and a quoted \\"term\\".')))
stopifnot(nvalid(goodm,m),nscore(goodm,m)=='correct',nscore(paste('```json',goodm,'```',sep='\n'),m)=='correct')
for(q in list(f,m)){
 a<-if(q$domain=='facts')goodf else goodm
 for(c in NCOND){msgs<-nmessages(q,c,a,a);stopifnot(length(msgs)==if(c=='N0')2 else 4,identical(msgs[[2]]$content,q$question))}
 n2<-nmessages(q,'N2',a,a);n3<-nmessages(q,'N3',a,a)
 stopifnot(identical(n2[1:3],n3[1:3]),grepl(donor_text(a,q),n2[[4]]$content,fixed=TRUE),grepl(donor_text(a,q),n3[[4]]$content,fixed=TRUE))
 aobj<-nparse(a);aobj$gold<-'SECRET_REFERENCE';aobj$grade<-'correct';stopifnot(!grepl('SECRET_REFERENCE',donor_text(mjson(aobj),q),fixed=TRUE))
}
u<-read.csv(file.path(NROOT,'protocol/units.csv'));stopifnot(nrow(u)==147,all(u$provider!=u$donor),all(table(u$provider)==49),all(table(u$domain)==c(facts=108,mathematics=39)))
o<-jsonlite::fromJSON(file.path(NROOT,'protocol/orders.json'));for(p in MODELS)stopifnot(nrow(o[[p]])==196,!anyDuplicated(paste(o[[p]]$question_id,o[[p]]$condition)),all(table(o[[p]]$condition)==49))
# Each donor corresponds to another model's independent N0 on the same question.
stopifnot(all(paste(u$question_id,u$donor)%in%paste(u$question_id,u$provider)))
write_json(list(status='pass',time=now(),checks=c('both_domain_grading','explicit_abstention','conflict_rejection','string_aware_brace_extraction','parallel_branch_context','matched_peer_material','reference_field_allowlist','147_units_588_outputs','different_model_donors')),file.path(NROOT,'protocol/offline-tests.json'))
cat('Natural cross-check offline checks passed.\n')
