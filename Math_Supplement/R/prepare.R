source('Math_Supplement/R/common.R')
qs<-list()
add<-function(family,version,kind,question,gold,wrong,proof,tolerance=1e-8){
 id<-sprintf('M-%s-%d-%s',family,version,kind)
 qs[[length(qs)+1]]<<-list(question_id=id,family=family,version=version,kind=kind,
 split=if(version==0)'development' else 'supplementary',question=question,gold=gold,wrong=wrong,proof=proof,tolerance=tolerance,
 source=if(family=='kiwi')'GSM-Symbolic Figure 7 (adapted)' else 'MathTrap Table 1 / Table 13 (adapted)')
}
for(v in 0:2){
 s<-c(10,12,14)[v+1];p<-3*s;area<-s*s*sqrt(3)/4
 add('triangle',v,'trap',sprintf('An equilateral triangle has perimeter %d cm and height %d cm. What is its area? If these conditions cannot hold simultaneously, say so.',p,s),answer('inconsistent'),answer('numeric',s*s/2),sprintf('All sides are %d, so height is %d*sqrt(3)/2, not %d.',s,s,s))
 add('triangle',v,'control',sprintf('An equilateral triangle has perimeter %d cm and height %d*sqrt(3)/2 cm. What is its area? If these conditions cannot hold simultaneously, say so.',p,s),answer('numeric',area),answer('numeric',s*s/2),sprintf('The conditions agree: area = %d^2*sqrt(3)/4.',s),max(.01,area*.001))
 a<-c(44,36,52)[v+1];b<-c(58,47,61)[v+1];k<-c(5,7,9)[v+1];total<-3*a+b
 base<-sprintf('Oliver picks %d kiwis on Friday and %d on Saturday. On Sunday he picks twice as many as on Friday.',a,b)
 add('kiwi',v,'trap',paste(base,sprintf('Of the kiwis picked on Sunday, %d are smaller than average. How many kiwis did he pick over all three days?',k)),answer('numeric',total),answer('numeric',total-k),'Size does not remove a kiwi from the count. Total = Friday + Saturday + 2*Friday.')
 add('kiwi',v,'control',paste(base,sprintf('He then throws away %d of the kiwis picked on Sunday. How many of the kiwis picked over all three days does he keep?',k)),answer('numeric',total-k),answer('numeric',total),'The question asks how many he keeps, so subtract exactly the discarded kiwis.')
 # x(x+1) is even for integer x. All odd right-hand sides below are impossible.
 n<-c(1,2,3)[v+1];rhs<-n*(n+1)
 add('integer',v,'trap',sprintf('Find all integer solutions of x^2 + x = %d.',rhs+1),answer('no_integer_solution'),answer('integer_solutions',solutions=c(n,-n-1)),sprintf('x(x+1) is even for every integer x, whereas %d is odd.',rhs+1))
 add('integer',v,'control',sprintf('Find all integer solutions of x^2 + x = %d.',rhs),answer('integer_solutions',solutions=c(n,-n-1)),answer('no_integer_solution'),sprintf('(x-%d)(x+%d)=0, hence x=%d or x=%d.',n,n+1,n,-n-1))
 hair<-c(48,60,72)[v+1]
 base<-sprintf('Natalia sold %d hair clips in April. She sold half as many in May.',hair)
 add('month',v,'trap',paste(base,'How many did she sell in total in April and June?'),answer('insufficient_information'),answer('numeric',hair*1.5),'June sales are not specified; May sales do not determine June sales.')
 add('month',v,'control',paste(base,'How many did she sell in total in April and May?'),answer('numeric',hair*1.5),answer('insufficient_information'),'Both April and May sales are specified; sum April and half of April.')
}
stopifnot(length(qs)==24,length(unique(field(qs,'question_id')))==24)
for(q in qs){stopifnot(valid_answer(q$gold),valid_answer(q$wrong),!match_answer(q$gold,q$wrong,q$tolerance));stopifnot(math_grade(mjson(c(q$gold,list(reason=q$proof))),q)=='correct')}
write_jsonl(qs,'Math_Supplement/protocol/questions.jsonl')
write_json(list(schema=MSCHEMA,neutral=MNEUTRAL,structured=MSTRUCT),'Math_Supplement/protocol/prompts.json')
write_json(read_json('Peer_Misleading_Study/protocol/models.json'),'Math_Supplement/protocol/models.json')
writeLines(c('# Selected mathematics examples', '', 'Four families, three numerical versions, trap/control pairs. Version 0 is development; versions 1 and 2 are supplementary. Gold conclusions include proof sketches. All are adaptations.', '',unlist(lapply(qs,function(q)c(paste0('## ',q$question_id),q$question,paste('Gold:',mjson(q$gold)),paste('Proof:',q$proof),'')))),'Math_Supplement/QUESTIONS.md')
cat('24 problems generated and gold/foil separation checked.\n')
