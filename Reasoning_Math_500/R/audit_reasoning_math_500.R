# Source and file-integrity audit of the fixed easier-reasoning question set.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
base <- "Reasoning_Math_500"
inputs <- read.csv(file.path(base, "model_inputs_500.csv"), check.names = FALSE)
key <- read.csv(file.path(base, "scoring_key_500.csv"), check.names = FALSE)
first <- read.csv(file.path(base, "first_batch_100.csv"), check.names = FALSE)
source_file <- file.path(base, "source_data/gsmplus_v1_test.jsonl")
source <- stream_in(file(source_file), verbose = FALSE)
manifest <- fromJSON(file.path(base, "selection_manifest.json"), simplifyVector = FALSE)
normalize <- function(s) tolower(gsub("[^[:alnum:]]+", " ", trimws(s)))

stopifnot(nrow(inputs) == 500L, nrow(key) == 500L, nrow(first) == 100L,
          identical(inputs$question_order, 1:500),
          identical(first, inputs[1:100, ]),
          !anyDuplicated(inputs$eval_id), !anyDuplicated(key$eval_id),
          identical(inputs$eval_id, key$eval_id),
          !anyDuplicated(normalize(inputs$input_text)),
          !anyDuplicated(key$seed_id),
          all(nzchar(inputs$input_text)),
          all(key$source_row >= 1L & key$source_row <= nrow(source)),
          all(inputs$input_text == source$question[key$source_row]),
          all(key$reference_answer == source$answer[key$source_row]),
          all(key$source_solution == source$solution[key$source_row]),
          all(key$perturbation_type == source$perturbation_type[key$source_row]),
          all(nchar(inputs$input_text) <= 300L),
          all(key$max_number_in_question <= 1000),
          all(key$planned_batch[1:100] == "first_100"),
          all(key$planned_batch[101:500] == "remaining_400"))
stopifnot(!any(key$source_row %in% as.integer(names(manifest$manually_excluded_source_rows))))

expected <- c("critical thinking" = 150L,
              "distraction insertion" = 200L,
              "problem understanding" = 150L)
counts <- table(key$perturbation_type)
stopifnot(identical(as.integer(counts[names(expected)]), as.integer(expected)))
first_counts <- table(key$perturbation_type[1:100])
stopifnot(identical(as.integer(first_counts[names(expected)]), c(30L, 40L, 30L)))

missing <- key$answer_kind == "insufficient_information"
numeric <- key$answer_kind == "numeric"
stopifnot(sum(missing) == 150L, sum(numeric) == 350L,
          all(key$reference_answer[missing] == "None"),
          all(is.finite(suppressWarnings(as.numeric(key$reference_answer[numeric])))),
          all(abs(suppressWarnings(as.numeric(key$reference_answer[numeric]))) <= 1000))

old <- fromJSON("Two_Model_Collection/math/protocol/questions.json", simplifyVector = FALSE)
old_text <- vapply(old, `[[`, "", "question")
stopifnot(!any(normalize(inputs$input_text) %in% normalize(old_text)))

text <- c(
  "# Easier reasoning-math set: audit",
  "",
  sprintf("- Source: GSM-Plus v1 test, revision `%s`; source SHA-256 `%s`.",
          "3b708db57b96a16e8e3368ed2956990c0809440e",
          digest(file = source_file, algo = "sha256")),
  "- 500 unique question texts and 500 distinct base problems; every selected question, answer, and solution matches the downloaded source row.",
  "- 200 irrelevant-information questions, 150 missing-information questions, and 150 rephrased word problems.",
  "- The first 100 are a fixed balanced batch: 40 / 30 / 30 in the same category order.",
  "- Every question is at most 300 characters; every number in the question is at most 1,000; 350 reference answers are numeric and 150 are `None` because a required condition is missing.",
  "- No exact normalized overlap with the earlier 41 formal CHAMP questions.",
  "- Five mislabeled source questions were excluded after manual logic review; their IDs, reasons, and replacements are recorded in the selection manifest.",
  "",
  "This is an integrity and source-consistency audit, not independent mathematical verification of all 500 benchmark answers. Score a missing-information item as *correct* only when the response explains that the requested number cannot be determined from the given facts; a generic 'I don't know' is an abstention. Numeric items require semantic equivalence, not raw string equality. Keep both outcomes distinct in analysis."
)
writeLines(text, file.path(base, "AUDIT.md"), useBytes = TRUE)
cat(paste(text, collapse = "\n"), "\n")
