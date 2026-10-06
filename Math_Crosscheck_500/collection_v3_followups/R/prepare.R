#!/usr/bin/env Rscript

# Freeze GSM-Plus v3 self/natural branches, both replaying the same MiniMax initial.
# No provider request is made here. Controlled wrong-peer stimuli have a separate gate.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
source('Math_Crosscheck_500/R/selfcheck_runtime.R')
base <- 'Math_Crosscheck_500/collection_v3_followups'
protocol <- file.path(base, 'protocol')
replays <- file.path(protocol, 'replay')
payloads <- file.path(protocol, 'payloads')
dir.create(replays, recursive = TRUE, showWarnings = FALSE)
dir.create(payloads, recursive = TRUE, showWarnings = FALSE)
stopifnot(!file.exists(file.path(protocol, 'run_manifest.json')))

mini_file <- 'Math_Crosscheck_500/collection_v3_minimax/derived/final_scores_500.csv'
deep_file <- 'Math_Crosscheck_500/collection_v3_deepseek/derived/final_scores_500.csv'
mini_att_file <- 'Math_Crosscheck_500/collection_v3_minimax/runs/attempts.jsonl'
mini_resp_file <- 'Math_Crosscheck_500/collection_v3_minimax/runs/http_responses.jsonl'
prompt_file <- 'Math_Crosscheck_500/protocol/prompts.json'
q_file <- 'Math_Crosscheck_500/question_review_v3/model_inputs_500.csv'
mini <- read.csv(mini_file, stringsAsFactors = FALSE, check.names = FALSE)
deep <- read.csv(deep_file, stringsAsFactors = FALSE, check.names = FALSE)
questions <- read.csv(q_file, stringsAsFactors = FALSE, check.names = FALSE)
read_jsonl <- function(p) lapply(readLines(p, warn = FALSE), fromJSON, simplifyVector = FALSE)
all_attempts <- read_jsonl(mini_att_file)
all_responses <- read_jsonl(mini_resp_file)
responses <- Filter(function(x) identical(x$status, 'ok') &&
                      identical(x$finish_reason, 'end_turn'), all_responses)
selected_attempt_ids <- vapply(responses, function(x) x$attempt_id, character(1))
attempts <- all_attempts[match(selected_attempt_ids,
                               vapply(all_attempts, function(x) x$attempt_id, character(1)))]
prompts <- fromJSON(prompt_file, simplifyVector = FALSE)
stopifnot(nrow(mini) == 500L, nrow(deep) == 500L, nrow(questions) == 500L,
          length(attempts) == 500L, length(responses) == 500L,
          !anyDuplicated(mini$eval_id), !anyDuplicated(deep$eval_id),
          !anyDuplicated(questions$eval_id))
deep <- deep[match(mini$eval_id, deep$eval_id), ]
questions <- questions[match(mini$eval_id, questions$eval_id), ]
stopifnot(identical(mini$eval_id, deep$eval_id),
          identical(mini$eval_id, questions$eval_id),
          identical(mini$input_text, deep$input_text),
          identical(mini$input_text, questions$input_text))

aid <- vapply(attempts, function(x) x$task_id, character(1))
rid <- vapply(responses, function(x) x$task_id, character(1))
stopifnot(!anyDuplicated(aid), !anyDuplicated(rid),
          setequal(aid, mini$task_id), setequal(rid, mini$task_id))
attempts <- attempts[match(mini$task_id, aid)]
responses <- responses[match(mini$task_id, rid)]
eligible <- mini$grade %in% c('correct', 'incorrect') &
            deep$grade %in% c('correct', 'incorrect')
stopifnot(sum(eligible) == 496L)

replay_path <- rep('', nrow(mini))
for (i in which(eligible)) {
  req <- attempts[[i]]$request_payload
  raw <- responses[[i]]$raw_response
  stopifnot(identical(req$model, 'MiniMax-M3'),
            identical(req$messages[[1]]$role, 'user'),
            identical(req$messages[[1]]$content, mini$input_text[i]),
            identical(raw$stop_reason, 'end_turn'),
            identical(raw$model, 'MiniMax-M3'),
            is.list(raw$content), length(raw$content) >= 1L,
            identical(responses[[i]]$status, 'ok'))
  visible <- paste(vapply(Filter(function(z) identical(z$type, 'text'), raw$content),
                          function(z) z$text, character(1)), collapse = '\n')
  stopifnot(identical(visible, mini$model_response[i]))
  template <- req[setdiff(names(req), 'messages')]
  replay <- list(request_template = template,
                 messages = list(req$messages[[1]],
                                 list(role = 'assistant', content = raw$content)))
  rp <- file.path(replays, paste0(mini$eval_id[i], '.json'))
  sc_write(replay, rp)
  replay_path[i] <- rp
}

baseline <- data.frame(eval_id = mini$eval_id, question_order = mini$question_order,
                       question = mini$input_text,
                       minimax_initial_id = mini$task_id, minimax_grade = mini$grade,
                       deepseek_initial_id = deep$task_id, deepseek_grade = deep$grade,
                       replay_path = replay_path, eligible = eligible,
                       stringsAsFactors = FALSE)
baseline_file <- file.path(protocol, 'baseline_index_500.csv')
write.csv(baseline, baseline_file, row.names = FALSE, na = '')

set.seed(25011010L)
question_order <- sample(which(eligible))
jobs <- list()
for (i in question_order) {
  pair_conditions <- sample(c('self_check', 'natural_crosscheck'))
  for (condition in pair_conditions) {
    donor <- if (condition == 'natural_crosscheck') deep$model_response[i] else ''
    followup_prompt <- if (condition == 'self_check') prompts$review_suffix else
      gsub('{peer_response}', donor, prompts$peer_wrapper, fixed = TRUE)
    stopifnot(nzchar(followup_prompt),
              !grepl('\\{peer_response\\}', followup_prompt))
    replay <- sc_read(replay_path[i])
    request <- replay$request_template
    request$messages <- c(replay$messages,
                          list(list(role = 'user', content = followup_prompt)))
    stopifnot(identical(request$messages[[1]]$content, mini$input_text[i]),
              identical(request$messages[[2]]$content,
                        responses[[i]]$raw_response$content),
              identical(request$model, 'MiniMax-M3'))
    task <- list(task_id = paste0('math_v3:', mini$eval_id[i], ':', condition),
                 eval_id = mini$eval_id[i], question_order = as.integer(mini$question_order[i]),
                 condition = condition, receiver = 'minimax',
                 receiver_initial_id = mini$task_id[i],
                 receiver_initial_grade = mini$grade[i],
                 donor_initial_id = if (condition == 'natural_crosscheck') deep$task_id[i] else '',
                 donor_initial_grade = if (condition == 'natural_crosscheck') deep$grade[i] else '',
                 peer_origin = if (condition == 'natural_crosscheck')
                   'actual_independent_deepseek_initial' else 'none',
                 replay_path = replay_path[i], followup_prompt = followup_prompt)
    pp <- file.path(payloads, sprintf('%04d.json', length(jobs) + 1L))
    sc_write(request, pp)
    jobs[[length(jobs) + 1L]] <- list(task = task, payload_path = pp,
                                     payload_sha256 = sc_hash(pp))
  }
}
stopifnot(length(jobs) == 992L,
          !anyDuplicated(vapply(jobs, function(x) x$task$task_id, character(1))))

# This is a request-count guard, not a claimed monetary price or course quota.
cfg <- list(protocol = 'anthropic',
            endpoint = 'http://www.bio8.cs.hku.hk:8080/v1/messages',
            api_key_env = 'MINIMAX_API_KEY', model = 'MiniMax-M3',
            adapter_verified = TRUE,
            adapter_evidence_file = mini_resp_file,
            authorization_source = paste('User requested complete data collection',
                                         'and later removed the prior spending cap.'),
            guard_unit = 'course_quota_http_requests',
            max_total_guard_units = 1100,
            reservation_per_http = 1)
sc_config(cfg)
config_file <- file.path(protocol, 'transport_config.json')
sc_write(cfg, config_file)
source_files <- c(mini_file, deep_file, mini_att_file, mini_resp_file,
                  q_file, prompt_file, baseline_file, config_file,
                  'Math_Crosscheck_500/R/selfcheck_runtime.R',
                  file.path(base, 'R/prepare.R'),
                  replay_path[eligible])
source_files <- unique(source_files)
hashes <- setNames(lapply(source_files, sc_hash), source_files)
plan <- list(status = 'frozen_not_collected', created_at = sc_now(),
             study = 'GSM-Plus v3 MiniMax receiver self vs natural DeepSeek cross',
             question_count = 500L, eligible_questions = 496L,
             conditions = c('self_check', 'natural_crosscheck'),
             source_sha256 = hashes, config_path = config_file,
             config = cfg, jobs = jobs,
             transport_attempt_limit = 2L, pause_continuation_limit = 3L,
             concurrency = 1L,
             note = paste('Controlled wrong-peer stimulus and human-first-prompt',
                          'experiments are separately gated and absent from this run.'))
sc_write(plan, file.path(protocol, 'run_manifest.json'))
cat('Frozen', length(jobs), 'branches across', sum(eligible),
    'same MiniMax initials; no request sent.\n')
