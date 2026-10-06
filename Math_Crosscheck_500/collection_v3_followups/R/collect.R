#!/usr/bin/env Rscript

# Execute only the frozen v3 self/natural branch schedule. Authentication is
# loaded from the existing private credential pointer, never persisted here.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
source('Math_Crosscheck_500/R/selfcheck_runtime.R')
base <- 'Math_Crosscheck_500/collection_v3_followups'
manifest_file <- file.path(base, 'protocol/run_manifest.json')
freeze_file <- file.path(base, 'protocol/collector_freeze.json')
run_dir <- file.path(base, 'runs')
dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(freeze_file))
freeze <- sc_read(freeze_file)
stopifnot(identical(freeze$collector_sha256, sc_hash(file.path(base, 'R/collect.R'))),
          identical(freeze$manifest_sha256, sc_hash(manifest_file)))
plan <- sc_read(manifest_file)
sc_verify(plan)
stopifnot(length(plan$jobs) == 992L,
          identical(plan$config$model, 'MiniMax-M3'))

ptr <- '/private/tmp/comp2501-two-model-credential-path.txt'
if (!file.exists(ptr)) stop('Private credential pointer unavailable.')
cp <- readLines(ptr, warn = FALSE)
if (length(cp) != 1L || !startsWith(cp, '/private/tmp/') || !file.exists(cp))
  stop('Private credential location invalid.')
creds <- readRDS(cp)
if (!'MINIMAX_API_KEY' %in% names(creds) || !nzchar(creds$MINIMAX_API_KEY))
  stop('MiniMax credential unavailable.')
Sys.setenv(MINIMAX_API_KEY = creds$MINIMAX_API_KEY)
rm(creds)

args <- commandArgs(trailingOnly = TRUE)
if (any(!args %in% c('--preflight','--pilot','2'))) stop('Unknown argument.')
if ('--preflight' %in% args) {
  cat('Preflight passed: 992 immutable branch payloads, source hashes and private credential present; no request sent.\n')
  quit(save = 'no', status = 0)
}
limit <- if ('--pilot' %in% args) 2L else length(plan$jobs)
if ('--pilot' %in% args && !('2' %in% args)) stop('Only the frozen first-two-task pilot is supported.')

write_status <- function() {
  finals <- list.files(run_dir, pattern = '^final\\.json$', recursive = TRUE,
                       full.names = TRUE)
  states <- if (length(finals)) vapply(finals, function(p) sc_read(p)$status, character(1))
            else character()
  x <- list(state = if (length(finals) == length(plan$jobs)) 'finished' else 'running',
            updated_at = sc_now(), planned = length(plan$jobs), completed = length(finals),
            complete_pending_grade = sum(states == 'complete_pending_grade'),
            technical_incomplete = sum(states != 'complete_pending_grade'),
            remaining = length(plan$jobs) - length(finals))
  sp <- file.path(run_dir, 'status.json')
  tmp <- paste0(sp, '.tmp-', Sys.getpid())
  write_json(x, tmp, pretty = TRUE, auto_unbox = TRUE)
  if (!file.rename(tmp, sp)) stop('Status checkpoint write failed.')
  invisible(x)
}
write_status()
for (i in seq_len(limit)) {
  task_id <- plan$jobs[[i]]$task$task_id
  sc_run_one(plan, task_id, run_dir)
  if (i %% 10L == 0L || i == limit) {
    status <- write_status()
    cat('Branch', status$completed, '/', status$planned, '\n')
  }
}
