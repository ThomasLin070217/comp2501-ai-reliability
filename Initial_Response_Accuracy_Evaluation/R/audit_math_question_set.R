# Independent integrity audit of the frozen 500-item math question set.
# Run from the repository root: Rscript Initial_Response_Accuracy_Evaluation/R/audit_math_question_set.R
suppressPackageStartupMessages(library(jsonlite))

base <- "Initial_Response_Accuracy_Evaluation"
inputs <- read.csv(file.path(base, "math_model_inputs_500.csv"), check.names = FALSE)
key <- read.csv(file.path(base, "math_scoring_key_500.csv"), check.names = FALSE)
source <- read.csv(file.path(base, "source_data/hendrycks_math_test_all.csv"), check.names = FALSE)
old_questions <- fromJSON("Two_Model_Collection/math/protocol/questions.json", simplifyVector = FALSE)
old_references <- fromJSON("Two_Model_Collection/math/protocol/researcher_reference.json", simplifyVector = FALSE)

stopifnot(nrow(inputs) == 500L, nrow(key) == 500L, nrow(source) == 5000L,
          identical(sort(inputs$question_order), 1:500),
          !anyNA(inputs$eval_id), !anyDuplicated(inputs$eval_id),
          !anyNA(key$eval_id), !anyDuplicated(key$eval_id),
          setequal(inputs$eval_id, key$eval_id),
          !anyNA(inputs$input_text), all(nzchar(trimws(inputs$input_text))),
          !anyNA(key$reference_answer), all(nzchar(trimws(key$reference_answer))))

normalize_question <- function(x) tolower(gsub("[^[:alnum:]]+", " ", trimws(x)))
stopifnot(!anyDuplicated(normalize_question(inputs$input_text)))

# Parse independently of the build script: keep the content of the last balanced
# \boxed{...} expression, allowing nested braces such as \frac{1}{2}.
last_boxed <- function(x) {
  starts <- gregexpr("\\\\boxed[[:space:]]*\\{", x, perl = TRUE)[[1L]]
  if (starts[1L] < 0L) return(NA_character_)
  chars <- strsplit(x, "", fixed = TRUE)[[1L]]
  answers <- character()
  for (start in starts) {
    left <- start + attr(starts, "match.length")[which(starts == start)[1L]] - 1L
    depth <- 0L
    right <- NA_integer_
    for (pos in left:length(chars)) {
      if (chars[pos] == "{" && (pos == 1L || chars[pos - 1L] != "\\")) depth <- depth + 1L
      if (chars[pos] == "}" && (pos == 1L || chars[pos - 1L] != "\\")) {
        depth <- depth - 1L
        if (depth == 0L) { right <- pos; break }
      }
    }
    if (!is.na(right)) answers <- c(answers, paste(chars[(left + 1L):(right - 1L)], collapse = ""))
  }
  if (length(answers)) tail(answers, 1L) else NA_character_
}

items <- inputs[order(inputs$question_order), ]
items <- cbind(items, key[match(items$eval_id, key$eval_id),
                           setdiff(names(key), "eval_id"), drop = FALSE])
is_math <- items$source_benchmark == "Hendrycks MATH test"
is_champ <- items$source_benchmark == "CHAMP existing formal set"
stopifnot(sum(is_math) == 459L, sum(is_champ) == 41L,
          all(is_math | is_champ))

source_index <- match(items$source_record_id[is_math], source$source_record_id)
stopifnot(!anyNA(source_index),
          identical(items$input_text[is_math], source$problem[source_index]))
reparsed <- vapply(source$solution[source_index], last_boxed, character(1L))
stopifnot(!anyNA(reparsed), all(items$reference_answer[is_math] == reparsed))

old_ids <- vapply(old_questions, `[[`, "", "question_id")
old_text <- setNames(vapply(old_questions, `[[`, "", "question"), old_ids)
old_answers <- setNames(vapply(old_references, `[[`, "", "reference_answer"),
                        vapply(old_references, `[[`, "", "question_id"))
stopifnot(setequal(items$source_record_id[is_champ], old_ids),
          identical(items$input_text[is_champ], unname(old_text[items$source_record_id[is_champ]])),
          identical(items$reference_answer[is_champ],
                    unname(old_answers[items$source_record_id[is_champ]])))

visual_markup <- grepl("[asy]", items$input_text, fixed = TRUE) |
  grepl("\\\\includegraphics|\\\\begin\\{tikzpicture\\}|\\\\begin\\{picture\\}",
        items$input_text, perl = TRUE)
visual_wording <- grepl("(in|from) the (figure|diagram|picture)|figure (above|below)|diagram (above|below)|shown in the (figure|diagram)",
                       items$input_text, ignore.case = TRUE, perl = TRUE)
numeric_key <- grepl("^-?[0-9]+(\\.[0-9]+)?$", trimws(items$reference_answer))
answer_class <- ifelse(numeric_key, "plain_numeric", "symbolic_or_text")

audit <- data.frame(question_order = items$question_order,
                    eval_id = items$eval_id,
                    source_benchmark = items$source_benchmark,
                    subject = items$subject,
                    difficulty = items$difficulty,
                    source_record_id = items$source_record_id,
                    source_text_and_key_match = TRUE,
                    visual_markup = visual_markup,
                    possible_visual_reference = visual_wording,
                    answer_class = answer_class,
                    stringsAsFactors = FALSE)
write.csv(audit, file.path(base, "math_question_quality_audit.csv"),
          row.names = FALSE, fileEncoding = "UTF-8", na = "")

report <- c(
  "# 500-question math set: integrity audit",
  "",
  "Audit run with `R/audit_math_question_set.R`. The question bank is already frozen; this script does not resample or edit it.",
  "",
  sprintf("- Total: %d unique questions; CHAMP: %d; Hendrycks MATH test: %d.",
          nrow(items), sum(is_champ), sum(is_math)),
  "- All 459 new question texts and extracted final boxed answers match the saved 5,000-row source snapshot.",
  "- All 41 reused CHAMP question texts and keys match their original protocol files.",
  sprintf("- Missing questions/keys, duplicate IDs/text, and embedded image markup: 0 / 0 / %d.",
          sum(visual_markup)),
  sprintf("- Possible wording references to an unseen diagram: %d; inspect flagged rows in the audit CSV.",
          sum(visual_wording)),
  sprintf("- Plain numeric keys: %d; symbolic, fractional, tuple, expression, or text keys: %d.",
          sum(numeric_key), sum(!numeric_key)),
  "",
  "The audit establishes file and source consistency, not independent mathematical proof of all 500 reference solutions. Do not grade symbolic/text answers by raw string equality. Preserve model output and adjudicate equivalent expressions or ambiguous answers separately. Keep `math_scoring_key_500.csv` hidden from tested models. The 41 reused CHAMP items and 459 newly sampled MATH items have different collection histories; analyze them by source as well as in the planned pooled set."
)
writeLines(report, file.path(base, "MATH_500_AUDIT.md"), useBytes = TRUE)
cat(paste(report, collapse = "\n"), "\n")
