source('Math_Supplement/R/common.R')
qs<-read_jsonl('Math_Supplement/protocol/questions.jsonl')
stopifnot(length(qs)==24,sum(field(qs,'split')=='development')==8)
for(q in qs){
 stopifnot(math_grade(mjson(q$gold),q)=='correct',math_grade(mjson(q$wrong),q)=='incorrect',math_grade(mjson(answer('uncertain')),q)=='abstain',math_grade('{"conclusion":"numeric"',q)=='unscorable')
 for(p in MODELS)stopifnot(generator(p,q)!=p)
 m<-list(answer=q$wrong,reason='Example material fixture')
 b<-mjson(q$gold)
 a2<-receiver_messages(q,'C2',b,m);a3<-receiver_messages(q,'C3',b,m)
 stopifnot(identical(a2[1:3],a3[1:3]),grepl(m$reason,a2[[4]]$content,fixed=TRUE),grepl(m$reason,a3[[4]]$content,fixed=TRUE))
 stopifnot(length(receiver_messages(q,'baseline'))==2,length(a2)==4)
}
stopifnot(valid_answer(answer('numeric',0)),!valid_answer(answer('numeric')),
 valid_answer(answer('integer_solutions',solutions=c(2.0,-3))),!valid_answer(answer('integer_solutions',solutions=c(2.1))),
 !valid_answer(answer('integer_solutions',solutions=c(2,2))),!valid_answer(answer('numeric','42')),
 !valid_answer(answer('insufficient information')),
 math_grade(paste0('```json\n',mjson(qs[[1]]$gold),'\n```'),qs[[1]])=='correct')
write_json(list(status='passed',question_gold_and_foil_checks=24,branch_and_donor_checks=72,schema_edge_checks=8,R=as.character(getRversion())), 'Math_Supplement/protocol/offline-tests.json')
cat('Offline fixtures passed for gold, foils, logical nonanswers, branching and schema boundaries.\n')
