# Build a 500-item math set: reuse 41 formal CHAMP questions and sample 459
# nonduplicate text-only questions from the full MATH test split.
suppressPackageStartupMessages({library(jsonlite); library(digest)})

root <- normalizePath(".", winslash = "/")
base <- file.path(root, "Initial_Response_Accuracy_Evaluation")
src_dir <- file.path(base, "source_data")
dir.create(src_dir, recursive = TRUE, showWarnings = FALSE)
source_csv <- file.path(src_dir, "hendrycks_math_test_all.csv")

if (!file.exists(source_csv)) {
  configs <- c("algebra", "counting_and_probability", "geometry",
               "intermediate_algebra", "number_theory", "prealgebra", "precalculus")
  page_cache <- file.path(src_dir, "hendrycks_math_test_pages")
  dir.create(page_cache, recursive = TRUE, showWarnings = FALSE)
  records <- list()
  for (subject in configs) {
    offset <- 0L
    repeat {
      cache_file <- file.path(page_cache, paste0(subject, "_", offset, ".json"))
      if (file.exists(cache_file)) {
        page <- jsonlite::fromJSON(cache_file, simplifyVector = FALSE)
      } else {
        url <- paste0("https://datasets-server.huggingface.co/rows?dataset=",
                      utils::URLencode("EleutherAI/hendrycks_math", reserved = TRUE),
                      "&config=", subject, "&split=test&offset=", offset, "&length=100")
        fetched <- NULL
        for (attempt in seq_len(6L)) {
          fetched <- curl::curl_fetch_memory(url)
          if (fetched$status_code == 200L) break
          if (fetched$status_code != 429L) {
            stop("Dataset API returned HTTP ", fetched$status_code, " for ", subject, " offset ", offset)
          }
          Sys.sleep(min(60, 10 * attempt))
        }
        if (is.null(fetched) || fetched$status_code != 200L) {
          stop("Rate-limited after retries for ", subject, " offset ", offset)
        }
        writeBin(fetched$content, cache_file)
        page <- jsonlite::fromJSON(cache_file, simplifyVector = FALSE)
        Sys.sleep(2)
      }
      rows <- page$rows
      if (!length(rows)) break
      for (i in seq_along(rows)) {
        r <- rows[[i]]
        records[[length(records) + 1L]] <- data.frame(
          source_record_id = paste0("test/", subject, "/", r$row_idx),
          subject = subject,
          difficulty = suppressWarnings(as.integer(gsub("[^0-9]", "", r$row$level))),
          problem_type = r$row$type,
          problem = r$row$problem,
          solution = r$row$solution,
          stringsAsFactors = FALSE
        )
      }
      offset <- offset + length(rows)
      if (length(rows) < 100L) break
    }
    cat(subject, "downloaded through offset", offset, "\n")
  }
  source_data <- do.call(rbind, records)
  stopifnot(nrow(source_data) == 5000L, !anyDuplicated(source_data$source_record_id))
  write.csv(source_data, source_csv, row.names = FALSE, fileEncoding = "UTF-8", na = "")
}

source_data <- read.csv(source_csv, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(source_data) == 5000L,
          all(c("source_record_id", "subject", "difficulty", "problem", "solution") %in% names(source_data)))

extract_last_boxed <- function(solution) {
  if (is.na(solution) || !nzchar(solution)) return(NA_character_)
  starts <- gregexpr("\\\\boxed[[:space:]]*\\{", solution, perl = TRUE)[[1]]
  if (starts[1] < 0L) return(NA_character_)
  results <- character()
  chars <- strsplit(solution, "", fixed = TRUE)[[1]]
  for (start in starts) {
    brace <- start
    while (brace <= length(chars) && chars[brace] != "{") brace <- brace + 1L
    depth <- 0L
    escaped <- FALSE
    end <- NA_integer_
    for (i in brace:length(chars)) {
      ch <- chars[i]
      if (ch == "\\" && !escaped) { escaped <- TRUE; next }
      if (ch == "{" && !escaped) depth <- depth + 1L
      if (ch == "}" && !escaped) {
        depth <- depth - 1L
        if (depth == 0L) { end <- i; break }
      }
      escaped <- FALSE
    }
    if (!is.na(end) && end > brace) results <- c(results, paste(chars[(brace + 1L):(end - 1L)], collapse = ""))
  }
  if (!length(results)) NA_character_ else tail(results, 1L)
}

normalize_question <- function(x) tolower(gsub("[^[:alnum:]]+", " ", trimws(x)))
old_questions <- jsonlite::fromJSON(
  file.path(root, "Two_Model_Collection/math/protocol/questions.json"),
  simplifyVector = FALSE
)
old_refs <- jsonlite::fromJSON(
  file.path(root, "Two_Model_Collection/math/protocol/researcher_reference.json"),
  simplifyVector = FALSE
)
all_responses <- read.csv(file.path(root, "All_Experiment_Data/all_experiment_responses.csv"),
                          stringsAsFactors = FALSE, check.names = FALSE)
old_initial_texts <- unique(all_responses$question_text[
  all_responses$domain == "math" &
    all_responses$condition %in% c("neutral_initial", "baseline") &
    all_responses$provider %in% c("deepseek", "minimax")
])
old_norm <- unique(normalize_question(c(
  vapply(old_questions, `[[`, "", "question"), old_initial_texts
)))
source_norm <- normalize_question(source_data$problem)
has_asy <- grepl("[asy]", source_data$problem, fixed = TRUE)
is_duplicate <- source_norm %in% old_norm
reference <- vapply(source_data$solution, extract_last_boxed, character(1))
has_reference <- !is.na(reference) & nzchar(reference)
eligible <- source_data[!has_asy & !is_duplicate & has_reference, , drop = FALSE]
eligible$reference_answer <- reference[!has_asy & !is_duplicate & has_reference]
if (nrow(eligible) < 459L) {
  stop(sprintf("Only %d eligible MATH test problems remain (needed: 459). Excluded Asymptote=%d, prior duplicates=%d, no boxed reference=%d.",
               nrow(eligible), sum(has_asy), sum(is_duplicate), sum(!has_reference)))
}

# Proportional largest-remainder sampling across subject x difficulty.
set.seed(25011008)
eligible$stratum <- paste(eligible$subject, eligible$difficulty, sep = "|L")
counts <- table(eligible$stratum)
allocation <- 459 * as.numeric(counts) / sum(counts)
take <- floor(allocation)
remainder <- 459L - sum(take)
if (remainder > 0L) {
  chosen <- order(allocation - take, decreasing = TRUE)[seq_len(remainder)]
  take[chosen] <- take[chosen] + 1L
}
names(take) <- names(counts)
selected <- do.call(rbind, lapply(names(take), function(s) {
  pool <- eligible[eligible$stratum == s, , drop = FALSE]
  pool[sample.int(nrow(pool), take[[s]]), , drop = FALSE]
}))
selected$stratum <- NULL
selected <- selected[sample.int(nrow(selected)), , drop = FALSE]

old_reference <- setNames(vapply(old_refs, `[[`, "", "reference_answer"),
                          vapply(old_refs, `[[`, "", "question_id"))
champ <- do.call(rbind, lapply(old_questions, function(q) {
  data.frame(
    eval_id = paste0("CHAMP_", gsub("[^A-Za-z0-9]+", "_", q$question_id)),
    source_record_id = q$question_id,
    input_text = q$question,
    reference_answer = old_reference[[q$question_id]],
    source_benchmark = "CHAMP existing formal set",
    subject = q$family,
    difficulty = NA_integer_,
    stringsAsFactors = FALSE
  )
}))
math_new <- data.frame(
  eval_id = paste0("MATH_", gsub("[^A-Za-z0-9]+", "_", selected$source_record_id)),
  source_record_id = selected$source_record_id,
  input_text = selected$problem,
  reference_answer = selected$reference_answer,
  source_benchmark = "Hendrycks MATH test",
  subject = selected$subject,
  difficulty = selected$difficulty,
  stringsAsFactors = FALSE
)
all_items <- rbind(champ, math_new)
stopifnot(nrow(all_items) == 500L, !anyDuplicated(all_items$eval_id),
          !anyDuplicated(normalize_question(all_items$input_text)),
          all(nzchar(all_items$input_text)), all(nzchar(all_items$reference_answer)),
          !any(grepl("[asy]", math_new$input_text, fixed = TRUE)))
all_items <- all_items[sample.int(nrow(all_items)), , drop = FALSE]
all_items$question_order <- seq_len(nrow(all_items))
all_items <- all_items[, c("question_order", "eval_id", "input_text", "source_record_id",
                           "reference_answer", "source_benchmark", "subject", "difficulty")]
model_input <- all_items[, c("question_order", "eval_id", "input_text")]
score_key <- all_items[, setdiff(names(all_items), c("question_order", "input_text"))]
selected_audit <- math_new[, c("eval_id", "source_record_id", "input_text", "reference_answer",
                               "source_benchmark", "subject", "difficulty")]
source_counts <- as.data.frame(table(all_items$source_benchmark), stringsAsFactors = FALSE)
names(source_counts) <- c("source_benchmark", "question_count")
math_strata <- as.data.frame(table(selected$subject, selected$difficulty), stringsAsFactors = FALSE)
names(math_strata) <- c("subject", "difficulty", "question_count")
math_strata <- math_strata[math_strata$question_count > 0, ]

write.csv(model_input, file.path(base, "math_model_inputs_500.csv"), row.names = FALSE,
          fileEncoding = "UTF-8", na = "")
write.csv(score_key, file.path(base, "math_scoring_key_500.csv"), row.names = FALSE,
          fileEncoding = "UTF-8", na = "")
write.csv(selected_audit, file.path(base, "math_selected_459_audit.csv"), row.names = FALSE,
          fileEncoding = "UTF-8", na = "")
write.csv(source_counts, file.path(base, "math_source_counts.csv"), row.names = FALSE,
          fileEncoding = "UTF-8", na = "")
write.csv(math_strata, file.path(base, "math_subject_difficulty_counts.csv"), row.names = FALSE,
          fileEncoding = "UTF-8", na = "")
unlink(file.path(src_dir, "math500_test.jsonl"))
cat("Eligible MATH test rows:", nrow(eligible),
    "| excluded Asymptote diagrams:", sum(has_asy),
    "| excluded prior matches:", sum(is_duplicate),
    "| no boxed reference:", sum(!has_reference), "\n")
print(source_counts)
cat("MATH test source SHA256:", digest(file = source_csv, algo = "sha256"), "\n")
