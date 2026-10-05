# User-requested descriptive reaggregation. Run from repository root.
# Keep frozen grades and the existing N2-N1 matched sample unchanged.
root <- 'Followup_Validation/reports'
cells <- read.csv(file.path(root, 'cells.csv'), stringsAsFactors = FALSE)
pairs <- read.csv(file.path(root, 'paired_outcomes.csv'), stringsAsFactors = FALSE)
valid <- c('correct', 'incorrect', 'abstain')
z <- cells[cells$N1 %in% valid & cells$N2 %in% valid, ]
p <- pairs[pairs$comparison == 'N2-N1', ]
stopifnot(!anyDuplicated(z$cell_id), setequal(z$cell_id, p$cell_id))
p <- p[match(z$cell_id, p$cell_id), ]
stopifnot(identical(z$N1, p$left), identical(z$N2, p$right))
stopifnot(sum(z$domain == 'facts') == 578L,
          sum(z$domain == 'mathematics') == 199L)

# First average available repeated binary error indicators within each question/model.
q <- do.call(rbind, lapply(split(z, interaction(z$domain, z$provider, z$question_id,
                                             drop = TRUE)), function(x) {
  stopifnot(nrow(x) %in% 1:2, !anyDuplicated(x$repeat_id))
  data.frame(domain = x$domain[1], provider = x$provider[1],
             question_id = x$question_id[1], repeats = nrow(x),
             self_error = mean(x$N1 == 'incorrect'),
             cross_error = mean(x$N2 == 'incorrect'))
}))
rownames(q) <- NULL
models <- c('deepseek', 'kimi', 'minimax')
out <- do.call(rbind, lapply(c('facts', 'mathematics'), function(d) {
  do.call(rbind, lapply(models, function(m) {
    x <- q[q$domain == d & q$provider == m, ]
    planned <- length(unique(cells$question_id[cells$domain == d & cells$provider == m]))
    data.frame(domain = d, provider = m, planned_questions = planned,
      questions = nrow(x), two_repeats = sum(x$repeats == 2),
      one_repeat = sum(x$repeats == 1), no_valid_pair = planned - nrow(x),
      paired_records = sum(x$repeats),
      self_error_pct = 100 * mean(x$self_error),
      cross_error_pct = 100 * mean(x$cross_error),
      difference_pp = 100 * mean(x$cross_error - x$self_error))
  }))
}))
avg <- do.call(rbind, lapply(split(out, out$domain), function(x) {
  stopifnot(nrow(x) == 3L)
  data.frame(domain = x$domain[1], models = 3,
    self_error_pct = mean(x$self_error_pct),
    cross_error_pct = mean(x$cross_error_pct),
    difference_pp = mean(x$difference_pp))
}))
# Independent weighted-record calculation must recover each question-equal estimate.
for (i in seq_len(nrow(out))) {
  x <- z[z$domain == out$domain[i] & z$provider == out$provider[i], ]
  w <- 1 / as.numeric(table(x$question_id)[x$question_id])
  stopifnot(abs(100 * weighted.mean(x$N1 == 'incorrect', w) - out$self_error_pct[i]) < 1e-10,
            abs(100 * weighted.mean(x$N2 == 'incorrect', w) - out$cross_error_pct[i]) < 1e-10)
}
dest <- file.path(root, 'equal_weight')
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
write.csv(q, file.path(dest, 'question_means.csv'), row.names = FALSE)
write.csv(out, file.path(dest, 'model_summary.csv'), row.names = FALSE)
write.csv(avg, file.path(dest, 'three_model_average.csv'), row.names = FALSE)
lines <- c('# 按题目、模型等权汇总错误率', '',
  '2026-10-05。用户要求的事后描述性汇总，保留原冻结评分及原主分析。', '',
  '范围：最新 Followup_Validation 自然复核实验。沿用 N1/N2 均可判分的配对记录（事实578、数学199）；不混入旧轮次或受控错误建议实验。', '',
  '错误记1，正确和明确弃答记0。先对同一模型同一道题的有效重复取平均，再对该模型有效题目等权平均，最后对三个模型等权平均。正确与弃答记0仅针对错误指标，不代表两者使用价值相同。', '',
  '一次对、一次错对应该题50%错误率；两次错为100%。只有一次有效配对时使用该次，不把缺失记0；无有效配对的题目不进入均值。两种方法使用完全相同的记录，但不同模型的有效题目覆盖不完全一致，不能据此作无条件的模型排名。', '',
  '|题型|模型|有效题数|两次有效/仅一次有效/无有效配对|自行复核错误率|交叉复核错误率|交叉减自行（百分点）|',
  '|---|---|---:|---|---:|---:|---:|')
names_m <- c(deepseek = 'DeepSeek', kimi = 'Kimi', minimax = 'MiniMax')
for (d in c('facts', 'mathematics')) {
  label <- if (d == 'facts') '日期事实题' else '数学题'
  for (i in which(out$domain == d)) {
    a <- out[i, ]
    lines <- c(lines, sprintf('|%s|%s|%d/%d|%d / %d / %d|%.2f%%|%.2f%%|%+.2f|',
      label, names_m[a$provider], a$questions, a$planned_questions,
      a$two_repeats, a$one_repeat, a$no_valid_pair,
      a$self_error_pct, a$cross_error_pct, a$difference_pp))
  }
  a <- avg[avg$domain == d, ]
  lines <- c(lines, sprintf('|%s|**三模型等权平均**|—|—|**%.2f%%**|**%.2f%%**|**%+.2f**|',
    label, a$self_error_pct, a$cross_error_pct, a$difference_pp))
}
lines <- c(lines, '',
  '与原报告差别：原报告直接按回答次数加权，本表先按题目再按模型等权。缺失重复会导致数值略变。这一重新加权不是新增实验，也不消除缺失偏差。旧置信区间不直接套用于新均值；本表不新增显著性或稳定收益结论。', '',
  '来源：[原配对数据](../paired_outcomes.csv)、[单元评分](../cells.csv)。复算：在仓库根目录运行 `Rscript Followup_Validation/R/equal_weight_summary.R`。', '',
  '明细：[逐题平均](question_means.csv)、[分模型汇总](model_summary.csv)、[三模型平均](three_model_average.csv)。')
writeLines(lines, file.path(dest, 'README.md'), useBytes = TRUE)
print(out, row.names = FALSE)
print(avg, row.names = FALSE)
cat('Matched-sample and independent weighted-calculation checks passed.\n')
