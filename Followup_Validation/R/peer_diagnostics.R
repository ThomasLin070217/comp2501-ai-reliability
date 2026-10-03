# Post-hoc descriptive mechanism checks; no primary score changes or causal claims.
source('Followup_Validation/R/common.R')
p<-file.path(VROOT,'reports');g<-read.csv(file.path(p,'graded_responses.csv'));c<-read.csv(file.path(p,'cells.csv'));valid<-c('correct','incorrect','abstain')
lookup<-function(ids)g[match(ids,g$task_id),]
base<-lookup(vapply(seq_len(nrow(c)),function(i)vtask(c$question_id[i],c$provider[i],c$repeat_id[i],'N0'),''))
donor<-lookup(vapply(seq_len(nrow(c)),function(i)vtask(c$question_id[i],c$donor[i],c$repeat_id[i],'N0'),''))
c$donor_grade<-donor$grade
canon<-function(txt,domain){a<-vparse(txt);if(!vvalid(a)||a$abstain)return(NA_character_);if(domain=='mathematics'){v<-vnumber(a$answer);if(!is.finite(v))return(NA_character_);return(as.character(v))};v<-vdate(a$answer);if(is.null(v))NA_character_ else paste(v,collapse='-')}
bc<-vapply(seq_len(nrow(c)),function(i)canon(base$response_text[i],c$domain[i]),'')
dc<-vapply(seq_len(nrow(c)),function(i)canon(donor$response_text[i],c$domain[i]),'')
c$same_wrong_initial_answer<-c$N0=='incorrect'&c$donor_grade=='incorrect'&!is.na(bc)&!is.na(dc)&bc==dc
c$event<-ifelse(c$N1=='incorrect'&c$N2=='correct','wrong_to_correct',ifelse(c$N1=='correct'&c$N2=='incorrect','correct_to_wrong',ifelse(c$N1=='incorrect'&c$N2=='incorrect'&c$same_wrong_initial_answer,'same_wrong_answer_persists','other')))
write.csv(c,file.path(p,'peer_quality_cells.csv'),row.names=FALSE)
z<-c[c$N0%in%valid&c$donor_grade%in%valid&c$N2%in%valid,]
tb<-as.data.frame(table(z$domain,z$N0,z$donor_grade,z$N2));names(tb)<-c('domain','initial_receiver','initial_donor','cross_final','n');tb<-tb[tb$n>0,];write.csv(tb,file.path(p,'peer_quality_transitions.csv'),row.names=FALSE)
same<-do.call(rbind,lapply(c('facts','mathematics'),function(domain){a<-c[c$domain==domain&c$same_wrong_initial_answer&c$N2%in%valid,];data.frame(domain=domain,n=nrow(a),cross_wrong=sum(a$N2=='incorrect'),cross_correct=sum(a$N2=='correct'),cross_abstain=sum(a$N2=='abstain'))}))
write.csv(same,file.path(p,'same_wrong_peer_outcomes.csv'),row.names=FALSE)
qs<-indexed(read_jsonl(file.path(VROOT,'protocol/questions.jsonl')),'question_id');selection<-list();set.seed(25011009)
for(domain in c('facts','mathematics'))for(event in c('wrong_to_correct','correct_to_wrong','same_wrong_answer_persists')){
 a<-c[c$domain==domain&c$event==event,];if(!nrow(a))next;a<-a[sample(seq_len(nrow(a)),min(2,nrow(a))),];selection[[length(selection)+1]]<-a
 for(i in seq_len(nrow(a))){u<-a[i,];id<-paste(u$question_id,u$provider,u$repeat_id,sep=':');text<-c(paste('#',domain,event,id),'',qs[[u$question_id]]$question,paste('Reference:',qs[[u$question_id]]$gold),'')
 for(role in c('N0','donor','N1','N2','N3')){provider<-if(role=='donor')u$donor else u$provider;cond<-if(role=='donor')'N0'else role;r<-lookup(vtask(u$question_id,provider,u$repeat_id,cond));text<-c(text,paste('##',role,provider),r$response_text,'')}
 writeLines(text,file.path(p,sprintf('case_%s_%s_%d.md',domain,event,i)))
 }
}
write.csv(do.call(rbind,selection),file.path(p,'case_selection.csv'),row.names=FALSE)
writeLines(c('# Descriptive peer-quality diagnostics','',
 'This post-hoc analysis was added after reading baseline mathematical errors, before inspecting final comparison aggregates. Same-question errors are correlated even across different model APIs. `same_wrong_peer_outcomes.csv` counts units with matching canonical incorrect initial answers and a scorable N2 outcome. This is conditional on observed peer quality, not a randomized causal comparison of correct versus wrong donors.', '',
 'The examples use seed 25011009, selecting up to two units in each domain/event category: N1 wrong to N2 correct, N1 correct to N2 wrong, or persisting wrong answers where receiver and donor initially agreed on the same incorrect value. All selected examples and their raw answers are retained; examples are illustrative, not an estimate of overall prevalence. The selection is based on final-answer grades and does not certify reasoning validity.'),file.path(p,'peer_diagnostics.md'))
