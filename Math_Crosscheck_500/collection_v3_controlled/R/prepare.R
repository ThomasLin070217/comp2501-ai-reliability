#!/usr/bin/env Rscript

# Freeze 50 scripted wrong-peer branches from verified-correct MiniMax initials.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
source('Math_Crosscheck_500/R/selfcheck_runtime.R')
base <- 'Math_Crosscheck_500/collection_v3_controlled'
parent <- 'Math_Crosscheck_500/collection_v3_followups'
protocol <- file.path(base, 'protocol')
payload_dir <- file.path(protocol, 'payloads')
dir.create(payload_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(!file.exists(file.path(protocol, 'run_manifest.json')))
selection_file <- file.path(parent, 'protocol/controlled_target_selection_50.csv')
materials_file <- file.path(parent, 'protocol/controlled_wrong_peer_materials_50.csv')
materials_manifest <- file.path(parent, 'protocol/controlled_materials_manifest.json')
baseline_file <- file.path(parent, 'protocol/baseline_index_500.csv')
prompt_file <- 'Math_Crosscheck_500/protocol/prompts.json'
s <- read.csv(selection_file, stringsAsFactors = FALSE, check.names = FALSE)
m <- read.csv(materials_file, stringsAsFactors = FALSE, check.names = FALSE)
b <- read.csv(baseline_file, stringsAsFactors = FALSE, check.names = FALSE)
mm <- sc_read(materials_manifest)
prompts <- sc_read(prompt_file)
stopifnot(nrow(s) == 50L, nrow(m) == 50L, nrow(b) == 500L,
          identical(sc_hash(materials_file), mm$materials_sha256),
          identical(sc_hash(selection_file), mm$selection_sha256),
          setequal(s$eval_id, m$eval_id), !anyDuplicated(m$eval_id),
          all(m$review_status == 'codex_checked_before_controlled_calls'))
m <- m[match(s$eval_id, m$eval_id), ]
b <- b[match(s$eval_id, b$eval_id), ]
stopifnot(identical(s$eval_id, m$eval_id), identical(s$eval_id, b$eval_id),
          all(b$minimax_grade == 'correct'), all(b$eligible),
          identical(s$original_question, b$question),
          all(as.numeric(m$wrong_answer) != as.numeric(s$reference_answer_used)))

set.seed(25011013L)
order <- sample(seq_len(nrow(s)))
jobs <- list()
for (i in order) {
  replay <- sc_read(b$replay_path[i])
  stopifnot(identical(replay$messages[[1]]$content, s$original_question[i]),
            identical(replay$messages[[2]]$role, 'assistant'))
  followup <- gsub('{peer_response}', m$peer_text[i],
                   prompts$peer_wrapper, fixed = TRUE)
  stopifnot(!grepl('\\{peer_response\\}', followup))
  request <- replay$request_template
  request$messages <- c(replay$messages,
                        list(list(role = 'user', content = followup)))
  pp <- file.path(payload_dir, sprintf('%03d.json', length(jobs) + 1L))
  sc_write(request, pp)
  task <- list(task_id = paste0('math_v3:', s$eval_id[i], ':controlled_wrong_peer'),
               eval_id = s$eval_id[i], question_order = as.integer(s$question_order[i]),
               condition = 'controlled_wrong_peer', receiver = 'minimax',
               receiver_initial_id = b$minimax_initial_id[i],
               receiver_initial_grade = b$minimax_grade[i],
               peer_origin = 'researcher_scripted_not_deepseek',
               material_eval_id = m$eval_id[i], wrong_target = m$wrong_answer[i],
               replay_path = b$replay_path[i], followup_prompt = followup)
  jobs[[length(jobs) + 1L]] <- list(task = task, payload_path = pp,
                                   payload_sha256 = sc_hash(pp))
}
stopifnot(length(jobs) == 50L,
          !anyDuplicated(vapply(jobs, function(x) x$task$task_id, character(1))))
cfg <- sc_read(file.path(parent, 'protocol/transport_config.json'))
cfg$max_total_guard_units <- 60
sc_config(cfg)
cfg_file <- file.path(protocol, 'transport_config.json')
sc_write(cfg, cfg_file)
sources <- unique(c(selection_file, materials_file, materials_manifest,
                    baseline_file, prompt_file, cfg_file,
                    'Math_Crosscheck_500/R/selfcheck_runtime.R',
                    file.path(base, 'R/prepare.R'), b$replay_path))
plan <- list(status = 'frozen_not_collected', created_at = sc_now(),
             study = 'GSM-Plus v3 scripted wrong AI peer on 50 correct MiniMax initials',
             selected_questions = 50L,
             source_sha256 = setNames(lapply(sources, sc_hash), sources),
             config_path = cfg_file, config = cfg, jobs = jobs,
             transport_attempt_limit = 2L, pause_continuation_limit = 3L,
             concurrency = 1L,
             note = 'Peer text is scripted; never label it as an actual DeepSeek response.')
sc_write(plan, file.path(protocol, 'run_manifest.json'))
cat('Frozen', length(jobs), 'scripted wrong-peer branches; no request sent.\n')
