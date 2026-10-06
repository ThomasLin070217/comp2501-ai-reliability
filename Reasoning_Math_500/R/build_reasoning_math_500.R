# Build a shorter, elementary-arithmetic reasoning benchmark from GSM-Plus v1.
# Run from the repository root with Rscript Reasoning_Math_500/R/build_reasoning_math_500.R.
suppressPackageStartupMessages({library(jsonlite); library(digest)})

base <- "Reasoning_Math_500"
dir.create(file.path(base, "source_data"), recursive = TRUE, showWarnings = FALSE)
source_file <- file.path(base, "source_data", "gsmplus_v1_test.jsonl")
source_revision <- "3b708db57b96a16e8e3368ed2956990c0809440e"
source_sha256 <- "885c279bfa9cde767ea23f79fd462d566fa0dbf6af9f2dcf30c75aa94f3d4041"
source_url <- paste0("https://huggingface.co/datasets/qintongli/GSM-Plus/resolve/",
                     source_revision, "/data/test-00000-of-00001.jsonl")
if (!file.exists(source_file)) download.file(source_url, source_file, mode = "wb", quiet = TRUE)
stopifnot(identical(digest(file = source_file, algo = "sha256"), source_sha256))

source <- jsonlite::stream_in(file(source_file), verbose = FALSE)
stopifnot(nrow(source) == 10552L,
          all(c("question", "solution", "answer", "perturbation_type", "seed_question") %in% names(source)))
source$source_row <- seq_len(nrow(source))
source$seed_id <- vapply(source$seed_question,
                         function(s) digest(s, algo = "sha256", serialize = FALSE), "")

max_number <- function(s) {
  matches <- regmatches(s, gregexpr("[0-9][0-9,]*(\\.[0-9]+)?", s, perl = TRUE))[[1L]]
  if (!length(matches)) return(0)
  max(suppressWarnings(as.numeric(gsub(",", "", matches))), na.rm = TRUE)
}

source$question_chars <- nchar(source$question, type = "chars")
source$max_number_in_question <- vapply(source$question, max_number, 0.0)
source$numeric_answer <- suppressWarnings(as.numeric(gsub(",", "", source$answer)))
source$eligible <- source$perturbation_type %in%
  c("distraction insertion", "critical thinking", "problem understanding") &
  source$question_chars <= 300L & source$max_number_in_question <= 1000 &
  !grepl("[asy]", source$question, fixed = TRUE) &
  !grepl("\\", source$question, fixed = TRUE) &
  (source$perturbation_type == "critical thinking" |
     (!is.na(source$numeric_answer) & abs(source$numeric_answer) <= 1000))

# Preserve comparability with the earlier 41-question study without silently
# recycling one of its questions into a newly collected 500-item set.
normalize_question <- function(s) tolower(gsub("[^[:alnum:]]+", " ", trimws(s)))
old <- jsonlite::fromJSON("Two_Model_Collection/math/protocol/questions.json",
                          simplifyVector = FALSE)
old_text <- vapply(old, `[[`, "", "question")
source$eligible <- source$eligible &
  !(normalize_question(source$question) %in% normalize_question(old_text))

# Predeclared quotas emphasize reading/logic over arithmetic. Each question
# comes from a different GSM8K seed, so paraphrases of the same base problem
# never appear twice in this 500-question evaluation set.
quotas <- c("distraction insertion" = 200L,
            "critical thinking" = 150L,
            "problem understanding" = 150L)
set.seed(25011009)
used_seeds <- character()
selected <- integer()
for (type in names(quotas)) {
  pool <- which(source$eligible & source$perturbation_type == type &
                !(source$seed_id %in% used_seeds))
  stopifnot(length(pool) >= quotas[[type]])
  pick <- sample(pool, quotas[[type]], replace = FALSE)
  selected <- c(selected, pick)
  used_seeds <- c(used_seeds, source$seed_id[pick])
}
selected <- sample(selected, length(selected), replace = FALSE)
# Five source "critical thinking" keys fail a direct logic check despite their
# `None` reference: the question itself determines a numeric answer. Keep the
# rest of the sampled set stable and replace only these fixed source rows.
manual_exclusions <- c("9944" = "Half of 100 hats are red and the rest white: 50 white hats.",
                       "8416" = "Eight cups per day for 30 days converts using 16 cups per gallon.",
                       "2760" = "Juice C costs two dollars more than Juice B.",
                       "3432" = "Of 40 guests, 20 cannot receive a second hotdog.",
                       "2464" = "The question directly states Sandy needs four weeks.")
replacement_pairs <- list()
for (bad in as.integer(names(manual_exclusions))) {
  hit <- which(selected == bad)
  if (!length(hit)) next
  type <- source$perturbation_type[bad]
  pool <- which(source$eligible & source$perturbation_type == type &
                !(source$seed_id %in% source$seed_id[selected]) &
                !(source$source_row %in% as.integer(names(manual_exclusions))))
  stopifnot(length(pool) > 0L)
  selected[hit] <- sample(pool, 1L)
  replacement_pairs[[as.character(bad)]] <- source$source_row[selected[hit]]
}
first_batch_quota <- c("distraction insertion" = 40L,
                       "critical thinking" = 30L,
                       "problem understanding" = 30L)
first_batch <- unlist(lapply(names(first_batch_quota), function(type) {
  candidates <- selected[source$perturbation_type[selected] == type]
  head(candidates, first_batch_quota[[type]])
}), use.names = FALSE)
selected <- c(sample(first_batch), sample(selected[!(selected %in% first_batch)]))
items <- source[selected, ]
items$eval_id <- sprintf("GSMPLUS_V1_%05d", items$source_row)
items$question_order <- seq_len(nrow(items))
items$planned_batch <- ifelse(items$question_order <= 100L, "first_100", "remaining_400")
items$answer_kind <- ifelse(items$perturbation_type == "critical thinking",
                            "insufficient_information", "numeric")

stopifnot(nrow(items) == 500L, !anyDuplicated(items$eval_id),
          !anyDuplicated(items$seed_id),
          !anyDuplicated(normalize_question(items$question)),
          all(nzchar(items$question)),
          all(items$answer[items$answer_kind == "insufficient_information"] == "None"),
          all(!is.na(items$numeric_answer[items$answer_kind == "numeric"])))

model_inputs <- data.frame(question_order = items$question_order,
                           eval_id = items$eval_id,
                           input_text = items$question)
answer_key <- data.frame(eval_id = items$eval_id,
                         source_row = items$source_row,
                         source_benchmark = "GSM-Plus v1 test",
                         perturbation_type = items$perturbation_type,
                         seed_id = items$seed_id,
                         answer_kind = items$answer_kind,
                         planned_batch = items$planned_batch,
                         reference_answer = items$answer,
                         source_solution = items$solution,
                         question_chars = items$question_chars,
                         max_number_in_question = items$max_number_in_question,
                         stringsAsFactors = FALSE)
composition <- as.data.frame(table(items$perturbation_type), stringsAsFactors = FALSE)
names(composition) <- c("perturbation_type", "question_count")
manifest <- list(source_url = source_url,
                 source_sha256 = source_sha256,
                 R_seed = 25011009L,
                 quotas = as.list(quotas),
                 first_batch_quotas = as.list(first_batch_quota),
                 manually_excluded_source_rows = as.list(manual_exclusions),
                 replacement_source_rows = replacement_pairs,
                 max_question_characters = 300L,
                 max_number_in_question = 1000L,
                 max_absolute_numeric_answer = 1000L,
                 distinct_base_problems = length(unique(items$seed_id)),
                 selected_source_rows = items$source_row)

write.csv(model_inputs, file.path(base, "model_inputs_500.csv"), row.names = FALSE,
          fileEncoding = "UTF-8", na = "")
write.csv(answer_key, file.path(base, "scoring_key_500.csv"), row.names = FALSE,
          fileEncoding = "UTF-8", na = "")
write.csv(model_inputs[seq_len(100L), ], file.path(base, "first_batch_100.csv"),
          row.names = FALSE, fileEncoding = "UTF-8", na = "")
write.csv(composition, file.path(base, "composition.csv"), row.names = FALSE,
          fileEncoding = "UTF-8", na = "")
write_json(manifest, file.path(base, "selection_manifest.json"),
           pretty = TRUE, auto_unbox = TRUE)
cat("Selected", nrow(items), "unique questions from", length(unique(items$seed_id)),
    "base problems.\n")
print(composition)
cat("Maximum question length:", max(items$question_chars), "characters.\n")
