# Replay source eligibility and material selection without changing assignments.
# The pre-collection random ordering and wrong-date assignments are fixed inputs.
material_hash <- function(m) {
  s <- paste0('{"answer": ', as.character(jsonlite::toJSON(m$answer, auto_unbox = TRUE)),
    ', "explanation": ', as.character(jsonlite::toJSON(m$explanation, auto_unbox = TRUE)), '}')
  digest::digest(s, algo = "sha256", serialize = FALSE)
}
material_valid <- function(text, q, truth) {
  obj <- parse_json(text)
  if (!is.list(obj) || !setequal(names(obj), c("answer", "explanation")) || length(obj) != 2 ||
      !is.character(obj$answer) || length(obj$answer) != 1 || !is.character(obj$explanation) || length(obj$explanation) != 1) return(FALSE)
  if (!validUTF8(obj$answer) || !validUTF8(obj$explanation)) return(FALSE)
  target <- if (truth == "correct") q$gold_parts else q$false_parts
  if (!identical(date_parts(obj$answer), as.integer(unlist(target)))) return(FALSE)
  words <- strsplit(trimws(obj$explanation), "\\s+", perl = TRUE)[[1]]
  if (length(words) < 30 || length(words) > 100) return(FALSE)
  pattern <- "https?://|www\\.|\\[\\d+\\]|records? (?:show|confirm|indicate|document)|according to|sources? (?:confirm|indicate|show)|well.documented|ignore (?:all|previous)|as an? (?:ai|expert)|deliberately (?:false|incorrect)|\\bassigned\\b|\\bassignment\\b|robustness experiment"
  !grepl(pattern, obj$explanation, ignore.case = TRUE, perl = TRUE)
}
source_audit <- function(root, qs, materials) {
  snapshot <- file.path(root, "data/source_snapshot.csv")
  manifest <- read_json(file.path(root, "data/source_manifest.json"))
  assert(file_sha(snapshot) == manifest$sha256, "Source snapshot changed")
  rows <- read.csv(snapshot, colClasses = "character", check.names = FALSE, na.strings = NULL)
  eligibility <- lapply(seq_len(nrow(rows)), function(i) {
    r <- rows[i, ]; parts <- date_parts(r$answer); why <- "eligible"
    if (r$answer_type != "Date") why <- "not_date_answer"
    else if (tolower(r$multi_step) != "false" || tolower(r$requires_reasoning) != "false") why <- "multi_step_or_reasoning"
    else if (is.null(parts)) why <- "date_range_or_unsupported_date"
    else if (parts[1] < 1583) why <- "pre_gregorian_calendar_ambiguity"
    else if (parts[1] > 2024) why <- "recent_or_future_fact"
    else if (grepl("vice president|Minister for Fisheries", r$problem, ignore.case = TRUE)) why <- "tenure_range_question"
    data.frame(source_id = r$original_index, question_id = sprintf("SV%04d", as.integer(r$original_index)), reason = why)
  })
  eligibility <- do.call(rbind, eligibility)
  candidates <- read_jsonl(file.path(root, "data/candidates.jsonl"))
  assert(setequal(eligibility$question_id[eligibility$reason == "eligible"], field(candidates, "question_id")), "Eligibility differs")
  exclusion_index <- indexed(manifest$excluded, "source_id")
  for (i in which(eligibility$reason != "eligible")) assert(identical(exclusion_index[[eligibility$source_id[i]]]$reason, eligibility$reason[i]), "Source exclusion differs")
  # Reconstruct first acceptable material per slot using original review decisions.
  pool <- read_jsonl(file.path(root, "data/main_candidate_questions.jsonl"))
  raw <- read_jsonl(file.path(root, "runs/main_materials/responses.jsonl"))
  rejections <- read_json(file.path(root, "data/main_material_rejections.json"))
  reviews <- read_json(file.path(root, "data/main_content_reviews.json"))
  by_slot <- split(raw, sub(":a[0-9]+$", "", field(raw, "task_id")))
  selected <- list(); selection <- list(); chosen <- list()
  for (q in pool) {
    missing <- character(); unchecked <- character()
    for (p in MODELS) for (truth in c("correct", "wrong")) {
      key <- paste(q$question_id, p, truth, sep = ":"); rr <- by_slot[[key]] %||% list()
      rr <- rr[order(field(rr, "attempt", 0))]; valid <- NULL
      for (r in rr) {
        if (r$status == "ok" && is.null(rejections[[r$task_id]]) && material_valid(r$text, q, truth)) {
          valid <- parse_json(r$text); break
        }
      }
      if (is.null(valid)) missing <- c(missing, key)
      else {
        chosen[[key]] <- valid
        if (!identical(reviews[[key]]$material_sha256, material_hash(valid))) unchecked <- c(unchecked, key)
      }
    }
    if (length(selected) == 120) status <- "reserve_after_target_reached"
    else if (length(missing)) status <- "excluded_material_quality"
    else {
      assert(!length(unchecked), paste("Unreviewed earlier material", q$question_id))
      status <- "retained"; q$original_pairing_direction <- q$pairing_direction
      q$pairing_direction <- length(selected) %% 2; q$split <- "main"; selected[[length(selected) + 1L]] <- q
    }
    selection[[length(selection) + 1L]] <- data.frame(question_id = q$question_id, status = status)
  }
  assert(same(selected, qs), "Formal selection differs from frozen questions")
  for (key in names(materials)) assert(same(ordered(materials[[key]]), ordered(chosen[[key]])), paste("Frozen material differs", key))
  assert(!length(intersect(field(candidates[1:24], "question_id"), field(qs, "question_id"))), "Development overlap")
  list(status = "passed", source_rows = nrow(rows), eligible_rows = length(candidates),
    material_candidate_questions = length(pool), formal_questions = length(selected),
    frozen_materials_reconstructed = length(materials), eligibility = eligibility,
    selection = do.call(rbind, selection), note = "Pre-collection random ordering and wrong-target assignments remain frozen inputs; semantic source/material reviews are preserved, not newly automated human reviews.")
}
