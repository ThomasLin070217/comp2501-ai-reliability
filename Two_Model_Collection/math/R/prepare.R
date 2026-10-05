library(jsonlite)
library(digest)
root <- 'Two_Model_Collection/math'
dir.create(file.path(root,'protocol'),recursive=TRUE,showWarnings=FALSE)
prompts <- fromJSON('Math_Prompt_Design/generated/model_prompts.json',simplifyVector=FALSE)$questions
refs <- fromJSON('Math_Prompt_Design/generated/researcher_reference.json',simplifyVector=FALSE)
reviews <- fromJSON('Math_Prompt_Design/generated/item_review.json',simplifyVector=FALSE)
ids <- vapply(prompts,`[[`,'','question_id')
family <- setNames(vapply(refs,`[[`,'','family'),vapply(refs,`[[`,'','question_id'))
RNGkind('Mersenne-Twister','Inversion','Rejection');set.seed(25011005)
subset <- sort(unlist(lapply(sort(unique(family)),function(f)sample(sort(names(family)[family==f]),3))))
questions <- lapply(prompts,function(q){q$mechanism_selected<-q$question_id%in%subset;q$domain<-'math';q$family<-unname(family[q$question_id]);q})
write_json(questions,file.path(root,'protocol/questions.json'),auto_unbox=TRUE,pretty=TRUE)
file.copy('Math_Prompt_Design/generated/model_prompts.json',file.path(root,'protocol/prompts.json'),overwrite=TRUE)
write_json(refs,file.path(root,'protocol/researcher_reference.json'),auto_unbox=TRUE,pretty=TRUE)
write_json(reviews,file.path(root,'protocol/stimulus_review.json'),auto_unbox=TRUE,pretty=TRUE)
write.csv(data.frame(question_id=subset,family=unname(family[subset])),file.path(root,'protocol/mechanism_subset.csv'),row.names=FALSE)
key<-function(q,p,r,c)paste('two_math',q,p,paste0('r',r),c,sep=':')
tasks<-list()
for(q in questions) for(r in 1:2) for(p in c('minimax','deepseek')) {
 donor<-if(p=='minimax')'deepseek' else 'minimax'
 conditions<-c('neutral_initial','self_check','A0_AI',if(q$mechanism_selected)c('misconception_initial','A0_Human','A1_AI','A1_Human'))
 for(c in conditions) {
  peer<-grepl('^A[01]_',c)
  tasks[[length(tasks)+1L]]<-data.frame(id=key(q$question_id,p,r,c),question_id=q$question_id,domain='math',family=q$family,provider=p,donor=if(peer)donor else '',repeat_id=r,condition=c,
   baseline_id=if(c%in%c('neutral_initial','misconception_initial'))'' else key(q$question_id,p,r,'neutral_initial'),
   donor_id=if(peer)key(q$question_id,donor,r,if(startsWith(c,'A0'))'neutral_initial'else'misconception_initial')else'',
   phase=if(c=='neutral_initial')1L else if(c%in%c('self_check','A0_AI'))2L else if(c=='misconception_initial')3L else 4L,mechanism_selected=q$mechanism_selected,stringsAsFactors=FALSE)
 }
}
tasks<-do.call(rbind,tasks)
# Stage order is independent of model results; fixed random order within each stage.
set.seed(25011006);tasks<-tasks[unlist(lapply(1:4,function(s)sample(which(tasks$phase==s)))),]
tasks$order<-seq_len(nrow(tasks))
stopifnot(nrow(tasks)==732L,length(subset)==15L,all(table(family[subset])==3L),!anyDuplicated(tasks$id))
write.csv(tasks,file.path(root,'protocol/tasks.csv'),row.names=FALSE)
write_json(list(prepared_at=format(Sys.time(),tz='UTC',usetz=TRUE),status='prepared_before_collection',seed=25011005,
 questions=41L,mechanism_questions=15L,target_responses=732L,providers=c('minimax','deepseek'),repetitions=2L,
 native_search='available; automatic choice; no required search instruction',budget_cny=140,
 collection_authorized_by='User: 你现在用两个agent分别跑这两个数据收集的任务。',
 source_hashes=lapply(c('Math_Prompt_Design/generated/model_prompts.json','Math_Prompt_Design/generated/researcher_reference.json','Math_Prompt_Design/generated/item_review.json'),function(p)list(path=p,sha256=digest(file=p,algo='sha256')))),
 file.path(root,'protocol/preparation.json'),pretty=TRUE,auto_unbox=TRUE)
cat('Prepared 41 questions, 15 fixed mechanism questions, 732 tasks. No API calls.\n')
