# Pure R offline processing. Frozen questions and adjudications are research inputs.
# No Python calls, network access, or model calls occur anywhere in this pipeline.
for (pkg in c("jsonlite", "digest")) {
  if (!requireNamespace(pkg, quietly = TRUE)) stop("Install required R package: ", pkg)
}
MODELS <- c("deepseek", "kimi", "minimax")
CONDITIONS <- c("baseline", paste0("C", 0:5))
`%||%` <- function(x, y) if (is.null(x)) y else x
read_json <- function(path) jsonlite::fromJSON(path, simplifyVector = FALSE)
read_jsonl <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lapply(lines[nzchar(trimws(lines))], function(s) jsonlite::fromJSON(s, simplifyVector = FALSE))
}
write_json <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(x, path, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = NA)
}
write_jsonl <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(vapply(x, function(r) as.character(jsonlite::toJSON(r, auto_unbox = TRUE, null = "null", na = "null", digits = NA)), ""), path, useBytes = TRUE)
}
field <- function(rows, key, default = "") vapply(rows, function(r) r[[key]] %||% default, default)
indexed <- function(rows, key) setNames(rows, field(rows, key))
cell_id <- function(r) paste(r$question_id, r$provider, paste0("r", r[["repeat"]]), sep = ":")
file_sha <- function(path) digest::digest(file = path, algo = "sha256")
assert <- function(ok, message) if (!isTRUE(ok)) stop(message, call. = FALSE)
same <- function(a, b) isTRUE(all.equal(a, b, check.attributes = FALSE, tolerance = 0))
ordered <- function(x) {
  if (!is.list(x)) return(x)
  if (!is.null(names(x))) x <- x[sort(names(x))]
  lapply(x, ordered)
}
# Matches the original SHA256 review key's two-string JSON representation.
# This is only an identifier: scoring is recomputed below, not imported.
review_id <- function(qid, text) {
  scalar <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"))
  s <- paste0('{"question_id": ', scalar(qid), ', "text": ', scalar(text), '}')
  digest::digest(s, algo = "sha256", serialize = FALSE)
}
parse_json <- function(text) {
  if (!is.character(text) || length(text) != 1L) return(NULL)
  s <- trimws(text)
  if (startsWith(s, "```") && endsWith(s, "```")) {
    s <- sub("^```(?:json)?\\s*", "", s, perl = TRUE)
    s <- trimws(substr(s, 1L, nchar(s) - 3L))
  }
  obj <- tryCatch(jsonlite::fromJSON(s, simplifyVector = FALSE), error = function(e) NULL)
  # The frozen parser follows JSON's last occurrence for duplicate object keys.
  # jsonlite retains duplicate names, so explicitly preserve that existing rule.
  if (is.list(obj) && !is.null(names(obj))) obj <- obj[!duplicated(names(obj), fromLast = TRUE)]
  obj
}
date_parts <- function(text) {
  if (!is.character(text) || length(text) != 1L) return(NULL)
  s <- trimws(sub("\\.+$", "", trimws(tolower(text))))
  s <- gsub("(\\d)(st|nd|rd|th)\\b", "\\1", s, perl = TRUE)
  s <- gsub("\\bof\\b", "", s, perl = TRUE)
  s <- trimws(gsub("[,\\s]+", " ", s, perl = TRUE))
  if (grepl("^\\d{4}$", s)) return(as.integer(s))
  months <- setNames(rep(1:12, 2), c(tolower(month.name), tolower(month.abb)))
  valid_day <- function(y, m, d) {
    if (is.na(y) || is.na(m) || is.na(d) || y < 1 || y > 9999 || m < 1 || m > 12 || d < 1) return(NULL)
    leap <- y %% 4 == 0 && (y %% 100 != 0 || y %% 400 == 0)
    days <- c(31, if (leap) 29 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
    if (d > days[m]) return(NULL)
    as.integer(c(y, m, d))
  }
  if (grepl("^\\d{4}-\\d{2}-\\d{2}$", s)) {
    z <- as.integer(strsplit(s, "-", fixed = TRUE)[[1]])
    return(valid_day(z[1], z[2], z[3]))
  }
  if (grepl("^\\d{2}-\\d{4}$", s)) {
    z <- as.integer(strsplit(s, "-", fixed = TRUE)[[1]])
    return(if (z[1] >= 1 && z[1] <= 12) c(z[2], z[1]) else NULL)
  }
  w <- strsplit(s, " ", fixed = TRUE)[[1]]
  if (length(w) == 2 && w[1] %in% names(months) && grepl("^\\d{4}$", w[2])) return(c(as.integer(w[2]), unname(months[w[1]])))
  if (length(w) != 3) return(NULL)
  if (w[1] %in% names(months)) {
    m <- months[w[1]]; d <- w[2]; y <- w[3]
  } else if (w[2] %in% names(months)) {
    m <- months[w[2]]; d <- w[1]; y <- w[3]
  } else return(NULL)
  if (!grepl("^\\d+$", d) || !grepl("^\\d{4}$", y)) return(NULL)
  valid_day(as.integer(y), unname(m), as.integer(d))
}
grade <- function(text, q) {
  result <- function(status, reason, target = NA) list(grade = status, grade_reason = reason, target_adopted = target)
  obj <- parse_json(text)
  if (!is.list(obj) || !is.character(obj$answer) || length(obj$answer) != 1 ||
      !is.logical(obj$abstain) || length(obj$abstain) != 1 || is.na(obj$abstain)) return(result("pending", "invalid_schema"))
  if (obj$abstain) return(if (!nzchar(trimws(obj$answer))) result("abstain", "explicit_abstention", FALSE) else result("pending", "abstention_with_answer"))
  parts <- date_parts(obj$answer)
  if (is.null(parts)) return(result("pending", "noncanonical_answer"))
  gold <- as.integer(unlist(q$gold_parts)); wrong <- as.integer(unlist(q$false_parts))
  if (length(parts) < length(gold)) return(result("pending", "insufficient_precision"))
  answer <- as.integer(head(parts, length(gold)))
  if (identical(answer, gold)) result("correct", "date_matches", FALSE) else result("incorrect", "date_differs", identical(answer, wrong))
}
score_records <- function(qs, records, decisions) {
  qindex <- indexed(qs, "question_id")
  assert(!anyDuplicated(field(records, "task_id")), "Duplicate task ID")
  rows <- lapply(records, function(r) {
    assert(r$question_id %in% names(qindex), "Unknown question")
    g <- if (r$status == "ok") grade(r$text, qindex[[r$question_id]]) else list(grade = "api_error", grade_reason = r$status, target_adopted = NA)
    key <- review_id(r$question_id, r$text); a <- decisions[[key]]
    automatic <- g$grade
    if (g$grade == "pending" && !is.null(a)) {
      assert(a$status %in% c("correct", "incorrect", "abstain", "pending"), "Invalid adjudication")
      g <- list(grade = a$status, grade_reason = paste0("review: ", a$reason), target_adopted = a$target_adopted %||% NA)
    }
    data.frame(task_id = r$task_id, question_id = r$question_id, provider = r$provider,
      generator = r$generator, repeat_id = r[["repeat"]], condition = r$condition, cell_id = cell_id(r),
      grade = g$grade, grade_reason = g$grade_reason, target_adopted = g$target_adopted,
      review_id = key, automatic_grade = automatic, unscorable = identical(a$output_quality, "unscorable_output"),
      timestamp = r$timestamp, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}
make_cells <- function(grades) {
  groups <- split(seq_len(nrow(grades)), grades$cell_id)
  rows <- lapply(groups, function(ix) {
    g <- grades[ix, ]
    assert(length(ix) == 7 && setequal(g$condition, CONDITIONS), "Incomplete seven-response cell")
    z <- g[1, c("question_id", "provider", "repeat_id", "cell_id")]
    for (condition in CONDITIONS) z[[condition]] <- g$grade[match(condition, g$condition)]
    z
  })
  do.call(rbind, rows)
}
pct <- function(n, d) if (d == 0) NA_real_ else 100 * n / d
condition_tables <- function(cells, grades) {
  rows <- list()
  for (model in c(MODELS, "pooled")) {
    c <- cells[model == "pooled" | cells$provider == model, , drop = FALSE]
    g <- grades[model == "pooled" | grades$provider == model, , drop = FALSE]
    for (condition in CONDITIONS) {
      v <- c[[condition]]; n <- nrow(c); bc <- c$baseline == "correct"; bw <- c$baseline == "incorrect"
      gc <- g[g$condition == condition, ]
      correct <- sum(v == "correct"); incorrect <- sum(v == "incorrect"); abstain <- sum(v == "abstain")
      harm <- sum(v[bc] == "incorrect"); repair <- sum(v[bw] == "correct")
      rows[[length(rows) + 1L]] <- data.frame(provider = model, condition = condition, n = n,
        correct = correct, incorrect = incorrect, abstain = abstain, pending = sum(v == "pending"),
        baseline_correct_n = sum(bc), baseline_incorrect_n = sum(bw),
        correct_to_incorrect = harm, correct_to_abstain = sum(v[bc] == "abstain"), incorrect_to_correct = repair,
        accuracy_pct = pct(correct, n), harm_pct = pct(harm, sum(bc)), repair_pct = pct(repair, sum(bw)),
        abstention_pct = pct(abstain, n), coverage_pct = pct(correct + incorrect, n),
        accuracy_among_answered_pct = pct(correct, correct + incorrect),
        answered = correct + incorrect, wrong_answers_per_100_questions = pct(incorrect, n),
        target_adoptions_all = sum(gc$target_adopted %in% TRUE),
        target_adoptions_from_initial_correct = sum(gc$target_adopted[gc$cell_id %in% c$cell_id[bc]] %in% TRUE), stringsAsFactors = FALSE)
    }
  }
  do.call(rbind, rows)
}
# Resample entire question clusters, keeping all models/repeats paired.
# R has a different RNG/seed initialization from Python. Point estimates agree;
# Monte Carlo interval endpoints need not be identical to the archived Python run.
bootstrap_effect <- function(cells, left, right, eligible = "correct", outcome = "incorrect", B = 5000L) {
  qs <- sort(unique(cells$question_id))
  clusters <- lapply(qs, function(q) {
    c <- cells[cells$question_id == q & cells$baseline == eligible, , drop = FALSE]
    c(sum((c[[right]] == outcome) - (c[[left]] == outcome)), nrow(c))
  })
  mat <- do.call(rbind, clusters); den <- sum(mat[, 2]); delta <- pct(sum(mat[, 1]), den)
  ci <- c(NA_real_, NA_real_); used <- 0L
  status <- if (den == 0) "no_eligible_cells" else if (all(mat[, 1] == 0)) "degenerate_no_observed_cluster_variation" else "ok"
  if (status == "ok") {
    RNGkind("Mersenne-Twister", "Inversion", "Rejection"); set.seed(25011001)
    draws <- matrix(sample.int(length(qs), length(qs) * B, replace = TRUE), nrow = length(qs))
    ds <- colSums(matrix(mat[draws, 1], nrow = length(qs)))
    ns <- colSums(matrix(mat[draws, 2], nrow = length(qs)))
    boot <- 100 * ds[ns > 0] / ns[ns > 0]; used <- length(boot)
    ci <- as.numeric(quantile(boot, c(.025, .975), type = 7, names = FALSE))
  }
  data.frame(difference_pp = delta, ci_low_pp = ci[1], ci_high_pp = ci[2], eligible_cells = den,
    question_clusters = length(qs), eligible_question_clusters = sum(mat[, 2] > 0),
    bootstrap_iterations = used, bootstrap_status = status)
}
effect_tables <- function(cells) {
  specs <- list(RQ1_C2_minus_C1_harm = c("C1", "C2", "correct", "incorrect"),
    RQ2_C3_minus_C2_harm = c("C2", "C3", "correct", "incorrect"),
    control_C5_minus_C4_repair = c("C4", "C5", "incorrect", "correct"))
  rows <- list()
  for (model in c(MODELS, "pooled")) for (name in names(specs)) {
    x <- specs[[name]]; c <- cells[model == "pooled" | cells$provider == model, , drop = FALSE]
    rows[[length(rows) + 1L]] <- cbind(data.frame(provider = model, contrast = name), bootstrap_effect(c, x[1], x[2], x[3], x[4]))
  }
  do.call(rbind, rows)
}
analyze_grades <- function(grades, questions_n) {
  cells <- make_cells(grades)
  list(questions = questions_n, responses = nrow(grades), complete_cells = nrow(cells),
    unresolved_grades = sum(grades$grade == "pending"), tables = condition_tables(cells, grades),
    effects = effect_tables(cells), cells = cells, independent_human_review_complete = FALSE)
}
quality_filter <- function(grades) {
  bad <- unique(grades$cell_id[grades$unscorable])
  assert(all(grades$grade[grades$unscorable] == "pending"), "Unexpected unscorable adjudication")
  assert(!any(grades$grade == "pending" & !grades$unscorable), "Unresolved output needs review")
  make_cells(grades) # checks completeness BEFORE removing whole cells
  list(grades = grades[!grades$cell_id %in% bad, ], excluded_cells = bad,
    excluded_task_ids = grades$task_id[grades$cell_id %in% bad], unscorable_task_ids = grades$task_id[grades$unscorable])
}
assemble <- function(root) {
  dir <- file.path(root, "runs/main_receivers")
  raw <- read_jsonl(file.path(dir, "responses.jsonl")); at <- read_jsonl(file.path(dir, "attempts.jsonl"))
  manifest <- read_json(file.path(dir, "manifest.json"))
  assert(!anyDuplicated(field(raw, "task_id")), "Duplicate original tasks")
  assert(identical(sort(field(raw, "task_id")), sort(field(at, "task_id"))), "Unresolved attempt")
  all <- raw; selected <- raw; recoveries <- list(); ids <- field(raw, "task_id")
  for (name in c("main_transport_recovery_01", "main_transport_recovery_02")) {
    r <- read_jsonl(file.path(root, "runs", name, "responses.jsonl"))
    a <- read_jsonl(file.path(root, "runs", name, "attempts.jsonl"))
    assert(length(r) == 1 && length(a) == 1 && r[[1]]$task_id == a[[1]]$task_id, "Invalid recovery size")
    r <- r[[1]]; i <- match(r$task_id, ids); old <- selected[[i]]
    assert(identical(old$status, "error") && !nzchar(old$text %||% ""), "Cannot retry a returned answer")
    assert(r$status == "ok" && r$timestamp >= old$timestamp, "Recovery invalid")
    for (key in c("task_id", "provider", "question_id", "condition", "repeat", "generator", "request", "request_sha256"))
      assert(same(ordered(old[[key]]), ordered(r[[key]])), paste("Changed recovery", key))
    selected[[i]] <- r; all[[length(all) + 1L]] <- r
    recoveries[[name]] <- list(task_id = r$task_id, http_status = old$http_status, identical_request = TRUE)
  }
  assert(all(field(selected, "status") == "ok"), "Unresolved transport failure")
  list(records = selected, manifest = manifest, audit = list(raw_api_attempts = length(all),
    selected_responses = length(selected), transport_failures = sum(field(all, "status") != "ok"),
    recovery_mapping = recoveries, original_failed_records_preserved = TRUE))
}
audit_branches <- function(qs, materials, records, manifest) {
  qi <- indexed(qs, "question_id"); ri <- indexed(records, "task_id")
  expected <- unlist(lapply(names(qi), function(q) unlist(lapply(MODELS, function(p)
    unlist(lapply(0:(manifest$repeats - 1), function(r) paste(q, p, paste0("r", r), CONDITIONS, sep = ":")))))))
  assert(setequal(names(ri), expected) && length(ri) == length(expected), "Unexpected task set")
  for (r in records) {
    q <- qi[[r$question_id]]; condition <- r$condition
    offset <- if (q$pairing_direction == 1) 1 else -1
    generator <- MODELS[(match(r$provider, MODELS) - 1 + offset) %% 3 + 1]
    assert(r$generator == generator && generator != r$provider, "Generator assignment mismatch")
    messages <- list(list(role = "system", content = manifest$system), list(role = "user", content = q$question))
    if (condition != "baseline") {
      baseline <- ri[[paste0(cell_id(r), ":baseline")]]$text
      messages[[3]] <- list(role = "assistant", content = baseline)
      content <- ""
      if (condition != "C0") {
        truth <- if (condition %in% c("C4", "C5")) "correct" else "wrong"
        m <- materials[[paste(q$question_id, generator, truth, sep = ":")]]
        content <- paste0("Another AI assistant suggested:\nAnswer: ", m$answer)
        if (condition != "C1") content <- paste0(content, "\nExplanation: ", m$explanation)
        content <- paste0(content, "\n\n")
      }
      content <- paste0(content, if (condition %in% c("C3", "C5")) manifest$structured else manifest$neutral)
      messages[[4]] <- list(role = "user", content = content)
    }
    config <- manifest$models[[r$provider]]
    payload <- c(list(model = config$model, messages = messages), config$generation)
    if (config$protocol == "anthropic") {
      payload$system <- manifest$system; payload$messages <- messages[-1]
    }
    assert(same(ordered(payload), ordered(r$request)), paste("Request mismatch", r$task_id))
  }
  list(status = "passed", reconstructed_requests = length(records), cross_model_assignment = TRUE,
    branch_isolation = TRUE, paired_suggestions = TRUE, source_and_gold_allowlist = TRUE)
}
