#!/usr/bin/env Rscript

# Collect independent, fresh MiniMax or DeepSeek first-prompt pairs in R.
suppressPackageStartupMessages({library(jsonlite); library(digest); library(curl)})
`%or%` <- function(x, y) if (is.null(x)) y else x
base <- 'Math_Crosscheck_500/collection_v3_human_first'
protocol <- file.path(base, 'protocol')
manifest <- fromJSON(file.path(protocol, 'run_manifest.json'), simplifyVector = FALSE)
tasks_file <- file.path(protocol, 'tasks_200.csv')
models_file <- 'Two_Model_Collection/protocol/models.json'
hash <- function(p) digest(file = p, algo = 'sha256')
stopifnot(identical(manifest$status, 'frozen_not_collected'),
          identical(hash(tasks_file), manifest$tasks_sha256))
for (p in names(manifest$source_sha256))
  if (!identical(hash(p), manifest$source_sha256[[p]]))
    stop('Frozen source changed: ', p)
tasks <- read.csv(tasks_file, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(tasks) == 200L, !anyDuplicated(tasks$task_id),
          identical(tasks$run_order, 1:200))
args <- commandArgs(trailingOnly = TRUE)
provider_flag <- grep('^--provider=', args, value = TRUE)
if (length(provider_flag) != 1L) stop('Use --provider=deepseek or --provider=minimax.')
provider <- sub('^--provider=', '', provider_flag)
if (!provider %in% c('deepseek','minimax')) stop('Unknown provider.')
if (any(!args %in% c(provider_flag, '--preflight', '--pilot=2')))
  stop('Unknown argument.')
models <- fromJSON(models_file, simplifyVector = FALSE)
cfg <- models[[provider]]
stopifnot(identical(cfg$protocol, 'anthropic'),
          all(tasks$model[tasks$provider == provider] == cfg$model))
pt <- tasks[tasks$provider == provider, , drop = FALSE]
stopifnot(nrow(pt) == 100L)

ptr <- '/private/tmp/comp2501-two-model-credential-path.txt'
if (!file.exists(ptr)) stop('Private credential pointer unavailable.')
cp <- readLines(ptr, warn = FALSE)
if (length(cp) != 1L || !startsWith(cp, '/private/tmp/') || !file.exists(cp))
  stop('Private credential location invalid.')
creds <- readRDS(cp)
env_name <- if (provider == 'minimax') 'MINIMAX_API_KEY' else 'DEEPSEEK_API_KEY'
if (!env_name %in% names(creds) || !nzchar(creds[[env_name]]))
  stop('Provider credential unavailable.')
key <- creds[[env_name]]
rm(creds)
if ('--preflight' %in% args) {
  cat('Preflight passed for', provider, ': 100 frozen first-prompt tasks; no request sent.\n')
  quit(save = 'no', status = 0)
}

run_dir <- file.path(base, 'runs', provider)
dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
lock <- file.path(run_dir, 'collector.lock')
if (!dir.create(lock, showWarnings = FALSE)) stop('Provider collector lock exists.')
on.exit(unlink(lock, recursive = TRUE), add = TRUE)
writeLines(paste(Sys.getpid(), format(Sys.time(), tz = 'UTC', usetz = TRUE)),
           file.path(lock, 'owner.txt'))
attempt_file <- file.path(run_dir, 'attempts.jsonl')
response_file <- file.path(run_dir, 'http_responses.jsonl')
completed_file <- file.path(run_dir, 'completed.jsonl')
status_file <- file.path(run_dir, 'status.json')
read_jsonl <- function(p) {
  if (!file.exists(p) || file.info(p)$size == 0) return(list())
  lines <- readLines(p, warn = FALSE)
  if (any(!nzchar(lines))) stop('Blank JSONL record.')
  lapply(lines, fromJSON, simplifyVector = FALSE)
}
append_json <- function(x, p) {
  line <- toJSON(x, auto_unbox = TRUE, null = 'null', digits = NA)
  if (grepl(key, line, fixed = TRUE)) stop('Credential leakage guard blocked persistence.')
  cat(line, '\n', file = p, append = TRUE, sep = '')
}
now <- function() format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
attempts <- read_jsonl(attempt_file)
responses <- read_jsonl(response_file)
completed <- read_jsonl(completed_file)
aid <- vapply(attempts, function(x) x$attempt_id, character(1))
rid <- vapply(responses, function(x) x$attempt_id, character(1))
cid <- vapply(completed, function(x) x$task_id, character(1))
stopifnot(!anyDuplicated(aid), !anyDuplicated(rid), !anyDuplicated(cid),
          setequal(aid, rid), all(cid %in% pt$task_id))
if (any(!vapply(attempts, function(x) x$task_id, character(1)) %in% cid))
  stop('A prior attempt has no terminal task record; reconcile before any resend.')
if (any(vapply(responses, function(x) x$status %in%
               c('unknown_delivery','auth_or_quota_failure'), logical(1))))
  stop('Prior unresolved delivery or quota failure; do not resume.')
write_status <- function(state) {
  x <- list(state = state, updated_at = now(), provider = provider,
            planned = 100L, completed = length(completed),
            remaining = 100L - length(completed), http_attempts = length(attempts),
            known_http_responses = length(responses),
            native_search_calls = sum(vapply(completed,
              function(z) as.numeric(z$search_calls %or% 0), numeric(1))),
            monetary_cost = 'Not established; raw usage is retained.')
  tmp <- paste0(status_file, '.tmp-', Sys.getpid())
  write_json(x, tmp, pretty = TRUE, auto_unbox = TRUE)
  if (!file.rename(tmp, status_file)) stop('Status checkpoint write failed.')
  invisible(x)
}
write_status('running')
limit <- if ('--pilot=2' %in% args) 2L else nrow(pt)
for (i in seq_len(limit)) {
  t <- as.list(pt[i, ])
  if (t$task_id %in% cid) next
  payload <- list(model = cfg$model, temperature = 0.6, max_tokens = 2048L,
                  thinking = list(type = 'disabled'), stream = FALSE,
                  tools = list(list(type = 'web_search_20250305', name = 'web_search')),
                  messages = list(list(role = 'user', content = t$prompt)))
  stopifnot(length(payload$messages) == 1L,
            identical(payload$messages[[1]]$content, t$prompt))
  attempt_no <- 0L; retry_count <- 0L; continuation <- 0L
  history_text <- character(); search_calls <- 0L
  repeat {
    attempt_no <- attempt_no + 1L
    attempt_id <- paste0(t$task_id, ':http', attempt_no)
    req_text <- toJSON(payload, auto_unbox = TRUE, null = 'null', digits = NA)
    attempt <- list(attempt_id = attempt_id, task_id = t$task_id,
                    attempt_no = attempt_no, started_at = now(),
                    request_sha256 = digest(req_text, algo = 'sha256', serialize = FALSE),
                    request_payload = payload)
    append_json(attempt, attempt_file)
    attempts[[length(attempts) + 1L]] <- attempt
    h <- new_handle()
    handle_setheaders(h, .list = list('Content-Type' = 'application/json',
      'x-api-key' = key, 'anthropic-version' = '2023-06-01'))
    handle_setopt(h, postfields = req_text, timeout = 240, connecttimeout = 20,
                  followlocation = FALSE)
    raw_http <- tryCatch(curl_fetch_memory(paste0(cfg$base_url, '/messages'), handle = h),
                         error = function(e) NULL)
    if (is.null(raw_http)) {
      r <- list(attempt_id = attempt_id, task_id = t$task_id, finished_at = now(),
                status = 'unknown_delivery', http_status = NULL)
      append_json(r, response_file)
      stop('Unknown delivery. Provider stopped without retry.')
    }
    body <- rawToChar(raw_http$content)
    parsed <- tryCatch(fromJSON(body, simplifyVector = FALSE), error = function(e) NULL)
    code <- as.integer(raw_http$status_code)
    r <- list(attempt_id = attempt_id, task_id = t$task_id, finished_at = now(),
              http_status = code, raw_response = parsed,
              body_excerpt_if_invalid = if (is.null(parsed)) substr(body, 1L, 1000L) else '')
    if (code %in% c(401L,402L,403L,429L)) {
      r$status <- 'auth_or_quota_failure'
      append_json(r, response_file)
      stop('Provider authorization/quota failure HTTP ', code, '; no more calls to ', provider)
    }
    if (code %in% c(500L,502L,503L,504L)) {
      r$status <- 'known_transient_http_error'
      append_json(r, response_file)
      responses[[length(responses) + 1L]] <- r
      if (retry_count < 1L) { retry_count <- retry_count + 1L; next }
      stop('Repeated known HTTP 5xx; provider stopped.')
    }
    if (code != 200L || !is.list(parsed) || !is.list(parsed$content)) {
      r$status <- 'technical_incomplete'
      append_json(r, response_file)
      stop('Unexpected provider response; inspect raw record before continuing.')
    }
    blocks <- parsed$content
    text_blocks <- Filter(function(x) identical(x$type, 'text'), blocks)
    text <- paste(vapply(text_blocks, function(x) x$text %or% '', character(1)),
                  collapse = '\n')
    search_calls <- search_calls + sum(vapply(blocks,
      function(x) identical(x$type, 'server_tool_use') &&
        identical(x$name, 'web_search'), logical(1)))
    r$status <- if (identical(parsed$stop_reason, 'end_turn')) 'ok' else 'incomplete'
    r$text <- text; r$finish_reason <- parsed$stop_reason %or% ''
    r$usage <- parsed$usage %or% list()
    append_json(r, response_file)
    responses[[length(responses) + 1L]] <- r
    history_text <- c(history_text, text)
    if (identical(parsed$stop_reason, 'pause_turn') && continuation < 3L) {
      continuation <- continuation + 1L
      payload$messages <- c(payload$messages,
                            list(list(role = 'assistant', content = blocks)))
      next
    }
    final <- list(task_id = t$task_id, eval_id = t$eval_id,
                  question_order = as.integer(t$question_order), provider = provider,
                  model = cfg$model, condition = t$condition,
                  status = if (identical(parsed$stop_reason, 'end_turn') &&
                               nzchar(trimws(paste(history_text, collapse = '\n'))))
                             'ok' else 'technical_incomplete',
                  finish_reason = parsed$stop_reason,
                  text = paste(history_text[nzchar(history_text)], collapse = '\n'),
                  wrong_target = t$wrong_target,
                  search_calls = search_calls, http_attempts = attempt_no,
                  continuations = continuation, completed_at = now())
    append_json(final, completed_file)
    completed[[length(completed) + 1L]] <- final
    cid <- c(cid, t$task_id)
    break
  }
  if (length(completed) %% 10L == 0L || i == limit) {
    state <- write_status(if (length(completed) == 100L) 'finished' else 'running')
    cat(provider, state$completed, '/', state$planned, '\n')
  }
}
write_status(if (length(completed) == 100L) 'finished' else 'running')
