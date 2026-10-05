# Pure R descriptive and paired analysis of the frozen facts experiment.
source('Two_Model_Collection/facts/protocol/scoring.R')
root<-Sys.getenv('FACTS_ANALYSIS_ROOT',unset='Two_Model_Collection/facts');out<-file.path(root,'reports')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
tasks<-read.csv(file.path(root,'protocol/tasks.csv'),stringsAsFactors=FALSE)
qs<-indexed(read_jsonl(file.path(root,'protocol/questions.jsonl')),'question_id')
read_if<-function(p)if(file.exists(p))read_jsonl(p)else list()
records<-read_if(file.path(root,'runs/completed.jsonl'))
skips<-read_if(file.path(root,'runs/skipped.jsonl'))
stopifnot(!anyDuplicated(field(records,'id')),all(field(records,'id')%in%tasks$id))
rows<-lapply(records,function(r){
 t<-tasks[match(r$id,tasks$id),];txt<-r$text%||%'';status<-r$status%||%'unknown'
 g<-fact_grade(txt,qs[[t$question_id]],status)
 data.frame(t,status=status,grade=g,error=if(g=='unscorable')NA_real_ else as.numeric(g=='incorrect'),
  search_requested=r$search_requested%||%NA_real_,text=txt,stringsAsFactors=FALSE)
})
if(!length(rows)){cat('No completed facts records; analysis not yet possible.\n');quit(status=0)}
d<-do.call(rbind,rows);write.csv(d,file.path(out,'graded_responses.csv'),row.names=FALSE)
coverage<-merge(tasks,d[c('id','status','grade')],by='id',all.x=TRUE,sort=FALSE)
coverage$status[coverage$id%in%field(skips,'id')]<-'dependency_skipped'
coverage$status[is.na(coverage$status)]<-'not_collected'
write.csv(coverage,file.path(out,'coverage.csv'),row.names=FALSE)
counts<-do.call(rbind,lapply(split(d,interaction(d$provider,d$condition,drop=TRUE)),function(z){
 n<-sum(!is.na(z$error));data.frame(provider=z$provider[1],condition=z$condition[1],returned=nrow(z),
 correct=sum(z$grade=='correct'),incorrect=sum(z$grade=='incorrect'),abstain=sum(z$grade=='abstain'),
 unscorable=sum(z$grade=='unscorable'),valid=n,error_rate=if(n)sum(z$grade=='incorrect')/n else NA_real_,
 searches_observed=sum(z$search_requested>0,na.rm=TRUE),search_metadata_missing=sum(is.na(z$search_requested)))
}))
write.csv(counts,file.path(out,'counts.csv'),row.names=FALSE)
valid<-d[!is.na(d$error),]
if(nrow(valid)){
 qm<-aggregate(error~provider+condition+question_id,valid,mean)
 mm<-aggregate(error~provider+condition,qm,mean)
 write.csv(qm,file.path(out,'question_means.csv'),row.names=FALSE)
 write.csv(mm,file.path(out,'model_means.csv'),row.names=FALSE)
}
specs<-list(natural_crosscheck=c('self_check','A0_AI'),initial_vs_self=c('neutral_initial','self_check'),
 upstream_misconception=c('neutral_initial','misconception_initial'),propagation_AI=c('A0_AI','A1_AI'),
 propagation_Human=c('A0_Human','A1_Human'),attribution_A0=c('A0_AI','A0_Human'),attribution_A1=c('A1_AI','A1_Human'))
set.seed(25011008);effects<-list();pair_rows<-list();models<-c('minimax','deepseek');model_rows<-list();transitions<-list()
for(nm in names(specs)){
 cs<-specs[[nm]];a<-valid[valid$condition==cs[1],];b<-valid[valid$condition==cs[2],]
 z<-merge(a,b,by=c('question_id','provider','repeat_id'),suffixes=c('_a','_b'))
 if(!nrow(z))next
 z$comparison<-nm;pair_rows[[nm]]<-z
 v<-aggregate(cbind(error_a,error_b)~question_id+provider,z,mean)
 bymodel<-aggregate(cbind(error_a,error_b)~provider,v,mean);bymodel$comparison<-nm
 bymodel$pairs<-vapply(bymodel$provider,function(p)sum(z$provider==p),0L)
 bymodel$questions<-vapply(bymodel$provider,function(p)sum(v$provider==p),0L)
 model_rows[[nm]]<-bymodel
 transition<-as.data.frame(table(provider=z$provider,from=z$grade_a,to=z$grade_b));transition$comparison<-nm
 transitions[[nm]]<-transition
 if(!setequal(bymodel$provider,models))next
 ids<-sort(unique(v$question_id));ma<-mb<-matrix(NA_real_,length(ids),2,dimnames=list(ids,models))
 for(i in seq_len(nrow(v))){ma[v$question_id[i],v$provider[i]]<-v$error_a[i];mb[v$question_id[i],v$provider[i]]<-v$error_b[i]}
 effect<-function(ix){aa<-colMeans(ma[ix,,drop=FALSE],na.rm=TRUE);bb<-colMeans(mb[ix,,drop=FALSE],na.rm=TRUE);if(any(!is.finite(c(aa,bb))))NA_real_ else mean(bb-aa)}
 boot<-replicate(5000,effect(sample(seq_along(ids),length(ids),replace=TRUE)))
 alpha<-if(nm=='natural_crosscheck').025 else .05
 ci<-quantile(boot,c(alpha/2,1-alpha/2),na.rm=TRUE,names=FALSE)
 effects[[nm]]<-data.frame(comparison=nm,condition_a=cs[1],condition_b=cs[2],
  error_a=mean(bymodel$error_a),error_b=mean(bymodel$error_b),difference=effect(seq_along(ids)),
  lower=ci[1],upper=ci[2],confidence=1-alpha,questions=length(ids),pairs=nrow(z),bootstrap_valid=sum(is.finite(boot)))
}
if(length(pair_rows))write.csv(do.call(rbind,pair_rows),file.path(out,'paired_records.csv'),row.names=FALSE)
if(length(model_rows))write.csv(do.call(rbind,model_rows),file.path(out,'paired_model_means.csv'),row.names=FALSE)
if(length(transitions))write.csv(do.call(rbind,transitions),file.path(out,'transitions.csv'),row.names=FALSE)
eff<-if(length(effects))do.call(rbind,effects)else data.frame()
if(nrow(eff))write.csv(eff,file.path(out,'paired_effects.csv'),row.names=FALSE)
# Complete-path descriptive denominators: donor A0/A1 and B0 linked by frozen IDs.
di<-setNames(seq_len(nrow(d)),d$id);paths<-list()
for(i in which(d$condition%in%c('A1_AI','A1_Human'))){
 z<-d[i,];bid<-z$baseline_id;a1id<-z$donor_id
 a0id<-sub(':misconception_initial$',':neutral_initial',a1id)
 ix<-unname(di[c(bid,a0id,a1id)])
 if(any(is.na(ix)))next
 base<-d[ix[1],];a0<-d[ix[2],];a1<-d[ix[3],]
 usable<-all(c(base$grade,a0$grade,a1$grade,z$grade)!='unscorable')
 eligible<-usable&&base$grade=='correct'&&a0$grade=='correct'&&a1$grade=='incorrect'
 paths[[length(paths)+1L]]<-data.frame(id=z$id,question_id=z$question_id,provider=z$provider,repeat_id=z$repeat_id,
  condition=z$condition,B0=base$grade,A0=a0$grade,A1=a1$grade,final=z$grade,all_valid=usable,
  eligible=eligible,full_path=eligible&&z$grade=='incorrect')
}
if(length(paths)){
 pp<-do.call(rbind,paths);write.csv(pp,file.path(out,'propagation_paths.csv'),row.names=FALSE)
 ps<-do.call(rbind,lapply(split(pp,interaction(pp$provider,pp$condition,drop=TRUE)),function(z){
  av<-sum(z$all_valid);el<-sum(z$eligible);hit<-sum(z$full_path)
  data.frame(provider=z$provider[1],condition=z$condition[1],all_valid=av,eligible_opportunities=el,
   full_paths=hit,path_per_all=if(av)hit/av else NA_real_,path_per_eligible=if(el)hit/el else NA_real_)
 }))
 write.csv(ps,file.path(out,'propagation_path_counts.csv'),row.names=FALSE)
}
# Conditional flip risks use matched, valid receiver baseline/final pairs.
flip_rows<-list()
for(cond in c('self_check','A0_AI','A0_Human','A1_AI','A1_Human')){
 z<-merge(valid[valid$condition=='neutral_initial',],valid[valid$condition==cond,],
  by=c('question_id','provider','repeat_id'),suffixes=c('_base','_final'))
 if(!nrow(z))next
 for(p in models)for(g in c('correct','abstain')){
  zz<-z[z$provider==p&z$grade_base==g,];n<-nrow(zz);k<-sum(zz$grade_final=='incorrect')
  flip_rows[[length(flip_rows)+1L]]<-data.frame(provider=p,condition=cond,baseline_grade=g,
   wrong_finals=k,eligible_pairs=n,conditional_risk=if(n)k/n else NA_real_)
 }
}
if(length(flip_rows))write.csv(do.call(rbind,flip_rows),file.path(out,'conditional_flip_risks.csv'),row.names=FALSE)
# Source-by-upstream-input interaction requires all four branches valid.
cols<-c('A0_AI','A0_Human','A1_AI','A1_Human');wide<-NULL
for(cc in cols){
 zz<-valid[valid$condition==cc,c('question_id','provider','repeat_id','error')];names(zz)[4]<-cc
 wide<-if(is.null(wide))zz else merge(wide,zz,by=c('question_id','provider','repeat_id'))
}
if(nrow(wide)){
 wide$interaction<-(wide$A1_Human-wide$A1_AI)-(wide$A0_Human-wide$A0_AI)
 write.csv(wide,file.path(out,'source_input_interaction_pairs.csv'),row.names=FALSE)
 iv<-aggregate(interaction~question_id+provider,wide,mean)
 im<-aggregate(interaction~provider,iv,mean)
 write.csv(im,file.path(out,'source_input_interaction_model_means.csv'),row.names=FALSE)
 if(setequal(im$provider,models)){
  ids<-unique(iv$question_id);mat<-matrix(NA_real_,length(ids),2,dimnames=list(ids,models))
  for(i in seq_len(nrow(iv)))mat[iv$question_id[i],iv$provider[i]]<-iv$interaction[i]
  fn<-function(ix){m<-colMeans(mat[ix,,drop=FALSE],na.rm=TRUE);if(any(!is.finite(m)))NA_real_ else mean(m)}
  set.seed(25011009);boot<-replicate(5000,fn(sample(seq_along(ids),length(ids),replace=TRUE)))
  ci<-quantile(boot,c(.025,.975),na.rm=TRUE,names=FALSE)
  write_json(list(definition='(A1_Human - A1_AI) - (A0_Human - A0_AI)',difference=fn(seq_along(ids)),
   lower=ci[1],upper=ci[2],confidence=.95,questions=length(ids),complete_four_branch_units=nrow(wide),
   exploratory=TRUE),file.path(out,'source_input_interaction.json'))
 }
}
complete<-all(coverage$status!='not_collected')
summary<-list(time=now(),planned=nrow(tasks),completed=nrow(d),dependency_skipped=length(skips),
 not_collected=sum(coverage$status=='not_collected'),scope_complete=complete,grade_counts=as.list(table(d$grade)),
 budget='See runtime ledger/status; this script does not reconstruct billing from tokens.',
 note='No search is a retained model choice. Empty, malformed, truncated and failed outputs are not abstentions.')
write_json(summary,file.path(out,'summary.json'))
lines<-c('# Facts experiment: collection and paired analysis','',
 if(complete)'All scheduled tasks are completed or explicitly logged as unavailable.'else'**Partial collection: do not present these results as the completed full experiment.**','',
 sprintf('100 questions; 25 preselected mechanism questions; %d/1600 completed target records; %d dependency skips; %d not collected.',nrow(d),length(skips),summary$not_collected),
 '', 'Error rate = wrong / (correct + wrong + explicit abstention). Technical and formatting failures are separate.',
 'Within each paired comparison, repetitions are averaged per question/model, then questions are averaged, then the two models receive equal weight. Intervals resample question clusters 5,000 times.',
 'Natural cross-checking uses a 97.5% interval (two task-domain primary comparisons); other intervals are exploratory 95% intervals. No result determines stopping or additional sampling.','')
if(nrow(eff))for(i in seq_len(nrow(eff))){x<-eff[i,];lines<-c(lines,sprintf('- %s: %.2f%% to %.2f%%; difference %+.2f percentage points; %.1f%% CI [%.2f, %.2f]; %d questions, %d pairs.',x$comparison,100*x$error_a,100*x$error_b,100*x$difference,100*x$confidence,100*x$lower,100*x$upper,x$questions,x$pairs))}
lines<-c(lines,'','## Limits','',
 'Reference dates are inherited from the retained question bank, not newly adjudicated against every primary source. Model answer/reason conflicts and unusual date formats require separate semantic review.',
 'The mechanism subset is exploratory. Report full-path counts and denominators, including zero opportunities; do not infer a general error-propagation mechanism from rare cases.',
 'Human attribution is simulated by a fixed user-source header; no human participants supplied these suggestions. A1 describes an input condition, not guaranteed wrong output.',
 'Autonomous search is not randomly assigned, so searched versus unsearched comparisons do not establish the causal effect of search. Sources may contain benchmark copies.')
writeLines(lines,file.path(out,'RESULTS.md'))
if(nrow(eff)&&'natural_crosscheck'%in%eff$comparison){
 x<-eff[eff$comparison=='natural_crosscheck',];png(file.path(out,'error_rates.png'),width=1000,height=700,res=130)
 v<-100*c(x$error_a,x$error_b);b<-barplot(v,names.arg=c('Self-check','Cross-model check'),ylim=c(0,100),
 col=c('#708398','#2563eb'),ylab='Wrong answers (%)',main='Facts: paired error rate')
 text(b,v+3,sprintf('%.2f%%',v));dev.off()
}
cat('Analysed',nrow(d),'facts records; scope complete:',complete,'\n')
