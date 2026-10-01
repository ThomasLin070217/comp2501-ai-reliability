#!/usr/bin/env Rscript
# Compare two independently generated R output directories, without changing data.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript Peer_Misleading_Study/R/verify_reproduction.R FIRST SECOND")
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
source(file.path(dirname(normalizePath(script)), "core.R"))
files <- function(dir) {
  x <- list.files(dir, pattern = "\\.(csv|json|jsonl|md)$", recursive = TRUE)
  setdiff(x, "reproducibility.json")
}
a <- files(args[1]); b <- files(args[2]); assert(identical(a, b), "Output file sets differ")
checks <- lapply(a, function(path) {
  left <- file_sha(file.path(args[1], path)); right <- file_sha(file.path(args[2], path))
  assert(left == right, paste("Output differs:", path))
  list(path = path, sha256 = left, matches = TRUE)
})
write_json(list(status = "passed", matching_files = length(checks), checks = checks,
  excluded = "Graphics, HTML, and sessionInfo; PDF metadata may vary. CSV, JSON, JSONL and Markdown are byte-compared.",
  independent_human_review_complete = FALSE), file.path(args[1], "reproducibility.json"))
cat(length(checks), "R-derived data and report files are byte-identical.\n")
