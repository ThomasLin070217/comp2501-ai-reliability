source('Followup_Validation/R/common.R')
stopifnot(!file.exists(file.path(VROOT,'protocol/freeze.json')))
dir.create(file.path(VROOT,'protocol'),recursive=TRUE,showWarnings=FALSE)
dir.create(file.path(VROOT,'sources'),recursive=TRUE,showWarnings=FALSE)
facts<-read_jsonl('Peer_Misleading_Study/data/main_questions.jsonl')
ex<-union(unlist(read_json('Peer_Misleading_Study/reports/interaction_posthoc/audit.json')$exclusions$exclude_all_known_reference_concerns),c('SV0185','SV3693'))
facts<-Filter(function(q)!q$question_id%in%ex,facts);facts<-facts[order(field(facts,'question_id'))]
facts<-lapply(facts,function(q){q$domain<-'facts';q$family<-'date_fact';q})
stopifnot(length(facts)==100)
src<-'/private/tmp/comp2501-champ-v0.json'
raw<-read_json(src)$problems
eligible<-Filter(function(q)grepl('^-?[0-9]+$',trimws(q[['_answer']]))&&!grepl('figure|diagram|shown below',q[['_text']],ignore.case=TRUE),raw)
set.seed(25011004)
bycat<-split(names(eligible),vapply(eligible,function(q)q$category,''))
print(lengths(bycat));stopifnot(all(lengths(bycat)>=9))
initial_ids<-unlist(lapply(bycat,function(ids)sample(sort(ids),9)),use.names=FALSE)
# Source-reference audit before any API call. Never silently fix upstream gold.
preflight_exclusions<-list(P_Sequence_33='Upstream answer 8 contradicts its derivation and direct substitution: the requested ratio is 1/8.',P_Sequence_10='Upstream answer 3 conflicts with direct modular recurrence: a_1964 mod 4 is 2.',P_Inequality_7='Maximum 2 is attained in the reference only using a zero-length side; positive-length versus zero-side degeneracy is not explicit.',P_Inequality_22='Maximum 2 is attained in the reference only using a zero-length side; positive-length versus zero-side degeneracy is not explicit.')
ids<-setdiff(initial_ids,names(preflight_exclusions))
mq<-lapply(ids,function(id){q<-eligible[[id]];list(question_id=paste0('CHAMP:',id),source_id=id,domain='mathematics',family=q$category,question=q[['_text']],gold=q[['_answer']],gold_numeric=as.numeric(q[['_answer']]),reference_solution=paste(vapply(q$solution$steps,function(s)s[['_text']],''),collapse='\n'),source_url=paste0('https://github.com/YilunZhou/champ-dataset/tree/bfb6651efb3d91c266413db44e41d9a83ab789e5'),selection='Nine fixed-seed integer-answer text problems per source category; no model outputs examined.')})
qs<-c(facts,mq);write_jsonl(qs,file.path(VROOT,'protocol/questions.jsonl'))
write_json(list(upstream='https://github.com/YilunZhou/champ-dataset',revision='bfb6651efb3d91c266413db44e41d9a83ab789e5',dataset_sha256=file_sha(src),upstream_count=length(raw),eligibility_counts=as.list(lengths(bycat)),initial_sample_ids=initial_ids,preflight_exclusions=preflight_exclusions,selected_ids=ids,excluded_fields=c('conversations','fws_annotations','ch_list'),selection_seed=25011004),file.path(VROOT,'sources/CHAMP_manifest.json'))
library(curl)
for(f in c('LICENSE','README.md')){
 u<-paste0('https://raw.githubusercontent.com/YilunZhou/champ-dataset/bfb6651efb3d91c266413db44e41d9a83ab789e5/',f)
 curl_download(u,file.path(VROOT,'sources',paste0('CHAMP_',f)),quiet=TRUE,handle=new_handle(proxy='http://127.0.0.1:7897',timeout=60))
}
set.seed(25011005);wids<-sort(sample(field(facts,'question_id'),36))
units<-list()
for(i in seq_along(qs))for(r in 1:2)for(p in MODELS){
 q<-qs[[i]];direction<-if((i+r)%%2)1 else 2;donor<-MODELS[(match(p,MODELS)-1+direction)%%3+1]
 units[[length(units)+1L]]<-data.frame(question_id=q$question_id,domain=q$domain,family=q$family,provider=p,donor=donor,repeat_id=r,wrong_ablation=q$question_id%in%wids)
}
u<-do.call(rbind,units);write.csv(u,file.path(VROOT,'protocol/units.csv'),row.names=FALSE)
# Wrong explanations are previously generated, frozen material; receiver calls are new.
oldmat<-read_json('Peer_Misleading_Study/data/main_frozen/materials.json');wm<-list()
for(i in which(u$wrong_ablation)){z<-u[i,];key<-paste(z$question_id,z$donor,'wrong',sep=':');stopifnot(!is.null(oldmat[[key]]));wm[[key]]<-oldmat[[key]]}
write_json(wm,file.path(VROOT,'protocol/wrong_materials.json'))
cfg<-read_json('Natural_Crosscheck/protocol/models.json')
write_json(cfg,file.path(VROOT,'protocol/models.json'))
orders<-list()
for(p in MODELS){
 set.seed(25011010+match(p,MODELS));z<-u[u$provider==p,];z<-z[sample(nrow(z)),]
 bas<-cbind(z,condition='N0')
 br<-do.call(rbind,lapply(seq_len(nrow(z)),function(i){cs<-c('N1','N2','N3',if(z$wrong_ablation[i])c('W0','W1','W2'));cbind(z[rep(i,length(cs)),],condition=cs)}))
 orders[[p]]<-rbind(bas,br[sample(nrow(br)),])
}
write_json(orders,file.path(VROOT,'protocol/orders.json'))
write_json(list(fact_system=FSYSTEM,math_system=VMATH,neutral_fact=FNEUTRAL,neutral_math=VMNEUTRAL,verification_no_extra_abstention_fact=VCLEAN,verification_no_extra_abstention_math=VMCLEAN,old_structured_fact=FSTRUCT),file.path(VROOT,'protocol/prompts.json'))
writeLines(unlist(lapply(mq,function(q)c(paste0('## ',q$question_id),q$question,paste('Answer:',q$gold),q$reference_solution,''))),file.path(VROOT,'protocol/math_reference_review.md'))
cat('Prepared',length(qs),'questions,',nrow(u),'units,',sum(vapply(orders,nrow,0L)),'planned outputs. Not yet frozen.\n')
