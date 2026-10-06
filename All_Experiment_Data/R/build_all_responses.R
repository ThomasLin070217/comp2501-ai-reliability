#!/usr/bin/env Rscript
# One canonical answer/task row per study. All data transformation is in R.
library(jsonlite)

out_dir <- 'All_Experiment_Data'
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
read_jsonl <- function(path) {
  if (!file.exists(path) || file.info(path)$size == 0) return(data.frame())
  con <- file(path, open = 'r', encoding = 'UTF-8')
  on.exit(close(con))
  stream_in(con, verbose = FALSE)
}
read_json <- function(path) fromJSON(path, simplifyVector = FALSE)
scalar <- function(x) {
  if (is.null(x) || length(x) == 0L || (length(x) == 1L && is.na(x))) return(NA_character_)
  if (is.list(x) || length(x) != 1L) return(as.character(toJSON(x, auto_unbox = TRUE, null = 'null')))
  as.character(x)
}
chr <- function(x, n) {
  if (is.null(x)) return(rep(NA_character_, n))
  if (is.list(x)) return(vapply(x, scalar, character(1)))
  as.character(x)
}
col <- function(x, name) if (name %in% names(x)) x[[name]] else NULL
question_map <- function(path, id_col = 'question_id') {
  x <- if (grepl('jsonl$', path)) read_jsonl(path) else read_json(path)
  if (is.data.frame(x)) {
    ids <- as.character(x[[id_col]])
    return(setNames(lapply(seq_len(nrow(x)), function(i) as.list(x[i, , drop = FALSE])), ids))
  }
  setNames(x, vapply(x, function(z) scalar(z[[id_col]]), character(1)))
}
qvalues <- function(ids, map, field) vapply(ids, function(id) {
  z <- map[[id]]
  if (is.null(z)) return(NA_character_)
  scalar(z[[field]])
}, character(1))
last_user_message <- function(messages) {
  if (is.null(messages) || !length(messages)) return(NA_character_)
  if (is.data.frame(messages)) {
    user <- which(messages$role == 'user')
    if (!length(user)) return(NA_character_)
    content <- messages$content[[tail(user, 1)]]
  } else {
    user <- which(vapply(messages, function(m) identical(m$role, 'user'), logical(1)))
    if (!length(user)) return(NA_character_)
    content <- messages[[tail(user, 1)]]$content
  }
  if (is.character(content) && length(content) == 1L) return(content)
  if (is.data.frame(content) && 'text' %in% names(content)) return(paste(content$text, collapse = '\n'))
  if (is.list(content)) {
    pieces <- vapply(content, function(z) if (is.list(z)) scalar(z$text) else scalar(z), character(1))
    return(paste(pieces[!is.na(pieces)], collapse = '\n'))
  }
  scalar(content)
}
raw_prompts <- function(raw) {
  if (!nrow(raw) || !'request' %in% names(raw)) return(rep(NA_character_, nrow(raw)))
  req <- raw$request
  if (!is.data.frame(req) || !'messages' %in% names(req))
    return(rep(NA_character_, nrow(raw)))
  vapply(req$messages, last_user_message, character(1))
}
prompt_map <- function(paths, id_field = 'task_id') {
  out <- new.env(hash = TRUE, parent = emptyenv())
  for (path in paths) {
    z <- read_jsonl(path)
    if (!nrow(z) || !id_field %in% names(z)) next
    prompts <- raw_prompts(z)
    for (i in seq_len(nrow(z))) out[[as.character(z[[id_field]][i])]] <- prompts[i]
  }
  out
}
map_get <- function(ids, env) vapply(ids, function(id) {
  if (is.na(id) || !exists(id, envir = env, inherits = FALSE)) return(NA_character_)
  get(id, envir = env, inherits = FALSE)
}, character(1))
normalize_grade <- function(x) {
  y <- tolower(trimws(as.character(x)))
  y[y %in% c('wrong', 'incorrect')] <- 'incorrect'
  y[y %in% c('not_scorable', 'pending', 'unscorable', 'ungraded', 'not_requested')] <- 'unscorable'
  y[is.na(x) | !nzchar(y)] <- NA_character_
  stopifnot(all(is.na(y) | y %in% c('correct', 'incorrect', 'abstain', 'unscorable')))
  y
}
parse_answer <- function(text) {
  if (is.na(text) || !nzchar(trimws(text))) return(rep(NA_character_, 5))
  candidate <- trimws(text)
  if (grepl('```json', candidate, fixed = TRUE)) {
    candidate <- sub('^.*?```json[[:space:]]*', '', candidate)
    candidate <- sub('[[:space:]]*```.*$', '', candidate)
  }
  obj <- tryCatch(fromJSON(candidate, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(obj) || !is.list(obj)) return(rep(NA_character_, 5))
  c(scalar(obj$answer), scalar(obj$reason), scalar(obj$abstain),
    scalar(obj$conclusion), scalar(obj$value))
}
make_rows <- function(cohort, phase, domain, source, x, id, question_id,
                      model, condition, grade, response_text = NULL,
                      status = NULL, donor = NULL, repeat_id = NULL,
                      baseline_id = NULL, answer = NULL, reason = NULL,
                      timestamp = NULL, search_calls = NULL,
                      search_available = FALSE, question = NULL, gold = NULL,
                      family = NULL, grade_frozen = NULL,
                      grade_semantic = NULL, row_note = NULL,
                      conclusion = NULL, prompt_last_user = NULL,
                      donor_id = NULL, intervention_answer = NULL,
                      intervention_reason = NULL) {
  n <- length(id)
  if (length(domain) == 1L) domain <- rep(domain, n)
  if (length(search_available) == 1L) search_available <- rep(search_available, n)
  text <- chr(response_text, n)
  parsed <- t(vapply(text, parse_answer, character(5)))
  ans <- chr(answer, n); why <- chr(reason, n)
  ans[is.na(ans) | !nzchar(ans)] <- parsed[is.na(ans) | !nzchar(ans), 1]
  why[is.na(why) | !nzchar(why)] <- parsed[is.na(why) | !nzchar(why), 2]
  conclusion <- chr(conclusion, n)
  conclusion[is.na(conclusion) | !nzchar(conclusion)] <- parsed[is.na(conclusion) | !nzchar(conclusion), 4]
  numeric_answer <- !is.na(conclusion) & conclusion == 'numeric' & !is.na(parsed[, 5])
  ans[numeric_answer] <- parsed[numeric_answer, 5]
  missing_answer <- is.na(ans) | !nzchar(ans)
  ans[missing_answer & !is.na(conclusion)] <- conclusion[missing_answer & !is.na(conclusion)]
  g <- normalize_grade(grade)
  data.frame(
    observation_id = paste(cohort, chr(model, n), chr(id, n), sep = '::'),
    experiment = rep(cohort, n), experiment_phase = rep(phase, n),
    domain = chr(domain, n), question_id = chr(question_id, n),
    question_family = chr(family, n), question_text = chr(question, n),
    reference_answer = chr(gold, n), provider = chr(model, n),
    other_model = chr(donor, n), repeat_id = chr(repeat_id, n),
    condition = chr(condition, n), baseline_id = chr(baseline_id, n),
    donor_response_id = chr(donor_id, n),
    intervention_answer = chr(intervention_answer, n),
    intervention_reason = chr(intervention_reason, n),
    prompt_last_user = chr(prompt_last_user, n),
    response_status = chr(status, n), grade = g,
    grade_frozen = chr(grade_frozen, n), grade_semantic = chr(grade_semantic, n),
    grade_basis = ifelse(!is.na(chr(grade_semantic, n)), 'posthoc_semantic',
      ifelse(is.na(g), 'not_graded', 'source_grade')),
    is_wrong = ifelse(is.na(g) | g == 'unscorable', NA_integer_, as.integer(g == 'incorrect')),
    is_abstain = ifelse(is.na(g) | g == 'unscorable', NA_integer_, as.integer(g == 'abstain')),
    final_answer = ans, response_conclusion = conclusion,
    answer_value = parsed[, 5], reason = why, response_text = text,
    native_search_available = as.logical(search_available),
    native_search_calls = suppressWarnings(as.integer(chr(search_calls, n))),
    response_timestamp = chr(timestamp, n), source_file = rep(source, n),
    source_record_id = chr(id, n), note = chr(row_note, n),
    stringsAsFactors = FALSE, check.names = FALSE)
}

blocks <- list()
put <- function(name, x, expected) {
  stopifnot(nrow(x) == expected, !anyDuplicated(x$observation_id))
  blocks[[name]] <<- x
}

# Pilot: three completed model runs; empty failed/preflight directories excluded.
pilot_q <- question_map('Double_Check_Pilot_2026-09-30/pilot_questions.jsonl', 'pilot_id')
for (provider in c('deepseek', 'kimi', 'minimax')) {
  run <- if (provider == 'minimax') 'minimax_r2' else paste0(provider, '_r1')
  path <- paste0('Double_Check_Pilot_2026-09-30/runs/', run, '/graded_responses.jsonl')
  x <- read_jsonl(path); ids <- as.character(x$pilot_id)
  rawp <- sub('graded_responses.jsonl$', 'responses.jsonl', path)
  prompts <- prompt_map(rawp)
  put(paste0('pilot_', provider), make_rows('pilot_2026_09_30', 'pilot', 'facts', path,
    x, x$task_id, ids, provider, x$stage, x$grade, x$text, status = 'ok',
    question = qvalues(ids, pilot_q, 'question'),
    gold = qvalues(ids, pilot_q, 'correct_answer'),
    family = qvalues(ids, pilot_q, 'category'),
    grade_frozen = x$grade, prompt_last_user = map_get(x$task_id, prompts)), 180)
}

# Early fact-study development and main formal receiver responses. The main
# original stream retains two HTTP failures; their successful transport retries
# are selected once, by task ID, for the answer-level table.
peer_dev_q <- question_map('Peer_Misleading_Study/data/dev_questions.jsonl')
peer_main_q <- question_map('Peer_Misleading_Study/data/main_questions.jsonl')
for (phase in c('development', 'main')) {
  gp <- if (phase == 'main') 'Peer_Misleading_Study/reports/main_r/all_response_grades.csv' else
    'Peer_Misleading_Study/reports/main_r/development/graded_responses.csv'
  rawp <- paste0('Peer_Misleading_Study/runs/', if (phase == 'main') 'main_receivers' else 'dev_receivers', '/responses.jsonl')
  g <- read.csv(gp, stringsAsFactors = FALSE); raw <- read_jsonl(rawp)
  idx <- match(g$task_id, raw$task_id)
  stopifnot(!anyNA(idx), !anyDuplicated(g$task_id))
  selected_text <- raw$text[idx]
  selected_status <- raw$status[idx]
  selected_time <- raw$timestamp[idx]
  selected_prompt <- raw_prompts(raw)[idx]
  if (phase == 'main') {
    for (p in c('Peer_Misleading_Study/runs/main_transport_recovery_01/responses.jsonl',
                'Peer_Misleading_Study/runs/main_transport_recovery_02/responses.jsonl')) {
      replacement <- read_jsonl(p)
      where <- match(replacement$task_id, g$task_id)
      stopifnot(length(where) == 1L, !is.na(where), replacement$status == 'ok')
      selected_text[where] <- replacement$text
      selected_status[where] <- replacement$status
      selected_time[where] <- replacement$timestamp
      selected_prompt[where] <- raw_prompts(replacement)
    }
  }
  map <- if (phase == 'main') peer_main_q else peer_dev_q
  ids <- as.character(g$question_id)
  put(paste0('peer_', phase), make_rows(paste0('peer_misleading_', phase), phase,
    'facts', gp, g, g$task_id, ids, g$provider, g$condition, g$grade,
    response_text = selected_text, status = selected_status, donor = g$generator,
    repeat_id = g$repeat_id, timestamp = selected_time,
    question = qvalues(ids, map, 'question'), gold = qvalues(ids, map, 'gold'),
    family = qvalues(ids, map, 'topic'), grade_frozen = g$grade,
    prompt_last_user = selected_prompt,
    row_note = if (phase == 'main') ifelse(g$grade == 'pending',
      'Frozen pending output; excluded from scored analysis', NA_character_) else NULL),
    if (phase == 'main') 5040 else 315)
}

# Mathematical development and supplement include every scheduled answer, not
# merely the complete-pair subset used in older headline comparisons.
for (phase in c('development', 'supplementary')) {
  path <- paste0('Math_Supplement/reports/', phase, '/graded_responses.csv')
  x <- read.csv(path, stringsAsFactors = FALSE)
  raw_paths <- paste0('Math_Supplement/runs/', c('deepseek','kimi','minimax'), '/responses.jsonl')
  prompts <- prompt_map(raw_paths)
  put(paste0('math_', phase), make_rows(paste0('math_supplement_', phase), phase,
    'math', path, x, x$task_id, x$question_id, x$provider, x$condition,
    x$grade, x$response_text, x$response_status, x$donor, x$repeat_id,
    reason = x$reason, conclusion = x$conclusion, question = x$question,
    gold = x$gold, family = x$family, grade_frozen = x$grade,
    row_note = ifelse(x$complete_pair, NA_character_, 'Not in complete-pair main analysis'),
    prompt_last_user = map_get(x$task_id, prompts)),
    if (phase == 'development') 126 else 546)
}

for (cohort in c('Natural_Crosscheck', 'Followup_Validation')) {
  path <- paste0(cohort, '/reports/graded_responses.csv')
  x <- read.csv(path, stringsAsFactors = FALSE)
  qmap <- question_map(paste0(cohort, '/protocol/questions.jsonl'))
  ids <- as.character(x$question_id)
  question <- if ('question' %in% names(x)) x$question else qvalues(ids, qmap, 'question')
  gold <- if ('gold' %in% names(x)) x$gold else qvalues(ids, qmap, 'gold')
  raw_paths <- paste0(cohort, '/runs/', c('deepseek','kimi','minimax'), '/responses.jsonl')
  prompts <- prompt_map(raw_paths)
  put(cohort, make_rows(tolower(cohort), 'expanded_validation', x$domain, path, x,
    x$task_id, ids, x$provider, x$condition, x$grade, x$response_text,
    x$response_status, x$donor, col(x, 'repeat_id'),
    answer = col(x, 'answer'), reason = col(x, 'reason'), question = question,
    gold = gold, family = x$family, grade_frozen = x$grade,
    row_note = ifelse(x$response_status == 'not_requested',
      'Scheduled branch not requested; no model answer', NA_character_),
    prompt_last_user = map_get(x$task_id, prompts)),
    if (cohort == 'Natural_Crosscheck') 588 else 4032)
}

webp <- 'Web_Factcheck_100/reports/answers.csv'
x <- read.csv(webp, stringsAsFactors = FALSE)
web_prompts <- prompt_map('Web_Factcheck_100/runs/responses.jsonl', 'question_id')
put('web_factcheck', make_rows('web_factcheck_100', 'standalone_web', 'facts', webp,
  x, paste0(x$question_id, ':web:r1'), x$question_id, 'minimax', 'neutral_initial',
  x$grade, x$response_text, x$status, answer = x$answer, reason = x$reason,
  question = x$question, gold = x$gold, search_available = TRUE,
  search_calls = x$search_calls, grade_frozen = x$grade,
  prompt_last_user = map_get(x$question_id, web_prompts)), 100)

# Stopped three-provider online migration is retained as its own partial cohort.
onlinep <- 'Online_Replication/runs/completed.jsonl'
x <- read_jsonl(onlinep); qmap <- question_map('Online_Replication/protocol/questions.jsonl')
ids <- as.character(x$question_id)
online_http <- list.files('Online_Replication/runs/http', pattern = '-responses\\.jsonl$',
                          full.names = TRUE)
online_prompts <- prompt_map(online_http, 'id')
last_http <- vapply(x$http_ids, function(z) if (length(z)) as.character(tail(z, 1))
  else NA_character_, character(1))
put('online_partial', make_rows('online_replication_partial', 'stopped_partial',
  x$domain, onlinep, x, x$id, ids, x$provider, x$condition,
  ifelse(x$status == 'ok', NA_character_, 'unscorable'), x$text, x$status,
  x$donor, x$repeat_id, search_available = TRUE,
  search_calls = x$search_requested, timestamp = x$completed_at,
  question = qvalues(ids, qmap, 'question'), gold = qvalues(ids, qmap, 'gold'),
  family = x$family, prompt_last_user = map_get(last_http, online_prompts),
  row_note = 'Historical partial collection; no frozen final semantic grade'), 320)

# Latest two-model selected overlay: one final record per task, not each raw
# failed/retried HTTP attempt or each archived scoring sensitivity variant.
for (domain in c('facts', 'math')) {
  path <- if (domain == 'facts')
    'Two_Model_Collection/facts/recovery/derived/reports/semantic_sensitivity_records.csv' else
    'Two_Model_Collection/math/recovery/derived/reports/semantic_final_responses.csv'
  x <- read.csv(path, stringsAsFactors = FALSE)
  selected <- read_jsonl(paste0('Two_Model_Collection/', domain,
    '/recovery/derived/runs/completed.jsonl'))
  selected_http <- setNames(as.character(selected$http_id), as.character(selected$id))
  http_paths <- c(paste0('Two_Model_Collection/', domain, '/runs/http_responses.jsonl'),
    paste0('Two_Model_Collection/', domain, '/recovery/runs/http_responses.jsonl'))
  http_prompts <- prompt_map(http_paths, 'id')
  qmap <- question_map(if (domain == 'facts')
    'Two_Model_Collection/facts/protocol/questions.jsonl' else
    'Two_Model_Collection/math/protocol/questions.json')
  ids <- as.character(x$question_id)
  sem <- if (domain == 'facts') x$semantic_grade else x$final_semantic_grade
  gold <- if (domain == 'facts') qvalues(ids, qmap, 'gold') else {
    refs <- question_map('Two_Model_Collection/math/protocol/researcher_reference.json')
    qvalues(ids, refs, 'reference_answer')
  }
  put(paste0('two_model_', domain), make_rows(paste0('two_model_', domain),
    'technical_recovery_overlay', domain, path, x, x$id, ids, x$provider,
    x$condition, sem, x$text, x$status, x$donor, x$repeat_id,
    x$baseline_id, search_available = TRUE, search_calls = x$search_requested,
    donor_id = x$donor_id,
    prompt_last_user = map_get(unname(selected_http[x$id]), http_prompts),
    question = qvalues(ids, qmap, 'question'), gold = gold,
    family = x$family, grade_frozen = x$grade, grade_semantic = sem,
    row_note = 'Grade uses documented post-hoc semantic completed-data overlay'),
    if (domain == 'facts') 1591 else 732)
}
# The recovery overlay also retained nine factual branches blocked by invalid
# prerequisite outputs. They have no HTTP request and must remain missing rows.
skip_path <- 'Two_Model_Collection/facts/recovery/derived/runs/skipped.jsonl'
sk <- read_jsonl(skip_path)
fact_map <- question_map('Two_Model_Collection/facts/protocol/questions.jsonl')
skip_ids <- as.character(sk$question_id)
put('two_model_facts_skipped', make_rows('two_model_facts',
  'technical_recovery_overlay', 'facts', skip_path, sk, sk$id,
  skip_ids, sk$provider, sk$condition, rep(NA_character_, nrow(sk)),
  status = 'not_requested', donor = sk$donor, repeat_id = sk$repeat_id,
  baseline_id = sk$baseline_id, donor_id = sk$donor_id,
  search_available = TRUE,
  question = qvalues(skip_ids, fact_map, 'question'),
  gold = qvalues(skip_ids, fact_map, 'gold'), family = sk$family,
  row_note = paste('Blocked dependency:', sk$reason)), 9)

humanp <- 'Human_Challenge_Followup/reports/graded.csv'
x <- read.csv(humanp, stringsAsFactors = FALSE)
human_sel <- read_jsonl('Human_Challenge_Followup/recovery/selected.jsonl')
human_http <- setNames(as.character(human_sel$http_id), as.character(human_sel$id))
human_prompts <- prompt_map(c('Human_Challenge_Followup/runs/http_responses.jsonl',
  'Human_Challenge_Followup/recovery/http_responses.jsonl'), 'id')
manifest <- read_json('Human_Challenge_Followup/protocol/manifest.json')
qmap <- setNames(manifest$questions, vapply(manifest$questions,
  function(z) scalar(z$question_id), character(1)))
ids <- as.character(x$question_id)
fact_map <- question_map('Two_Model_Collection/facts/protocol/questions.jsonl')
math_ref <- question_map('Two_Model_Collection/math/protocol/researcher_reference.json')
human_gold <- vapply(ids, function(id) if (startsWith(id, 'CHAMP:'))
  qvalues(id, math_ref, 'reference_answer') else qvalues(id, fact_map, 'gold'),
  character(1))
put('human_challenge', make_rows('human_challenge_followup', 'correct_baseline_followup',
  x$domain, humanp, x, x$id, ids, x$provider, x$arm, x$grade, x$text,
  x$status, baseline_id = x$baseline_id, answer = x$final_answer,
  reason = x$reason, search_available = TRUE,
  search_calls = x$search_requested, question = qvalues(ids, qmap, 'question'),
  gold = human_gold,
  prompt_last_user = map_get(unname(human_http[x$id]), human_prompts),
  intervention_answer = ifelse(x$arm == 'human_challenge', x$wrong_answer, NA_character_),
  intervention_reason = ifelse(x$arm == 'human_challenge', x$wrong_reason, NA_character_),
  grade_frozen = x$grade,
  row_note = 'Scripted human challenge, not a real human participant'), 156)

all <- do.call(rbind, blocks)
rownames(all) <- NULL
stopifnot(nrow(all) == 14095L, !anyDuplicated(all$observation_id),
  all(!is.na(all$source_record_id)),
  all(file.exists(unique(all$source_file))),
  all(!is.na(all$question_text) & nzchar(all$question_text)),
  all(!is.na(all$reference_answer) & nzchar(all$reference_answer)),
  sum(all$response_status == 'not_requested', na.rm = TRUE) == 136L,
  sum(is.na(all$response_text) | !nzchar(all$response_text)) == 136L,
  sum(is.na(all$prompt_last_user) | !nzchar(all$prompt_last_user)) == 136L,
  all(is.na(all$grade) | all$grade %in% c('correct','incorrect','abstain','unscorable')))
csv_path <- file.path(out_dir, 'all_experiment_responses.csv')
write.csv(all, csv_path, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
round_trip <- read.csv(csv_path, stringsAsFactors = FALSE,
                       na.strings = '', fileEncoding = 'UTF-8')
stopifnot(nrow(round_trip) == nrow(all),
          identical(round_trip$observation_id, all$observation_id),
          identical(ifelse(is.na(round_trip$response_text), '', round_trip$response_text),
                    ifelse(is.na(all$response_text), '', all$response_text)))
summary <- data.frame(experiment = names(blocks), rows = vapply(blocks, nrow, integer(1)),
                      stringsAsFactors = FALSE)
write_json(list(status = 'passed', rows = nrow(all),
                unique_observation_ids = length(unique(all$observation_id)),
                csv_sha256 = digest::digest(file = csv_path, algo = 'sha256'),
                nonempty_question_text = sum(!is.na(all$question_text) & nzchar(all$question_text)),
                nonempty_reference_answer = sum(!is.na(all$reference_answer) & nzchar(all$reference_answer)),
                nonempty_response_text = sum(!is.na(all$response_text) & nzchar(all$response_text)),
                nonempty_prompt_last_user = sum(!is.na(all$prompt_last_user) & nzchar(all$prompt_last_user)),
                cohorts = lapply(seq_len(nrow(summary)), function(i) {
                  y <- blocks[[i]]
                  list(name = summary$experiment[i], rows = summary$rows[i],
                       grades = as.list(table(factor(y$grade,
                         levels = c('correct','incorrect','abstain','unscorable')))),
                       not_graded = sum(is.na(y$grade)))
                })),
           file.path(out_dir, 'audit.json'), auto_unbox = TRUE, pretty = TRUE)
cat('Wrote', nrow(all), 'unique task rows to', csv_path, '\n')
print(summary, row.names = FALSE)
