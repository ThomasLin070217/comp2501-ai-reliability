source('Web_Factcheck_100/R/common.R')
freeze<-read_json(file.path(WROOT,'protocol/freeze.json'))
stopifnot(all(vapply(names(freeze$files_sha256),function(p)file_sha(p)==freeze$files_sha256[[p]],TRUE)))
qs<-read_jsonl(file.path(WROOT,'protocol/questions.jsonl'));qi<-indexed(qs,'question_id')
rr<-wread(file.path(WROOT,'runs/responses.jsonl'));ats<-wread(file.path(WROOT,'runs/attempts.jsonl'))
stopifnot(length(rr)==length(ats),setequal(field(rr,'attempt_id'),field(ats,'attempt_id')))
last<-rr[!duplicated(field(rr,'question_id'),fromLast=TRUE)];ri<-indexed(last,'question_id')
stopifnot(length(last)==100L,file.exists(file.path(WROOT,'runs/done.json')))
url_rows<-list();query_rows<-list()
tab<-do.call(rbind,lapply(qs,function(q){
 r<-ri[[q$question_id]];txt<-r$text%||%'';a<-vparse(txt)
 blocks<-r$raw_response$content%||%list()
 searches<-Filter(function(b)identical(b$type,'server_tool_use')&&identical(b$name,'web_search'),blocks)
 result_blocks<-Filter(function(b)identical(b$type,'web_search_tool_result'),blocks)
 sources<-unlist(lapply(result_blocks,function(b)Filter(function(v)is.list(v)&&!is.null(v$url),b$content%||%list())),recursive=FALSE)
 urls<-vapply(sources,function(v)v$url,'')
 if(length(sources))for(s in sources)url_rows[[length(url_rows)+1L]]<<-data.frame(question_id=q$question_id,url=s$url,title=s$title%||%'')
 if(length(searches))for(s in searches)query_rows[[length(query_rows)+1L]]<<-data.frame(question_id=q$question_id,query=s$input$query%||%'')
 contaminated<-grepl('simpleqa|comp2501-ai-reliability|huggingface.co/datasets|kaggle.com/datasets',urls,ignore.case=TRUE)
 data.frame(question_id=q$question_id,question=q$question,gold=q$gold_answer%||%paste(unlist(q$gold_parts),collapse='-'),
   status=r$status,grade=if(r$status=='ok')vscore(txt,q)else'unscorable',
   answer=if(is.list(a))a$answer%||%''else'',abstain=if(is.list(a))a$abstain%||%NA else NA,
   reason=if(is.list(a))a$reason%||%''else'',search_calls=r$search_calls%||%0,
   search_result_blocks=length(result_blocks),returned_sources=length(urls),
   returned_source_url_in_reason=if(is.list(a))any(vapply(urls,function(u)grepl(u,a$reason%||%'',fixed=TRUE),TRUE))else FALSE,
   possible_benchmark_url=any(contaminated),source_urls=paste(unique(urls),collapse=' | '),response_text=txt,
   stringsAsFactors=FALSE)
}))
out<-file.path(WROOT,'reports');dir.create(out,recursive=TRUE,showWarnings=FALSE)
write.csv(tab,file.path(out,'answers.csv'),row.names=FALSE)
write.csv(if(length(url_rows))do.call(rbind,url_rows)else data.frame(question_id=character(),url=character(),title=character()),file.path(out,'sources.csv'),row.names=FALSE)
write.csv(if(length(query_rows))do.call(rbind,query_rows)else data.frame(question_id=character(),query=character()),file.path(out,'queries.csv'),row.names=FALSE)
valid<-c('correct','incorrect','abstain')
summarize<-function(x,label)data.frame(group=label,questions=nrow(x),scorable=sum(x$grade%in%valid),
 correct=sum(x$grade=='correct'),wrong=sum(x$grade=='incorrect'),abstain=sum(x$grade=='abstain'),
 unscorable=sum(!x$grade%in%valid),error_pct=100*mean(x$grade[x$grade%in%valid]=='incorrect'))
stats<-rbind(summarize(tab,'Web enabled: all 100'),summarize(tab[tab$search_calls>0,],'Actual search observed'),
 summarize(tab[tab$search_calls==0,],'No search observed'))
write.csv(stats,file.path(out,'outcomes.csv'),row.names=FALSE)
# Codex read the three malformed outputs after collection; retain frozen scores.
semantic_audit<-data.frame(question_id=c('SV1181','SV1140','SV2391'),
 frozen_grade='unscorable',semantic_label='abstain',reviewer='Codex (AI review)',
 reason=c('Explicit inability to verify; no final date supplied; missing JSON object.',
          'Empty answer and boolean abstain=true, but empty required reason.',
          'Empty answer and inability to confirm, but abstain is string true instead of boolean.'))
stopifnot(setequal(tab$question_id[tab$grade=='unscorable'],semantic_audit$question_id),
 all(tab$status[tab$question_id%in%semantic_audit$question_id]=='ok'))
write.csv(semantic_audit,file.path(out,'format_semantic_audit.csv'),row.names=FALSE)
semantic<-tab;semantic$grade[match(semantic_audit$question_id,semantic$question_id)]<-semantic_audit$semantic_label
semantic_stats<-summarize(semantic,'Post-hoc AI semantic sensitivity: malformed abstentions')
write.csv(semantic_stats,file.path(out,'format_semantic_sensitivity.csv'),row.names=FALSE)
old<-read.csv('Followup_Validation/reports/graded_responses.csv',stringsAsFactors=FALSE)
old<-old[old$domain=='facts'&old$provider=='minimax'&old$condition%in%c('N0','N1')&old$grade%in%valid,]
hm<-do.call(rbind,lapply(split(old,interaction(old$question_id,old$condition,drop=TRUE)),function(x){
 data.frame(question_id=x$question_id[1],condition=x$condition[1],repeats=nrow(x),
  error=mean(x$grade=='incorrect'),correct=mean(x$grade=='correct'),abstain=mean(x$grade=='abstain'))
}))
write.csv(hm,file.path(out,'historical_question_means.csv'),row.names=FALSE)
comparisons<-list();paired<-list()
for(cond in c('N0','N1')){
 z<-merge(hm[hm$condition==cond,],tab[tab$grade%in%valid,c('question_id','grade')],by='question_id')
 delta<-as.numeric(z$grade=='incorrect')-z$error
 set.seed(25011005);boot<-replicate(5000,100*mean(sample(delta,length(delta),replace=TRUE)))
 ci<-quantile(boot,c(.025,.975),names=FALSE)
 comparisons[[cond]]<-data.frame(historical_condition=cond,matched_questions=nrow(z),historical_error_pct=100*mean(z$error),
  web_enabled_error_pct=100*mean(z$grade=='incorrect'),difference_pp=100*mean(delta),ci95_low=ci[1],ci95_high=ci[2])
 paired[[cond]]<-z
}
comparisons<-do.call(rbind,comparisons)
write.csv(comparisons,file.path(out,'historical_comparisons.csv'),row.names=FALSE)
write.csv(do.call(rbind,paired),file.path(out,'historical_pairs.csv'),row.names=FALSE)
clean<-tab[!tab$possible_benchmark_url,]
sens<-summarize(clean,'Exclude possible benchmark/dataset URLs (post hoc)')
write.csv(sens,file.path(out,'benchmark_sensitivity.csv'),row.names=FALSE)
clean_pairs<-do.call(rbind,lapply(c('N0','N1'),function(cond){
 z<-merge(hm[hm$condition==cond,],clean[clean$grade%in%valid,c('question_id','grade')],by='question_id')
 data.frame(historical_condition=cond,matched_questions=nrow(z),historical_error_pct=100*mean(z$error),
  web_enabled_error_pct=100*mean(z$grade=='incorrect'),difference_pp=100*mean(as.numeric(z$grade=='incorrect')-z$error))
}))
write.csv(clean_pairs,file.path(out,'benchmark_sensitivity_comparisons.csv'),row.names=FALSE)
common_ids<-Reduce(intersect,list(hm$question_id[hm$condition=='N0'],hm$question_id[hm$condition=='N1'],tab$question_id[tab$grade%in%valid]))
chart<-rbind(
 data.frame(condition='Historical initial answer',questions=length(common_ids),error_pct=100*mean(hm$error[hm$condition=='N0'&hm$question_id%in%common_ids])),
 data.frame(condition='Historical self-check',questions=length(common_ids),error_pct=100*mean(hm$error[hm$condition=='N1'&hm$question_id%in%common_ids])),
 data.frame(condition='Web-enabled answer',questions=length(common_ids),error_pct=100*mean(tab$grade[tab$question_id%in%common_ids]=='incorrect')))
write.csv(chart,file.path(out,'chart_data.csv'),row.names=FALSE)
if(requireNamespace('ggplot2',quietly=TRUE)){
 chart$condition<-factor(chart$condition,levels=chart$condition)
 p<-ggplot2::ggplot(chart,ggplot2::aes(condition,error_pct,fill=condition))+
  ggplot2::geom_col(width=.6)+ggplot2::geom_text(ggplot2::aes(label=sprintf('%.2f%%',error_pct)),vjust=-.5,size=5)+
  ggplot2::scale_y_continuous(limits=c(0,100),breaks=seq(0,100,20))+
  ggplot2::scale_fill_manual(values=c('#8191A2','#536B85','#147E77'),guide='none')+
  ggplot2::labs(title='MiniMax: factual error rates with web access',x=NULL,y='Wrong answers (%)',
   subtitle=sprintf('Same %d questions; historical repeated answers averaged within question',length(common_ids)),
   caption='Historical comparison, not a randomized trial. Web enabled does not mean search was used on every question.')+
  ggplot2::theme_minimal(base_size=12)
 ggplot2::ggsave(file.path(out,'error_rates.png'),p,width=9,height=5,dpi=160,bg='white')
}
write.csv(tab[tab$grade=='incorrect',],file.path(out,'wrong_answers.csv'),row.names=FALSE)
probes<-lapply(list.files(file.path(WROOT,'probe'),pattern='json$',full.names=TRUE),read_json)
probe_in<-sum(vapply(probes,function(p)sum(unlist(p$response$usage[c('input_tokens','cache_creation_input_tokens','cache_read_input_tokens')])),0))
probe_out<-sum(vapply(probes,function(p)p$response$usage$output_tokens%||%0,0))
probe_search<-sum(vapply(probes,function(p)sum(vapply(p$response$content,function(b)identical(b$type,'server_tool_use'),TRUE)),0))
usage<-list(attempts=length(rr),questions=length(last),input_tokens=sum(vapply(rr,function(r)r$input_tokens%||%0,0)),
 output_tokens=sum(vapply(rr,function(r)r$output_tokens%||%0,0)),search_calls=sum(vapply(rr,function(r)r$search_calls%||%0,0)),
 guard_cny=sum(vapply(rr,function(r)r$guard_cny,0)),probe_input_tokens=probe_in,probe_output_tokens=probe_out,
 probe_search_calls=probe_search,probe_guard_cny=(probe_in*20+probe_out*50)/1e6+probe_search*.08,
 cash_price='Unknown HKU course quota pricing; guard is not an invoice')
write_json(usage,file.path(out,'usage.json'))
stopifnot(all(stats$questions==stats$correct+stats$wrong+stats$abstain+stats$unscorable),
 stats$questions[2]+stats$questions[3]==100L,all(tab$question_id%in%field(qs,'question_id')))
for(r in last)stopifnot(identical(r$request,wrequest(qi[[r$question_id]],read_json(file.path(WROOT,'protocol/model.json')))))
write_json(list(passed=TRUE,checks=c('100 frozen question IDs','planned request reconstruction without gold',
 'freeze hashes unchanged','attempt-response completeness','outcome totals','search/no-search partition'),
 response_sha256=file_sha(file.path(WROOT,'runs/responses.jsonl'))),file.path(out,'validation.json'))
lines<-c('# MiniMax：100道事实题允许联网后的结果','',
 '本轮为每题一次的联网补充测试。固定原100道日期事实题，MiniMax-M3、温度0.6、thinking disabled、最多768输出token，经原HKU接口启用原生web_search。没有提供参考答案、旧答案或另一模型建议。','',
 '|分组|题数|正确|错误|弃答|不可判分|错误率（可判分分母）|',
 '|---|---:|---:|---:|---:|---:|---:|')
labels<-c('允许联网：全部题目','实际观察到搜索调用','未观察到搜索调用')
for(i in 1:3){s<-stats[i,];lines<-c(lines,sprintf('|%s|%d|%d|%d|%d|%d|%.2f%%|',labels[i],s$questions,s$correct,s$wrong,s$abstain,s$unscorable,s$error_pct))}
lines<-c(lines,'','“允许联网”不等于每题实际搜索。主结果保留全部题目；后两个子组是模型自行选择行为后的描述，不能当作随机对照来证明搜索的因果收益。引用链接但无搜索记录，不算已搜索。',
 'Codex事后逐读全部3条不可判分回答：均表达无法回答；分别为未用JSON、reason为空、abstain使用字符串。原字段评分不变。将三条按语义归为弃答的敏感性结果为63正确、21错误、16弃答，错误率21/100=21%。这是AI复核，不冒充独立人工标注。详见 format_semantic_audit.csv。',
 sprintf('全部100题的已观察错误占比为 %.2f%%；将不可判分全部视为错误时为 %.2f%%，作为缺失范围而非主评分。',stats$wrong[1],stats$wrong[1]+stats$unscorable[1]),'',
 '## 同题历史对照','',
 '旧回答先对每题有效重复取平均；新组每题一次。每行使用两组都可判分的相同题目。历史N1不额外要求旧N2有效，因此与此前N1/N2配对表的覆盖及均值可能略有差别。','',
 '|旧条件|共同题数|旧错误率|联网组错误率|差值（百分点）|95%题目bootstrap区间|',
 '|---|---:|---:|---:|---:|---|')
for(i in seq_len(nrow(comparisons))){s<-comparisons[i,];lines<-c(lines,sprintf('|%s|%d|%.2f%%|%.2f%%|%+.2f|[%.2f, %.2f]|',
 if(s$historical_condition=='N0')'不联网独立初答N0'else'不联网自行复核N1',s$matched_questions,s$historical_error_pct,s$web_enabled_error_pct,s$difference_pp,s$ci95_low,s$ci95_high))}
lines<-c(lines,'','这是历史对照，不是同期随机控制试验。新增工具、查证提示、资料和调用时间一起改变；尤其N1还涉及不同回答流程。不能把差值全归因于联网，也不能直接推论跨模型复核有效。区间只描述本题集抽样不确定性，不能消除这些混杂。','',
 '## 搜索与来源核查','',
  sprintf('共记录 %d 次正式搜索调用，%d 题返回至少一个来源URL；%d 题的理由包含返回来源的完整URL。%d 题返回的URL命中基准/项目副本风险关键词，需核对，关键词检查不能保证无污染。',sum(tab$search_calls),sum(tab$returned_sources>0),sum(tab$returned_source_url_in_reason),sum(tab$possible_benchmark_url)),
 sprintf('事后敏感性：保守排除所有命中基准或数据集URL风险的题目后，保留%d题，正确%d、错误%d、弃答%d、不可判分%d，错误率%.2f%%。匹配历史对照另存 benchmark_sensitivity_comparisons.csv；原100题结果保留。',sens$questions,sens$correct,sens$wrong,sens$abstain,sens$unscorable,sens$error_pct),
 '逐题原文见 answers.csv，全部返回来源见 sources.csv，查询见 queries.csv；请求、搜索内容块和原始回答见 ../runs/responses.jsonl。最终字段正确不代表解释与引用均已逐项独立验证。','',
 '## 用量与复现','',sprintf('正式请求%d次，输入token %d，输出token %d，保守token/搜索估价 %.4f 元。两次预检估价 %.4f 元另列。HKU现金费用未知，估价不是账单。',usage$attempts,usage$input_tokens,usage$output_tokens,usage$guard_cny,usage$probe_guard_cny),
 '全部处理用R；复算命令：`Rscript Web_Factcheck_100/R/analyse.R`。冻结文件、请求重建及数量检查已通过。统计表为事后补充，不替换旧冻结结果。')
writeLines(lines,file.path(out,'结果说明.md'),useBytes=TRUE)
print(stats);print(comparisons);print(usage)
