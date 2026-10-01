#!/usr/bin/env Rscript
# All selection, extraction and display-data preparation is performed in R.
# The separate JS workbook renderer only writes and styles these prepared cells.
self <- normalizePath(sub('^--file=', '', grep('^--file=', commandArgs(), value=TRUE)[1]))
root <- dirname(dirname(self)); source(file.path(root,'R/core.R'))
args <- commandArgs(trailingOnly=TRUE)
out <- if(length(args)) args[1] else file.path(root,'reports/readable_review')
if(dir.exists(out) && length(list.files(out))) stop('Use a new empty directory; never overwrite reviewer work.')
dir.create(out,recursive=TRUE)
input <- file.path(root,'reports/key_review_r/coordinator/response_mapping.csv')
a <- read.csv(input,stringsAsFactors=FALSE,check.names=FALSE)
# Six priority questions: every C2 harm question, two source controversies,
# and one answer/abstention contradiction. This is a first batch, not a full audit.
priority <- c('SV0013','SV3488','SV3693','SV3691','SV3593','SV1199')
qids <- c(priority,sort(setdiff(unique(a$question_id),priority)))
labels <- setNames(sprintf('Q%02d',seq_along(qids)),qids)
plain <- function(s) {
  z <- parse_json(s); fallback <- ''
  if(is.null(z)) {
    # For the one prose+JSON output, extract the final object but retain all
    # prose in the explanation display and the exact original in the archive.
    start <- regexpr('\\{[[:space:]]*"answer"',s,perl=TRUE)[1]
    if(start>0) z <- parse_json(substr(s,start,nchar(s)))
    if(!is.null(z)) fallback <- substr(s,1,start-1)
  }
  if(is.null(z)) return(c(answer='无法自动拆分，请看解释栏原文',abstain='无法读取',reason=s,mode='raw_fallback'))
  answer <- if(is.null(z$answer)) '[null：无答案值]' else if(identical(z$answer,'')) '[空答案]' else as.character(z$answer)
  abstain <- if(isTRUE(z$abstain)) '是' else if(identical(z$abstain,FALSE)) '否' else '无法读取'
  reason <- z$reason %||% '[未提供解释]'
  if(nzchar(trimws(fallback))) reason <- paste0('JSON之前的文字（原文）：\n',trimws(fallback),'\n\nreason字段（原文）：\n',reason)
  c(answer=answer,abstain=abstain,reason=reason,mode=if(nzchar(fallback)) 'prose_plus_json' else 'json')
}
parts <- t(vapply(a$response_text,plain,c(answer='',abstain='',reason='',mode='')))
d <- data.frame('题号'=unname(labels[a$question_id]),'题目原文'=a$question,
 '模型答案'=parts[,'answer'],'模型声明弃答'=parts[,'abstain'],'解释原文'=parts[,'reason'],
 '你的判定'='','答案与解释矛盾'='','依据或疑点'='','记录编号'=a$packet_id,check.names=FALSE)
d <- d[order(d$题号,d$记录编号),]
first <- d[d$题号 %in% labels[priority],]; rest <- d[!d$题号 %in% labels[priority],]
q <- a[match(qids,a$question_id),]
s <- data.frame('题号'=unname(labels[q$question_id]),'题目原文'=q$question,
 '题库参考答案（待核）'=q$reference_answer,'原始来源'=q$source_url,
 '你的核验'='','核实后的答案'='','你查到的来源'='','简短依据'='',check.names=FALSE)
sf <- s[s$题号 %in% labels[priority],]
csv <- function(x,name) write.csv(x,file.path(out,name),row.names=FALSE,na='',fileEncoding='UTF-8')
csv(first,'第一批_45条回答.csv');csv(sf,'第一批_6道题来源.csv')
csv(rest,'后续_171条回答.csv');csv(s[!s$题号 %in% labels[priority],],'后续_45道题来源.csv')
mapping <- data.frame(packet_id=a$packet_id,source_id=a$source_id,question_id=a$question_id,
 short_id=unname(labels[a$question_id]),parse_mode=parts[,'mode'],stringsAsFactors=FALSE)
csv(mapping,'coordinator_mapping.csv')
# Exact mechanical extraction checks, not a new semantic grade.
for(i in seq_len(nrow(a))) {
 z<-parse_json(a$response_text[i]);if(!is.null(z)) {
  if(is.character(z$answer)&&nzchar(z$answer)) stopifnot(identical(parts[i,'answer'],z$answer))
  if(is.character(z$reason)) stopifnot(identical(parts[i,'reason'],z$reason))
 }
}
stopifnot(nrow(first)==45,nrow(sf)==6,nrow(rest)==171,!anyDuplicated(d$记录编号),
 setequal(d$记录编号,a$packet_id),all(first$你的判定==''),all(sf$你的核验==''))
matrix_rows <- function(x) unname(lapply(seq_len(nrow(x)),function(i)unname(as.list(x[i,]))))
# Row heights are prepared in R, using conservative wrapped-line estimates.
heights <- function(x,chars) vapply(seq_len(nrow(x)),function(i) {
  lines <- vapply(seq_len(ncol(x)),function(j)sum(pmax(1,ceiling(nchar(strsplit(as.character(x[i,j]),'\n',fixed=TRUE)[[1]])/chars[j]))),0)
  max(64, 18*max(lines)+12)
},0)
payload <- list(sheets=list(
 list(name='1_核对来源',headers=names(sf),rows=matrix_rows(sf),widths=c(65,320,130,260,125,125,260,260),
      heights=heights(sf,c(8,42,16,32,15,15,32,32)),editable='E8:H13',last_col='H',
      title='先核对这6道题的参考答案',note='黄色格由你填写。参考答案待核实；来源冲突或题意不清时如实标记。',
      detail='核验：来源支持 / 来源冲突 / 题意不清 / 找不到。附你实际查看的网页与简短依据。',
      validation=list(list(range='E8:E13',values=c('来源支持','来源冲突','题意不清','找不到')))),
 list(name='2_判断回答',headers=names(first),rows=matrix_rows(first),widths=c(65,260,115,95,430,120,115,250,150),
      heights=heights(first,c(8,34,14,11,58,14,14,32,18)),editable='F8:H52',last_col='I',
      title='再判断这45条模型回答',note='只填黄色格。日期答案按题目要求核对；解释里的其他问题写在依据或疑点。',
      detail='判定：答案正确 / 答案错误 / 明确弃答 / 无法判定。答案与解释冲突时另标，不凭语气评分。',
      validation=list(list(range='F8:F52',values=c('答案正确','答案错误','明确弃答','无法判定')),list(range='G8:G52',values=c('是','否','不确定'))))))
write_json(payload,file.path(out,'workbook_payload.json'))
write_json(list(input_sha256=file_sha(input),responses=216,priority_responses=45,priority_questions=6,
 remaining_responses=171,remaining_questions=45,parse_modes=as.list(table(parts[,'mode'])),
 original_answers_and_reasons_preserved=TRUE,review_fields_blank=TRUE,
 primary_scores_changed=FALSE,independent_human_review_complete=FALSE),file.path(out,'verification.json'))
writeLines(c('# 人工复核：先做第一批','',
 '打开仓库outputs/01a0e6a9-review/COMP2501_人工复核.xlsx。先做6道题的来源核查，再评45条回答；黄色格为填写区域。每人复制一份，分别填写。',
 '这次评测是核对实验标签，不是重新让AI答题，也不是给模型文风或聪明程度打分。',
 '## 你需要填写什么',
 '来源表：选择来源支持、来源冲突、题意不清或找不到；记录核实后的答案、你实际查看的网页及一句依据。题库参考答案只是待核查值。',
 '回答表：选择答案正确、答案错误、明确弃答或无法判定；再判断答案与解释是否矛盾。依据或疑点用一句话写明，正常情况也可注明对应题号的已核来源。',
 '答案正确：最终日期与查证结果一致，并满足题目要求的年/月/日精度。答案错误：给出明确日期且与查证结果不符。明确弃答：明确不提供确定答案。无法判定：来源冲突、题意不清、答案与弃答冲突等使评分无法确定。',
 '模型声明弃答是原始abstain字段的中文显示，并非已替你做了判断。字段与文字矛盾时标“是”，必要时判“无法判定”。正确日期配了错误背景解释，也不要默默把原日期指标改成全段正确性指标；在疑点记录。',
 '不需要上网验证解释里每一个附带事实，不做1至5分的主观打分，不需要运行API。保留题号与记录编号不改。每个工作表顶部填审阅者代号和日期。',
 '## 范围与后续',
 '第一批6题45条是优先队列，不是全量复核；做完才能如实写完成该批。其余45题171条已另存中文CSV，可分批继续。第一批不能代表全样本准确率或全量标签质量。',
 '模型名、条件及旧分数未放进工作簿；正文仍可能泄露条件，因此不是完全盲法。原始216条CSV及采集日志保持原样。此批次没有新增模型回答。',
 '解析规则：标准JSON去掉外层代码围栏后拆字段，原解释不改写；null与空串分别显示。文字加JSON的非标准回答保留额外文字，不丢弃。',
 '## 复现',
 '所有筛选、JSON拆分、排序、数据导出和内容验证均由R/prepare_readable_review.R完成。JS仅将R准备的单元格值排版为Excel，不负责判分、筛选或统计。',
 '运行：Rscript Peer_Misleading_Study/R/prepare_readable_review.R NEW_EMPTY_DIRECTORY。工作簿排版脚本在tools/render_review_workbook.mjs。',
 '工作簿与表格留空人工结论，不把AI准备工作标成人工已审。'),file.path(out,'README.md'))
cat('Prepared 6 source questions and 45 priority responses; 171 responses kept for later.\n')
