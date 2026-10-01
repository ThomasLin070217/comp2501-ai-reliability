#!/usr/bin/env Rscript
# Post-result audit only. Never edits frozen inputs or main_r outputs.
args <- commandArgs(trailingOnly = FALSE)
self <- normalizePath(sub('^--file=', '', args[grepl('^--file=', args)][1]))
root <- dirname(dirname(self))
source(file.path(root, 'R/core.R'))
extra <- commandArgs(trailingOnly = TRUE)
out <- if (length(extra)) extra[1] else file.path(root, 'reports/key_review_r')
if (dir.exists(out) && length(list.files(out, all.files = TRUE, no.. = TRUE))) stop('Output must be new/empty; preserve completed reviews.')
dir.create(out, recursive = TRUE, showWarnings = FALSE)
for (d in c('reviewer', 'coordinator')) dir.create(file.path(out, d))
base <- file.path(root, 'reports/main_r')
a <- read.csv(file.path(base, 'analysis_data.csv'), stringsAsFactors = FALSE)
c <- read.csv(file.path(base, 'cells.csv'), stringsAsFactors = FALSE)
harm <- c$baseline == 'correct' & c$C2 == 'incorrect'
loss <- c$baseline == 'incorrect' & c$C4 == 'correct' & c$C5 != 'correct'
gain <- c$baseline == 'incorrect' & c$C4 != 'correct' & c$C5 == 'correct'
selected <- c[harm | loss | gain, ]
selected$selection <- ifelse(harm[harm | loss | gain], 'C2_harm', ifelse(loss[harm | loss | gain], 'C5_repair_loss', 'C5_repair_gain'))
full <- a[a$cell_id %in% selected$cell_id, ]
# All seven responses for the three harm cases; baseline/C4/C5 for both repair directions.
focus <- full[full$cell_id %in% c$cell_id[harm] | full$condition %in% c('baseline','C4','C5'), ]
hid <- function(x, prefix) paste0(prefix, substr(vapply(x, function(s) digest::digest(s, algo='sha256',serialize=FALSE), ''), 1, 12))
focus$packet_id <- hid(paste0('COMP2501-key-review-v1:', focus$task_id), 'R-')
focus$source_id <- hid(paste0('COMP2501-source-v1:', focus$question_id), 'Q-')
focus <- focus[order(focus$packet_id), ]
stopifnot(!anyDuplicated(focus$packet_id), nrow(focus)==216, nrow(full)==476, nrow(selected)==68)
csv <- function(x, path) write.csv(x,file.path(out,path),row.names=FALSE,na='',fileEncoding='UTF-8')
csv(selected,'coordinator/case_index.csv')
csv(full,'coordinator/all_seven_branches.csv')
csv(focus,'coordinator/response_mapping.csv')
packet <- focus[,c('packet_id','source_id','question','response_text')]
for (col in c('reviewer_id','extracted_answer','response_kind','answer_reason_conflict','reason_fact_issue','proposed_grade','evidence_url','notes','completed_at')) packet[[col]] <- ''
csv(packet,'reviewer/responses_to_review.csv')
q <- focus[!duplicated(focus$source_id),c('source_id','question','reference_answer','source_url')]
q <- q[order(q$source_id),]
for (col in c('reviewer_id','source_verdict','verified_answer','independent_source_url','brief_evidence','notes','completed_at')) q[[col]] <- ''
csv(q,'reviewer/sources_to_review.csv')
stats <- list(harm_cells=sum(harm), repair_loss_cells=sum(loss), repair_gain_cells=sum(gain),
  loss_to_abstain=sum(loss & c$C5=='abstain'),loss_to_incorrect=sum(loss & c$C5=='incorrect'),
  gain_from_abstain=sum(gain & c$C4=='abstain'),gain_from_incorrect=sum(gain & c$C4=='incorrect'),
  both_repair=sum(c$baseline=='incorrect' & c$C4=='correct' & c$C5=='correct'),
  selected_cells=nrow(selected),selected_questions=nrow(q),focused_responses=nrow(focus),full_responses=nrow(full),
  independent_human_review_complete=FALSE,selection_timing='post-result; purpose-selected, not a random audit sample')
write_json(stats,file.path(out,'summary.json'))
variants <- list(primary_reference=c,
  posthoc_exclude_Wood_River=c[c$question_id!='SV3593',],
  posthoc_exclude_Arch_Linux=c[c$question_id!='SV3691',],
  posthoc_exclude_both_source_questions=c[!c$question_id %in% c('SV3593','SV3691'),])
alt <- c
alt$C5[alt$cell_id=='SV1199:minimax:r0'] <- 'abstain'
variants$posthoc_reason_conflict_as_abstain <- alt
variants$posthoc_exclude_reason_conflict_question <- c[c$question_id!='SV1199',]
effects <- do.call(rbind,lapply(names(variants),function(v) {
  e <- effect_tables(variants[[v]])
  cbind(variant=v,e[e$provider=='pooled',])
}))
csv(effects,'posthoc_effects.csv')
provenance <- data.frame(file=c('analysis_data.csv','cells.csv'),sha256=vapply(file.path(base,c('analysis_data.csv','cells.csv')),file_sha,''))
csv(provenance,'input_hashes.csv')
writeLines(capture.output(sessionInfo()),file.path(out,'sessionInfo.txt'))
writeLines(c('# 独立复核包：先读说明', '',
 '这是事后定向抽取的关键案例，不是随机质检样本。不能由本包估计全部题目的评分错误率。',
 sprintf('范围：%s 道题、68 个模型–题目–重复单元；216 条重点回答。所有七分支的476条记录另存协调者目录。',nrow(q)),
 '三次初答正确而C2错误的单元全部保留；正确建议下48次失去纠错、17次新增纠错全部保留，不只展示一个方向。', '',
 '## 给复核者',
 '1. 协调者只发送 reviewer/ 文件夹（内含独立说明），不发送本页、coordinator/、统计结果或AI复核笔记。不得假称彻底盲法：回答正文可能泄露提示特征。',
 '2. 先独立填写 responses_to_review.csv 的答案提取、response_kind（answer/abstain/unscorable/ambiguous）及两个解释问题字段（yes/no/uncertain）。第一遍不看来源表，proposed_grade暂留空。',
 '3. 再打开 sources_to_review.csv。参考答案只是待核实基准，不是真值保证。检查原始来源并查官方或独立来源；source_verdict填写supported/conflicting/ambiguous/unavailable，附来源及简短证据。',
 '4. 回填 proposed_grade：correct/incorrect/abstain/unscorable/uncertain。精度按题目年/月/日要求。若答案字段与解释冲突，保留提取值并标冲突，不自行消除歧义。',
 '5. reviewer_id使用可识别的项目内代号，不填敏感身份信息；填写日期与理由。不确定可保留uncertain。两名复核者用各自副本，不互看结论；若只有一名也如实记录。', '',
 '## 给协调者',
 '所有人工判断初始为空。AI准备此包、AI核对来源均不等于人工完成。收齐后按packet_id/source_id联结，保留每人的原始副本；分歧另表裁决，不能覆盖冻结主评分。',
 'coordinator/response_mapping.csv提供原始task_id、条件、历史等级和参考答案；case_index.csv列选择原因。',
 '本轮尚无人工返回，尚未改变正式分数。source-findings.md和posthoc_effects.csv是AI事后调查，不属于预注册或原七种敏感性分析。', '',
 '## R复现',
 '从任意工作目录运行 Rscript /绝对路径/Peer_Misleading_Study/R/prepare_key_review.R /新的空输出目录。默认输出reports/key_review_r；已存在非空目录时停止，避免覆盖人工填写。',
 '来源调查是人工可读的独立文件，不由脚本虚构或联网重建。报告中的准确率仍采用冻结日期评分；解释质量没有预设的量化评分。'),file.path(out,'README.md'))
writeLines(c('# 独立复核填写说明','',
 '请独立判断，不先阅读项目结果或其他复核者的意见。文件已隐藏模型、实验条件和历史评分；回答正文仍可能透露提示特征。',
 '1. 先打开responses_to_review.csv：提取最终答案，response_kind填answer/abstain/unscorable/ambiguous；答案与解释矛盾、解释事实问题各填yes/no/uncertain。此时proposed_grade留空。',
 '2. 再打开sources_to_review.csv：参考答案也可能错误。核对题目实体、事件、日期精度；优先官方与独立资料。source_verdict填supported/conflicting/ambiguous/unavailable，记录verified_answer、来源URL及简短证据。',
 '3. 回填响应proposed_grade：correct/incorrect/abstain/unscorable/uncertain。原任务只评分最终日期，解释附带问题单列；若答案与弃答措辞冲突，保留冲突并说明。',
 '4. 不修改packet_id、source_id、题目、原始回答和给定来源。填写项目内reviewer_id与日期；不要填写敏感身份信息。每位复核者使用独立副本，不互看结论。',
 '5. 无法确认可填uncertain，不强行猜。完成后交回两张表，协调者另行记录分歧，不覆盖原评分。',
 '此包用于定向关键案例复核，不代表全量随机审核。所有判断栏初始为空；AI准备材料不等于人工审核完成。'),file.path(out,'reviewer/README.md'))
print(stats)
