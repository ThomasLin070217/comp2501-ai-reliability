source('Followup_Validation/R/common.R')
checks<-list();check<-function(k,x){stopifnot(isTRUE(x));checks[[k]]<<-TRUE}
qs<-read_jsonl(file.path(VROOT,'protocol/questions.jsonl'));f<-Filter(function(q)q$domain=='facts',qs)[[1]];m<-Filter(function(q)q$domain=='mathematics',qs)[[1]]
good<-function(a)vjson(list(reason='A short justification with {braces}.',abstain=FALSE,answer=a))
gf<-good(f$gold);gm<-good(m$gold);unknown<-vjson(list(reason='I cannot determine it.',abstain=TRUE,answer=''))
check('gold_scores_and_explicit_abstention',vscore(gf,f)=='correct'&&vscore(gm,m)=='correct'&&vscore(unknown,m)=='abstain')
check('format_extraction_after_latex',vscore(paste('\\frac{1}{2} and \\sqrt{3}',gm),m)=='correct')
check('conflicting_objects_not_silently_selected',is.null(vparse(paste(gm,good('999999')))))
check('identical_duplicate_objects_allowed',vscore(paste(gm,gm),m)=='correct')
check('nonempty_answer_abstain_conflict',!vvalid(list(reason='Unsure',abstain=TRUE,answer='1975')))
check('iso_year_month',identical(vdate('2021-01'),c(2021L,1L))&&is.null(vdate('2021-13')))
check('numeric_fraction_and_box',vnumber('1/8')==.125&&vnumber('2,001,000')==2001000&&vnumber('\\boxed{144}')==144&&is.na(vnumber('system(1)')))
check('clean_fact_prompt_only_drops_added_abstention',identical(paste0(sub(' Give your final answer in the required JSON format.','',VCLEAN,fixed=TRUE),' If you cannot determine the answer, explicitly abstain. Give your final answer in the required JSON format.'),FSTRUCT))
check('no_added_abstention_in_clean_prompts',!grepl('abstain|uncertain',paste(VCLEAN,VMCLEAN),ignore.case=TRUE))
for(q in list(f,m)){
 b<-if(q$domain=='facts')gf else gm
 for(c in c('N0','N1','N2','N3')){z<-vmessages(q,c,b,b);stopifnot(length(z)==if(c=='N0')2 else 4,identical(z[[2]]$content,q$question))}
 a<-vparse(b);a$gold<-'SECRET_GOLD';check(paste0(q$domain,'_peer_allowlist'),!grepl('SECRET_GOLD',vpeer(vjson(a)),fixed=TRUE))
}
w<-list(answer='1111',explanation='Assigned test evidence.')
ww<-lapply(c('W0','W1','W2'),function(c)vmessages(f,c,gf,wrong=w))
check('wrong_material_and_baseline_matched',all(vapply(ww,function(z)identical(z[1:3],ww[[1]][1:3])&&grepl(paste0('Answer: ',w$answer,'\nExplanation: ',w$explanation),z[[4]]$content,fixed=TRUE),TRUE)))
u<-read.csv(file.path(VROOT,'protocol/units.csv'));o<-jsonlite::fromJSON(file.path(VROOT,'protocol/orders.json'))
check('141_questions_846_units_4032_outputs',length(qs)==141&&nrow(u)==846&&sum(vapply(o,nrow,0L))==4032)
check('all_donors_different_and_both_donors_per_repeat_pair',all(u$provider!=u$donor)&&all(vapply(split(u$donor,paste(u$question_id,u$provider)),function(x)length(unique(x))==2,TRUE)))
check('fact100_math41_wrong36',sum(field(qs,'domain')=='facts')==100&&sum(field(qs,'domain')=='mathematics')==41&&length(unique(u$question_id[u$wrong_ablation]))==36)
# Independent checks of the two source-key errors, before collection.
s<-numeric(1965);s[1:2]<-1;for(i in 3:1965)s[i]<-(s[i-1]*s[i-2]+1)%%4
a<-1;b<-4;a1<-sqrt(a*b);b1<-(a+b)/2;b2<-(a1+b1)/2
check('source_sequence_key_errors_verified',s[1965]==2&&abs((b1-a1)*b2/(b-a)^2-1/8)<1e-12)
# Exact enumeration independently checks the less obvious tiling reference.
tiles<-list();for(x in 0:3){cells<-c(2*x+1,2*x+2,2*x+3,2*x+4);for(drop in 1:4)tiles[[length(tiles)+1]]<-sum(2^(cells[-drop]-1))}
memo<-new.env();count<-function(mask){if(mask==1023)return(1);key<-as.character(mask);if(exists(key,memo,inherits=FALSE))return(memo[[key]]);i<-which(bitwAnd(mask,as.integer(2^(0:9)))==0)[1];total<-count(bitwOr(mask,as.integer(2^(i-1))));for(t in tiles)if(bitwAnd(as.integer(t),as.integer(2^(i-1)))!=0&&bitwAnd(mask,as.integer(t))==0)total<-total+count(bitwOr(mask,as.integer(t)));memo[[key]]<-total;total}
check('L_tile_gold_independent_enumeration',count(0L)==87)
write_json(list(time=now(),checks=checks,status='pass',model_calls=0),file.path(VROOT,'protocol/offline_tests.json'))
cat('Passed',length(checks),'precollection checks.\n')
