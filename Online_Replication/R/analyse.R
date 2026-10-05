source('Online_Replication/R/batch.R')
root<-file.path(OROOT,'reports');dir.create(root,recursive=TRUE,showWarnings=FALSE)
qs<-indexed(read_jsonl(file.path(OROOT,'protocol/questions.jsonl')),'question_id')
tasks<-read.csv(file.path(OROOT,'protocol/tasks.csv'),stringsAsFactors=FALSE)
rs<-oread(file.path(OROOT,'runs/completed.jsonl'));http<-oallhttp();skipped<-oread(file.path(OROOT,'runs/skipped.jsonl'))
stopifnot(!anyDuplicated(field(rs,'id')),all(field(rs,'id')%in%tasks$id))
rows<-lapply(rs,function(r){
 q<-qs[[r$question_id]];g<-if(r$status=='ok')oscore(r$text,q)else'unscorable'
 data.frame(id=r$id,question_id=r$question_id,domain=r$domain,family=r$family,provider=r$provider,donor=r$donor,
  repeat_id=r$repeat_id,condition=r$condition,status=r$status,grade=g,
  error=if(g=='unscorable')NA_real_ else as.numeric(g=='incorrect'),
  new_search_requested=r$search_requested>0,search_calls=r$search_requested,
  visible_result_blocks=r$search_result_blocks,text=r$text)
})
if(!length(rows))stop('No formal completed records yet')
d<-do.call(rbind,rows);write.csv(d,file.path(root,'graded_responses.csv'),row.names=FALSE)
coverage<-merge(tasks,d[c('id','status','grade')],by='id',all.x=TRUE,sort=FALSE)
coverage$status[coverage$id%in%field(skipped,'id')]<-'dependency_skipped'
coverage$status[is.na(coverage$status)]<-'not_collected'
write.csv(coverage,file.path(root,'coverage.csv'),row.names=FALSE)
parts<-split(d,interaction(d$domain,d$provider,d$condition,drop=TRUE))
counts<-do.call(rbind,lapply(parts,function(z)data.frame(domain=z$domain[1],provider=z$provider[1],condition=z$condition[1],
 returned=nrow(z),correct=sum(z$grade=='correct'),incorrect=sum(z$grade=='incorrect'),abstain=sum(z$grade=='abstain'),
 unscorable=sum(z$grade=='unscorable'),new_search_answers=sum(z$new_search_requested),search_rate=mean(z$new_search_requested))))
write.csv(counts,file.path(root,'counts_and_search.csv'),row.names=FALSE)
valid<-d[!is.na(d$error),]
qm<-aggregate(error~domain+provider+condition+question_id,valid,mean)
mm<-aggregate(error~domain+provider+condition,qm,mean)
nn<-aggregate(question_id~domain+provider+condition,qm,length);names(nn)[4]<-'questions'
mm<-merge(mm,nn);write.csv(qm,file.path(root,'question_means.csv'),row.names=FALSE)
write.csv(mm,file.path(root,'model_means_available.csv'),row.names=FALSE)
specs<-list(natural_crosscheck=c('N1','N2'),initial_vs_self=c('N0','N1'),structured_crosscheck=c('N2','N3'),
 wrong_answer=c('N1','C1'),wrong_explanation=c('N1','C2'),verification_wrong=c('C2','C3'),
 no_extra_abstention=c('C2','W1'),extra_abstention=c('W1','C3'),correct_advice=c('C4','C5'),math_trap_wrong=c('C0','C2'))
tables<-list();pairs<-list();effects<-list()
set.seed(25011008)
for(name in names(specs))for(domain in unique(d$domain)){
 cs<-specs[[name]];a<-d[d$domain==domain&d$condition==cs[1]&!is.na(d$error),];b<-d[d$domain==domain&d$condition==cs[2]&!is.na(d$error),]
 if(!nrow(a)||!nrow(b))next
 z<-merge(a,b,by=c('question_id','provider','repeat_id'),suffixes=c('_a','_b'))
 if(!nrow(z))next
 z$comparison<-name;z$domain<-domain;pairs[[length(pairs)+1L]]<-z
 v<-aggregate(cbind(error_a,error_b)~question_id+provider,z,mean)
 bymodel<-aggregate(cbind(error_a,error_b)~provider,v,mean)
 bymodel$comparison<-name;bymodel$domain<-domain
 bymodel$questions<-vapply(bymodel$provider,function(p)sum(v$provider==p),0L)
 bymodel$pairs<-vapply(bymodel$provider,function(p)sum(z$provider==p),0L)
 tables[[length(tables)+1L]]<-bymodel
 # Missing models do not silently become a "three-model average".
 if(!setequal(bymodel$provider,MODELS))next
 ids<-unique(v$question_id);matrix_a<-matrix_b<-matrix(NA_real_,nrow=length(ids),ncol=3,dimnames=list(ids,MODELS))
 for(i in seq_len(nrow(v))){matrix_a[v$question_id[i],v$provider[i]]<-v$error_a[i];matrix_b[v$question_id[i],v$provider[i]]<-v$error_b[i]}
 effect<-function(ix){a<-colMeans(matrix_a[ix,,drop=FALSE],na.rm=TRUE);b<-colMeans(matrix_b[ix,,drop=FALSE],na.rm=TRUE);if(any(!is.finite(c(a,b))))NA_real_ else mean(b-a)}
 boot<-replicate(5000,effect(sample(seq_along(ids),length(ids),replace=TRUE)))
 alpha<-if(name=='natural_crosscheck'&&domain%in%c('facts','mathematics')).025 else .05
 ci<-quantile(boot,c(alpha/2,1-alpha/2),na.rm=TRUE,names=FALSE)
 effects[[length(effects)+1L]]<-data.frame(comparison=name,domain=domain,condition_a=cs[1],condition_b=cs[2],
 error_a=mean(bymodel$error_a),error_b=mean(bymodel$error_b),difference=effect(seq_along(ids)),
 lower=ci[1],upper=ci[2],confidence=1-alpha,questions=length(ids),pairs=nrow(z),bootstrap_valid=sum(is.finite(boot)))
}
if(length(tables))write.csv(do.call(rbind,tables),file.path(root,'paired_model_means.csv'),row.names=FALSE)
if(length(pairs))write.csv(do.call(rbind,pairs),file.path(root,'paired_records.csv'),row.names=FALSE)
eff<-if(length(effects))do.call(rbind,effects)else data.frame()
if(nrow(eff))write.csv(eff,file.path(root,'paired_equal_model_effects.csv'),row.names=FALSE)
usage<-.44723+sum(vapply(http,function(x)x$guard_cny,0))
complete<-nrow(d)+length(skipped)==nrow(tasks)
write_json(list(time=now(),planned=nrow(tasks),completed=nrow(d),dependency_skipped=length(skipped),
 not_collected=nrow(tasks)-nrow(d)-length(skipped),scope_complete=complete,new_guard_cny=usage,
 raw_http_calls=length(http),search_requested_answers=sum(d$new_search_requested),grade_counts=as.list(table(d$grade))),file.path(root,'summary.json'))
lines<-c('# 自主联网复现实验：当前结果', '',
 if(complete)'状态：计划任务均已完成或记录依赖失败。'else'**状态：尚未完成全量采集；以下是当前已完成部分，不能冒充全量结论。**',
 sprintf('计划 %s 条回答；已完成 %s，依赖不可用跳过 %s，未采集 %s。新增保守估价 %.3f 元，包含预检，非供应商账单。',nrow(tasks),nrow(d),length(skipped),nrow(tasks)-nrow(d)-length(skipped),usage),
 '', '各模型自行决定是否搜索，不在提示中要求搜索、不预先提供网页材料。不搜索的回答照常进入主分析。',
 '主指标错误率 = 错误 / (正确 + 错误 + 明确弃答)。格式异常、截断和传输失败单列，不当作弃答。',
 '同一模型、同一题的有效重复先平均，再对题目平均，最后三个模型等权平均。比较双方只用同题、同模型、同重复的有效配对。',
 '区间按题目联合重抽样5000次。两类自然跨模型主要比较各用97.5%区间，其余95%为探索性比较；不以显著性决定补采。',
 '', '## 自行复核与跨模型复核', '')
if(nrow(eff))for(i in which(eff$comparison=='natural_crosscheck')){x<-eff[i,];lines<-c(lines,sprintf('- %s：自行 %.2f%%，跨模型 %.2f%%，差 %+.2f 个百分点；%.1f%% 区间 [%.2f, %.2f]，%s 题、%s 对。',x$domain,100*x$error_a,100*x$error_b,100*x$difference,100*x$confidence,100*x$lower,100*x$upper,x$questions,x$pairs))}
lines<-c(lines,'','## 解释范围','',
 '此处比较的是模型及其供应商搜索系统的整体行为。自主搜索选择不是随机的，搜索/未搜索子组差异不能解释为搜索的因果效果。',
 'Kimi原生工具可能只暴露search_id及用量，不能声称已逐页核查其来源。DeepSeek/MiniMax可见来源另存于原始记录，可能检索到基准答案副本，后续需标注敏感性。',
 '数学题允许自主搜完整题目，因此反映联网环境下的整体答题表现，不能单独证明内在推理能力提高。',
 '历史离线结果、原评分及旧预检均保留；旧离线与新联网的历史差异不能独立隔离时间、接口和提示变动。',
 '原始受控正确/错误建议沿用冻结刺激材料；它们不是本轮模型自然联网产生的答案。新自然donor均来自本轮独立初答。')
writeLines(lines,file.path(root,'结果说明.md'))
if(nrow(eff)&&any(eff$comparison=='natural_crosscheck')){
 z<-eff[eff$comparison=='natural_crosscheck',];png(file.path(root,'error_rates.png'),width=1300,height=700,res=130)
 par(mfrow=c(1,nrow(z)),mar=c(6,5,4,1))
 for(i in seq_len(nrow(z))){v<-100*c(z$error_a[i],z$error_b[i]);bx<-barplot(v,names.arg=c('Self-check','Cross-model'),ylim=c(0,100),col=c('#718096','#2563eb'),ylab='Wrong answers (%)',main=z$domain[i]);text(bx,v+3,sprintf('%.2f%%',v))}
 dev.off()
}
cat('Analysed',nrow(d),'completed tasks; guard',usage,'scope complete',complete,'\n')
