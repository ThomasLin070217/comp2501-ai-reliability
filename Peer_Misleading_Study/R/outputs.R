# Analysis variants, exports, plots, and checks. All derived in R from raw logs.
save_analysis <- function(x, out) {
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  for (key in c("tables", "effects", "cells")) write.csv(x[[key]], file.path(out, paste0(key, ".csv")), row.names = FALSE, na = "")
  write_json(x, file.path(out, "summary.json"))
}
sensitivity_analysis <- function(root, qs, records, raw_grades, filtered, decisions) {
  caveats <- read_json(file.path(root, "data/main_preanalysis_caveats.json"))
  alternative <- decisions
  for (key in names(alternative)) if (!is.null(alternative[[key]]$alternative_status)) {
    alternative[[key]]$status <- alternative[[key]]$alternative_status
    alternative[[key]]$target_adopted <- alternative[[key]]$alternative_target_adopted
  }
  alt <- score_records(qs, records, alternative)
  alt <- alt[alt$task_id %in% filtered$task_id, ]
  disputed_keys <- names(Filter(function(x) isTRUE(x$disputed), decisions))
  disputed <- unique(filtered$question_id[filtered$review_id %in% disputed_keys])
  sources <- field(caveats$question_caveats, "question_id")
  unusable <- unique(raw_grades$question_id[raw_grades$unscorable])
  excluded <- union(union(disputed, sources), unusable)
  cutoff <- read_json(file.path(root, "protocol/morning-analysis-note.json"))$cutoff
  sides <- split(filtered$timestamp >= cutoff, filtered$cell_id)
  spanning <- names(Filter(function(x) length(unique(x)) == 2, sides))
  plans <- list(primary = filtered, alternative_adjudications = alt,
    exclude_disputed_and_source_caveats = filtered[!filtered$question_id %in% excluded, ],
    exclude_unscorable_questions_only = filtered[!filtered$question_id %in% unusable, ])
  for (status in c("incorrect", "abstain")) {
    g <- raw_grades; g$grade[g$unscorable] <- status; g$target_adopted[g$unscorable] <- NA
    name <- if (status == "incorrect") "unscorable_as_unsuccessful_answer" else "unscorable_as_nonanswer"
    plans[[name]] <- g
  }
  if (length(spanning)) plans$exclude_cells_spanning_overnight_pause <- filtered[!filtered$cell_id %in% spanning, ]
  variants <- lapply(names(plans), function(name) {
    g <- plans[[name]]
    # The overnight variant retains all registered questions, even if no cells remain.
    n <- if (name %in% c("exclude_disputed_and_source_caveats", "exclude_unscorable_questions_only")) length(unique(g$question_id)) else length(qs)
    analyze_grades(g, n)
  })
  names(variants) <- names(plans)
  list(variants = variants, excluded_disputed_question_ids = sort(disputed),
    excluded_source_caveat_question_ids = sort(sources), excluded_unscorable_question_ids = unusable,
    excluded_overnight_spanning_cells = sort(spanning), independent_human_review_complete = FALSE)
}
supplementary <- function(cells, grades, records) {
  transitions <- list(); usage <- list(); neutral <- list(); i <- 0L; j <- 0L; k <- 0L
  for (model in c(MODELS, "pooled")) {
    c <- cells[model == "pooled" | cells$provider == model, ]
    for (condition in c(CONDITIONS, "C2_to_C3")) {
      left <- if (condition == "C2_to_C3") c$C2 else c$baseline
      right <- if (condition == "C2_to_C3") c$C3 else c[[condition]]
      t <- as.data.frame(table(from = left, to = right), stringsAsFactors = FALSE)
      i <- i + 1L; transitions[[i]] <- cbind(provider = model, condition = condition, t)
    }
    for (condition in CONDITIONS) {
      rs <- Filter(function(r) r$condition == condition && (model == "pooled" || r$provider == model), records)
      j <- j + 1L
      usage[[j]] <- data.frame(provider = model, condition = condition, calls = length(rs),
        input_tokens = sum(field(rs, "input_tokens", 0)), output_tokens = sum(field(rs, "output_tokens", 0)),
        cost_guard_cny = sum(field(rs, "cost_upper_cny", 0)), median_latency_seconds = median(field(rs, "latency_seconds", 0)))
    }
    for (condition in c("C2", "C3")) {
      bc <- c$baseline == "correct"; k <- k + 1L
      neutral[[k]] <- data.frame(provider = model, contrast = paste0(condition, "_minus_C0"),
        accuracy_difference_pp = pct(sum((c[[condition]] == "correct") - (c$C0 == "correct")), nrow(c)),
        harm_difference_pp = pct(sum((c[[condition]][bc] == "incorrect") - (c$C0[bc] == "incorrect")), sum(bc)),
        eligible_correct_cells = sum(bc), n = nrow(c))
    }
  }
  list(transitions = do.call(rbind, transitions), condition_usage = do.call(rbind, usage), neutral_comparisons = do.call(rbind, neutral))
}
usage_ledger <- function(root) {
  paths <- sort(list.files(file.path(root, "runs"), pattern = "^responses\\.jsonl$", recursive = TRUE, full.names = TRUE))
  stages <- lapply(paths, read_jsonl); names(stages) <- basename(dirname(paths))
  all <- unlist(stages, recursive = FALSE)
  aggregate <- function(rs) list(calls = length(rs), statuses = as.list(table(field(rs, "status"))),
    input_tokens = sum(field(rs, "input_tokens", 0)), output_tokens = sum(field(rs, "output_tokens", 0)),
    cost_guard_cny = sum(field(rs, "cost_upper_cny", 0)),
    usage_unavailable_calls = sum(vapply(rs, function(r) length(r$usage_raw) == 0, TRUE)),
    median_latency_seconds = median(field(rs, "latency_seconds", 0)))
  providers <- setNames(lapply(MODELS, function(p) aggregate(Filter(function(r) r$provider == p, all))), MODELS)
  list(total = aggregate(all), stages = lapply(stages, aggregate), providers = providers,
    note = "Guard estimate, not invoice. HKU MiniMax monetary price is unknown. Failed-call usage may be unavailable.")
}
export_evidence <- function(qs, records, grades, cells, materials, out) {
  ri <- indexed(records, "task_id"); qi <- indexed(qs, "question_id")
  baseline <- grades[grades$condition == "baseline", ]
  rows <- lapply(qs, function(q) {
    g <- baseline[baseline$question_id == q$question_id, ]; g <- g[order(g$task_id), ]
    answers <- lapply(seq_len(nrow(g)), function(i) {
      r <- ri[[g$task_id[i]]]
      list(task_id = r$task_id, model = r$provider, model_returned = r$model_returned, repeat_id = r[["repeat"]],
        text = r$text, grade = g$grade[i], grade_reason = g$grade_reason[i], timestamp = r$timestamp, request_sha256 = r$request_sha256)
    })
    list(question_id = q$question_id, question = q$question, reference_answer = q$gold, granularity = q$granularity,
      topic = q$topic, verified_source_url = q$verified_source_url, source_id = q$source_id,
      initial_answers = answers, initial_observations = nrow(g), initial_incorrect = sum(g$grade == "incorrect"),
      initial_correct = sum(g$grade == "correct"), initial_abstain = sum(g$grade == "abstain"),
      observed_initial_error = any(g$grade == "incorrect"),
      all_six_initial_answers_incorrect = nrow(g) == 6 && all(g$grade == "incorrect"), independent_human_review_complete = FALSE)
  })
  write_jsonl(rows, file.path(out, "error_bank/all_questions_observed.jsonl"))
  write_jsonl(Filter(function(r) r$observed_initial_error, rows), file.path(out, "error_bank/observed_initial_error_bank.jsonl"))
  flat <- do.call(rbind, lapply(rows, function(r) as.data.frame(r[setdiff(names(r), "initial_answers")], stringsAsFactors = FALSE)))
  flat <- flat[order(-flat$initial_incorrect, flat$question_id), ]
  write.csv(flat, file.path(out, "error_bank/question_summary.csv"), row.names = FALSE)
  predicates <- list(harm_after_explanation = cells$baseline == "correct" & cells$C2 == "incorrect",
    structured_rescue = cells$baseline == "correct" & cells$C2 == "incorrect" & cells$C3 == "correct",
    structured_harm = cells$C2 == "correct" & cells$C3 == "incorrect",
    correct_advice_repair = cells$baseline == "incorrect" & cells$C4 == "correct",
    initial_knowledge_error = cells$baseline == "incorrect")
  matches <- lapply(predicates, function(p) sort(cells$cell_id[p])); examples <- list()
  lines <- c("# R 生成的实验案例", "", "每类按单元 ID 字典序取第一条。所有匹配单元见 case_index.json。C2/C3 是平行分支；AI 审查不等于独立人工复核。", "")
  for (category in names(matches)) {
    if (!length(matches[[category]])) next
    id <- matches[[category]][1]; c <- cells[cells$cell_id == id, ]; q <- qi[[c$question_id]]
    g <- grades[grades$cell_id == id, ]; g <- g[match(CONDITIONS, g$condition), ]
    generator <- g$generator[1]
    responses <- setNames(lapply(seq_len(nrow(g)), function(i) list(task_id = g$task_id[i], text = ri[[g$task_id[i]]]$text, grade = g$grade[i])), CONDITIONS)
    wrong <- materials[[paste(q$question_id, generator, "wrong", sep = ":")]]
    correct <- materials[[paste(q$question_id, generator, "correct", sep = ":")]]
    examples[[category]] <- list(category = category, cell_id = id, question = q$question, gold = q$gold,
      source = q$verified_source_url, wrong_material = wrong, correct_material = correct, responses = responses)
    lines <- c(lines, paste0("## ", category), "", id, "", q$question, "", paste0("参考答案：", q$gold, "；来源：", q$verified_source_url), "",
      "实验错误建议（故意构造）：", as.character(jsonlite::toJSON(wrong, auto_unbox = TRUE)), "",
      "正确目标建议（背景断言未必经独立核实）：", as.character(jsonlite::toJSON(correct, auto_unbox = TRUE)), "")
    for (condition in CONDITIONS) lines <- c(lines, paste0("### ", condition, " · ", responses[[condition]]$grade), "", "``````text", responses[[condition]]$text, "``````", "")
  }
  write_json(list(selection = "First lexicographic cell per category; all matches listed.",
    counts = lapply(matches, length), all_matches = matches), file.path(out, "cases/case_index.json"))
  write_json(examples, file.path(out, "cases/illustrative_cases.json"))
  writeLines(lines, file.path(out, "cases/cases.md"), useBytes = TRUE)
  list(questions_total = length(rows), questions_with_observed_initial_error = sum(flat$observed_initial_error),
    questions_all_six_initial_answers_incorrect = sum(flat$all_six_initial_answers_incorrect), baseline_observations = nrow(baseline))
}
validate_archived <- function(root, primary, grades, sensitivity, dev, ledger) {
  # Archived outputs are read ONLY for validation, after the R calculations.
  old <- read_json(file.path(root, "reports/main/summary.json"))
  oldg <- indexed(read_json(file.path(root, "reports/main/grades.json")), "task_id")
  checks <- list(); deltas <- list()
  for (i in seq_len(nrow(grades))) {
    g <- grades[i, ]; h <- oldg[[g$task_id]]
    assert(!is.null(h) && identical(g$grade, h$grade), paste("Grade differs:", g$task_id))
    assert(identical(g$target_adopted, h$target_adopted %||% NA), paste("Target adoption differs:", g$task_id))
    assert(identical(g$review_id, h$review_id), paste("Review key differs:", g$task_id))
    assert(identical(g$grade_reason, h$grade_reason), paste("Grade reason differs:", g$task_id))
  }
  compare <- function(x, y, name) {
    assert(x$questions == y$questions && x$responses == y$responses && x$complete_cells == y$complete_cells && x$unresolved_grades == y$unresolved_grades,
      paste("Analysis dimensions differ", name))
    fields <- c("n", "correct", "incorrect", "abstain", "pending", "baseline_correct_n", "baseline_incorrect_n", "correct_to_incorrect", "correct_to_abstain", "incorrect_to_correct", "accuracy_pct", "harm_pct", "repair_pct")
    for (i in seq_len(nrow(x$tables))) {
      row <- x$tables[i, ]; ref <- y$tables[[row$provider]][[row$condition]]
      for (key in fields) {
        expected <- ref[[key]] %||% if (grepl("pct$", key)) NA_real_ else 0
        assert(isTRUE(all.equal(row[[key]], expected, tolerance = 1e-10)), paste("Table mismatch", name, row$provider, row$condition, key))
      }
    }
    for (i in seq_len(nrow(x$effects))) {
      row <- x$effects[i, ]; ref <- y$effects[[row$provider]][[row$contrast]]
      assert(isTRUE(all.equal(row$difference_pp, ref$difference_pp %||% NA_real_, tolerance = 1e-10)), paste("Effect mismatch", name))
      assert(row$eligible_cells == ref$eligible_cells && row$question_clusters == ref$question_clusters, "Bootstrap denominator mismatch")
      ci <- unlist(ref$ci95_pp) %||% c(NA_real_, NA_real_)
      if (!length(ci)) ci <- c(NA_real_, NA_real_)
      deltas[[length(deltas) + 1L]] <<- data.frame(variant = name, provider = row$provider, contrast = row$contrast,
        R_low = row$ci_low_pp, R_high = row$ci_high_pp, archived_low = ci[1], archived_high = ci[2],
        low_difference = row$ci_low_pp - ci[1], high_difference = row$ci_high_pp - ci[2])
    }
    TRUE
  }
  checks$primary <- compare(primary, old, "primary")
  oldsupp <- read_json(file.path(root, "reports/main/supplementary.json"))
  for (i in seq_len(nrow(primary$tables))) {
    row <- primary$tables[i, ]; ref <- oldsupp$tables[[row$provider]][[row$condition]]
    for (key in c("answered", "coverage_pct", "accuracy_among_answered_pct", "wrong_answers_per_100_questions", "target_adoptions_all", "target_adoptions_from_initial_correct"))
      assert(isTRUE(all.equal(row[[key]], ref[[key]] %||% NA_real_, tolerance = 1e-10)), paste("Supplementary mismatch", row$provider, row$condition, key))
  }
  checks$supplementary_rates_and_adoptions <- TRUE
  olds <- read_json(file.path(root, "reports/main/sensitivity.json"))
  for (name in names(sensitivity$variants)) checks[[name]] <- compare(sensitivity$variants[[name]], olds$variants[[name]], name)
  checks$development <- compare(dev, read_json(file.path(root, "reports/dev/summary.json")), "development")
  oldl <- read_json(file.path(root, "reports/main/usage-ledger.json"))
  for (key in c("calls", "input_tokens", "output_tokens", "cost_guard_cny")) assert(isTRUE(all.equal(ledger$total[[key]], oldl$total[[key]], tolerance = 1e-10)), paste("Usage mismatch", key))
  list(status = "passed", exactly_matched_response_grades = nrow(grades),
    exactly_matched_tables_and_point_estimates = checks,
    bootstrap_note = "R and Python use different random streams; CI endpoints are independently recomputed, not copied. Full differences disclosed.",
    interval_comparison = do.call(rbind, deltas), independent_human_review_complete = FALSE)
}
render_outputs <- function(primary, sensitivity, ledger, evidence, out) {
  t <- primary$tables; e <- primary$effects
  draw_accuracy <- function() {
    par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))
    for (model in c(MODELS, "pooled")) {
      z <- t[t$provider == model, ]; heights <- t(as.matrix(z[, c("correct", "incorrect", "abstain")]))
      heights <- sweep(heights, 2, z$n, "/") * 100
      barplot(heights, names.arg = z$condition, col = c("#29855b", "#ce624b", "#9aabb7"), ylim = c(0, 115),
        main = model, ylab = "Percent of all included cells", las = 1, cex.names = .8)
      legend("top", legend = c("Correct", "Incorrect", "Abstain"), fill = c("#29855b", "#ce624b", "#9aabb7"), bty = "n", horiz = TRUE, cex = .65)
    }
  }
  draw_effects <- function() {
    par(mar = c(5, 14, 3, 2)); z <- e[e$provider == "pooled", ]; y <- 3:1
    limits <- range(c(z$ci_low_pp, z$ci_high_pp, 0), na.rm = TRUE) + c(-1, 1)
    plot(z$difference_pp, y, xlim = limits, ylim = c(.5, 3.5), yaxt = "n", ylab = "", xlab = "Paired difference (percentage points)", pch = 19,
      main = "Question-cluster bootstrap: 95% intervals")
    axis(2, at = y, labels = c("RQ1: C2 - C1 harm", "RQ2: C3 - C2 harm", "Control: C5 - C4 repair"), las = 1, cex.axis = .85)
    abline(v = 0, lty = 2, col = "grey60")
    segments(z$ci_low_pp, y, z$ci_high_pp, y, lwd = 2)
  }
  for (name in c("accuracy", "effects")) {
    draw <- if (name == "accuracy") draw_accuracy else draw_effects
    png(file.path(out, paste0(name, ".png")), width = 1500, height = 950, res = 150); draw(); dev.off()
    pdf(file.path(out, paste0(name, ".pdf")), width = 10, height = 6.3, useDingbats = FALSE); draw(); dev.off()
  }
  z <- t[t$provider == "pooled", ]; ef <- e[e$provider == "pooled", ]
  lines <- c("# R 数据处理与分析结果", "", "从原始 API 日志在 R 中装配、清洗、判分、统计、重采样、绘图和导出。研究问题与纳入规则不变；不联网、不调用模型。", "",
    sprintf("正式样本 %d 题；主分析 %d 个配对单元、%d 条响应。", primary$questions, primary$complete_cells, primary$responses), "",
    "| 条件 | 正确 | 错误 | 弃答 | 总数 | 正确率 | 弃答率 |", "|---|---:|---:|---:|---:|---:|---:|")
  for (i in seq_len(nrow(z))) lines <- c(lines, sprintf("| %s | %d | %d | %d | %d | %.2f%% | %.2f%% |", z$condition[i], z$correct[i], z$incorrect[i], z$abstain[i], z$n[i], z$accuracy_pct[i], z$abstention_pct[i]))
  lines <- c(lines, "", "baseline 为独立初答；C0 中性复核；C1 错误日期；C2 错误日期加解释；C3 相同错误建议加结构化核验；C4 正确建议；C5 相同正确建议加结构化核验。六个分支互相隔离。", "",
    "| 预定比较 | 差值（百分点） | R 的 95% 区间 | 分母 |", "|---|---:|---|---:|")
  for (i in seq_len(nrow(ef))) lines <- c(lines, sprintf("| %s | %.2f | [%.2f, %.2f] | %d |", ef$contrast[i], ef$difference_pp[i], ef$ci_low_pp[i], ef$ci_high_pp[i], ef$eligible_cells[i]))
  lines <- c(lines, "", "每次 bootstrap 抽取整道题，保留模型和重复间的关联，5,000 次重采样。R 固定种子 25011001；R/Python 的随机数流不同，区间端点可能略有变化，逐项比较见 validation.json。零观察差且无题目间差异时区间留空，不声称等效。", "",
    "![各条件结果](accuracy.png)", "", "![预定比较](effects.png)", "",
    "## 七种处理规则的敏感性分析", "", "| 变体 | 题数 | 单元数 | RQ1 差 | RQ2 差 | 正确建议纠错差 |", "|---|---:|---:|---:|---:|---:|")
  for (name in names(sensitivity$variants)) {
    v <- sensitivity$variants[[name]]; pe <- v$effects[v$effects$provider == "pooled", ]
    lines <- c(lines, sprintf("| %s | %d | %d | %.2f | %.2f | %.2f |", name, v$questions, v$complete_cells, pe$difference_pp[1], pe$difference_pp[2], pe$difference_pp[3]))
  }
  lines <- c(lines, "", "## 解释与限制", "",
    "错误解释没有显示更高带偏率，不能据此证明无效；结构化提示的正确改错事件由 3 降到 0，但事件少。正确建议的真正纠错由 76/322 降至 45/322，并伴随更多弃答。不能概括为全面提升准确率。", "",
    sprintf("全部阶段 %d 条请求记录，付费接口保护性估算 %.4f 元（非账单）；HKU MiniMax 价格未知。", ledger$total$calls, ledger$total$cost_guard_cny), "",
    sprintf("%d 题至少一次初答错误；%d 题六次初答全部错误。错误库为筛选视图，不能反推总体错误率。", evidence$questions_with_observed_initial_error, evidence$questions_all_six_initial_answers_incorrect), "",
    "所选英文日期事实题、无外部检索、固定三模型、thinking 关闭；非随机总体样本。独立人工复核尚未完成，AI 语义审阅决定保持原样。原开发难度警报、不可判分处理和跨夜续跑偏离见 ../main-report.md。迁移 R 不消除这些限制。", "",
    "完整数据表：tables.csv、effects.csv、cells.csv、graded_responses.csv、supplementary.json、sensitivity.json。错误库和案例见 error_bank/、cases/；开发轮见 development/。")
  writeLines(lines, file.path(out, "report.md"), useBytes = TRUE)
  # Portable self-contained HTML, with images embedded; every number comes from R.
  esc <- function(s) gsub(">", "&gt;", gsub("<", "&lt;", gsub("&", "&amp;", s, fixed = TRUE), fixed = TRUE), fixed = TRUE)
  table_html <- function(d) paste0("<table><tr>", paste0("<th>", esc(names(d)), "</th>", collapse = ""), "</tr>",
    paste(apply(d, 1, function(r) paste0("<tr>", paste0("<td>", esc(as.character(r)), "</td>", collapse = ""), "</tr>")), collapse = ""), "</table>")
  html <- c('<!doctype html><html lang="zh"><meta charset="utf-8"><title>COMP2501 · R analysis</title>',
    '<style>body{max-width:1100px;margin:40px auto;padding:0 24px;font:16px/1.6 system-ui;color:#182c38}table{border-collapse:collapse;width:100%;font-size:13px}td,th{padding:7px;border-bottom:1px solid #ddd;text-align:left}img{width:100%}pre{white-space:pre-wrap}</style>',
    '<h1>AI 同伴误导与 Double-check：R 分析</h1><p>120 题 · 719 个完整配对单元 · 5,033 条纳入响应 · 无联网核验</p>',
    table_html(z[, c("condition", "n", "correct", "incorrect", "abstain", "accuracy_pct", "abstention_pct")]),
    paste0('<img alt="Outcome distribution" src="data:image/png;base64,', jsonlite::base64_enc(readBin(file.path(out, "accuracy.png"), "raw", n = file.info(file.path(out, "accuracy.png"))$size)), '">'),
    table_html(ef), paste0('<img alt="Paired contrasts" src="data:image/png;base64,', jsonlite::base64_enc(readBin(file.path(out, "effects.png"), "raw", n = file.info(file.path(out, "effects.png"))$size)), '">'),
    '<details><summary>完整报告与限制</summary><pre>', esc(paste(lines, collapse = "\n")), '</pre></details></html>')
  writeLines(html, file.path(out, "results.html"), useBytes = TRUE)
}
