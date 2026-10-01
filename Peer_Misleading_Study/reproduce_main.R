#!/usr/bin/env Rscript
# Entry point: Rscript Peer_Misleading_Study/reproduce_main.R --out NEW_DIRECTORY
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L || args[1] != "--out") stop("Usage: Rscript Peer_Misleading_Study/reproduce_main.R --out NEW_EMPTY_DIRECTORY")
script_arg <- grep("^--file=", commandArgs(), value = TRUE)
root <- dirname(normalizePath(sub("^--file=", "", script_arg[1]), mustWork = TRUE))
source(file.path(root, "R/core.R")); source(file.path(root, "R/outputs.R")); source(file.path(root, "R/source_audit.R"))
out <- args[2]
if (dir.exists(out) && length(list.files(out, all.files = TRUE, no.. = TRUE))) stop("Output must be a new empty directory")
dir.create(out, recursive = TRUE, showWarnings = FALSE); out <- normalizePath(out, mustWork = TRUE)
message("1/8 Check frozen inputs and read raw logs")
inputs <- c("data/main_questions.jsonl", "data/main_frozen/materials.json", "data/main_adjudications.json",
  "data/main_preanalysis_caveats.json", "runs/main_receivers/responses.jsonl", "runs/main_receivers/attempts.jsonl",
  "runs/main_transport_recovery_01/responses.jsonl", "runs/main_transport_recovery_02/responses.jsonl")
hashes <- setNames(lapply(file.path(root, inputs), file_sha), inputs)
frozen <- read_json(file.path(root, "protocol/final-analysis-inputs.json"))$hashes
for (path in intersect(names(frozen), inputs)) assert(identical(hashes[[path]], frozen[[path]]), paste("Frozen input changed:", path))
original_freeze <- read_json(file.path(root, "protocol/formal-receiver-freeze.json"))$hashes
for (path in names(original_freeze)) assert(identical(file_sha(file.path(root, path)), original_freeze[[path]]), paste("Original frozen file changed:", path))
qs <- read_jsonl(file.path(root, "data/main_questions.jsonl"))
materials <- read_json(file.path(root, "data/main_frozen/materials.json"))
decisions <- read_json(file.path(root, "data/main_adjudications.json"))
sources <- source_audit(root, qs, materials)
write_json(sources, file.path(out, "source_audit.json"))
write.csv(sources$eligibility, file.path(out, "source_eligibility.csv"), row.names = FALSE)
write.csv(sources$selection, file.path(out, "material_selection.csv"), row.names = FALSE)
assembly <- assemble(root); records <- assembly$records
branch_audit <- audit_branches(qs, materials, records, assembly$manifest)
write_json(assembly$audit, file.path(out, "collection_audit.json"))
write_json(branch_audit, file.path(out, "branch_audit.json"))
write_jsonl(records, file.path(out, "assembled_responses.jsonl"))
message("2/8 Parse, grade, and apply complete-cell quality rule")
raw_grades <- score_records(qs, records, decisions)
quality <- quality_filter(raw_grades); grades <- quality$grades
filtered_records <- records[field(records, "task_id") %in% grades$task_id]
write.csv(raw_grades, file.path(out, "all_response_grades.csv"), row.names = FALSE, na = "")
write.csv(grades, file.path(out, "graded_responses.csv"), row.names = FALSE, na = "")
qi <- indexed(qs, "question_id"); ri <- indexed(records, "task_id")
flat <- grades
flat$question <- vapply(flat$question_id, function(id) qi[[id]]$question, "")
flat$reference_answer <- vapply(flat$question_id, function(id) qi[[id]]$gold, "")
flat$false_target <- vapply(flat$question_id, function(id) qi[[id]]$false_target, "")
flat$source_url <- vapply(flat$question_id, function(id) qi[[id]]$verified_source_url, "")
flat$response_text <- vapply(flat$task_id, function(id) ri[[id]]$text, "")
write.csv(flat, file.path(out, "analysis_data.csv"), row.names = FALSE, na = "", fileEncoding = "UTF-8")
review_rows <- raw_grades[raw_grades$automatic_grade == "pending", ]
review_rows <- review_rows[!duplicated(review_rows$review_id), ]
queue <- setNames(lapply(seq_len(nrow(review_rows)), function(i) {
  g <- review_rows[i, ]; q <- qi[[g$question_id]]
  list(review_id = g$review_id, question_id = g$question_id, question = q$question, gold = q$gold,
    gold_parts = q$gold_parts, false_parts = q$false_parts, text = ri[[g$task_id]]$text,
    automatic_reason = grade(ri[[g$task_id]]$text, q)$grade_reason)
}), review_rows$review_id)
write_json(queue, file.path(out, "blinded_format_review.json"))
quality$grades <- NULL; write_json(quality, file.path(out, "output_quality.json"))
write_jsonl(filtered_records, file.path(out, "analysis_responses.jsonl"))
message("3/8 Calculate primary tables and question-cluster bootstrap")
primary <- analyze_grades(grades, length(qs)); save_analysis(primary, out)
save_analysis(analyze_grades(raw_grades, length(qs)), file.path(out, "unfiltered_diagnostic"))
message("4/8 Recompute every sensitivity variant and supplementary outcome")
sensitivity <- sensitivity_analysis(root, qs, records, raw_grades, grades, decisions)
write_json(sensitivity, file.path(out, "sensitivity.json"))
st <- do.call(rbind, lapply(names(sensitivity$variants), function(name) cbind(variant = name, sensitivity$variants[[name]]$effects)))
write.csv(st, file.path(out, "sensitivity_effects.csv"), row.names = FALSE, na = "")
supp <- supplementary(primary$cells, grades, filtered_records)
write_json(supp, file.path(out, "supplementary.json"))
for (key in names(supp)) write.csv(supp[[key]], file.path(out, paste0(key, ".csv")), row.names = FALSE, na = "")
message("5/8 Recompute development results and complete usage ledger")
dev_qs <- read_jsonl(file.path(root, "data/dev_retained_questions.jsonl"))
dev_records <- read_jsonl(file.path(root, "runs/dev_receivers/responses.jsonl"))
dev_g <- score_records(dev_qs, dev_records, read_json(file.path(root, "data/dev_adjudications.json")))
dev <- analyze_grades(dev_g, length(dev_qs)); save_analysis(dev, file.path(out, "development"))
write.csv(dev_g, file.path(out, "development/graded_responses.csv"), row.names = FALSE, na = "")
ledger <- usage_ledger(root); write_json(ledger, file.path(out, "usage-ledger.json"))
message("6/8 Export question-level errors and reproducibly selected cases")
evidence <- export_evidence(qs, filtered_records, grades, primary$cells, materials, out)
write_json(evidence, file.path(out, "error_bank/index.json"))
message("7/8 Check migration against archived results (no archived grades used as inputs)")
validation <- validate_archived(root, primary, grades, sensitivity, dev, ledger)
write_json(validation, file.path(out, "validation.json"))
write.csv(validation$interval_comparison, file.path(out, "bootstrap_comparison.csv"), row.names = FALSE, na = "")
message("8/8 Render figures, report, and portable HTML in R")
render_outputs(primary, sensitivity, ledger, evidence, out)
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
scripts <- c("reproduce_main.R", "R/core.R", "R/outputs.R", "R/source_audit.R")
input_paths <- c(list.files(file.path(root, "data"), pattern = "\\.(json|jsonl|csv)$", full.names = TRUE, recursive = TRUE),
  list.files(file.path(root, "runs"), pattern = "\\.(json|jsonl)$", full.names = TRUE, recursive = TRUE),
  list.files(file.path(root, "protocol"), pattern = "\\.(json|md)$", full.names = TRUE))
hashes <- setNames(lapply(input_paths, file_sha), substring(input_paths, nchar(root) + 2))
write_json(list(language = "R", inputs_sha256 = hashes,
  scripts_sha256 = setNames(lapply(file.path(root, scripts), file_sha), scripts),
  bootstrap_seed = 25011001, bootstrap_iterations = 5000, RNGkind = RNGkind(),
  research_questions_changed = FALSE, independent_human_review_complete = FALSE,
  original_data_modified = FALSE, model_calls = 0, archived_python_outputs_used_only_for_validation = TRUE), file.path(out, "provenance.json"))
message("Completed: ", out)
print(primary$tables[primary$tables$provider == "pooled", c("condition", "n", "correct", "incorrect", "abstain")], row.names = FALSE)
print(primary$effects[primary$effects$provider == "pooled", ], row.names = FALSE)
