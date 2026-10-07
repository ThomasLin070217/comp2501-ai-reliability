#!/usr/bin/env Rscript
# Recompute the headline descriptive results from the public release only.
# No network access or non-base R packages are required.

here <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1]), winslash = "/"))
data_dir <- file.path(here, "data")
results_dir <- file.path(here, "results")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
read_csv <- function(name) read.csv(file.path(data_dir, name), stringsAsFactors = FALSE,
                                     check.names = FALSE, na.strings = c("", "NA"),
                                     fileEncoding = "UTF-8")
write_csv <- function(x, name) write.csv(x, file.path(results_dir, name), row.names = FALSE,
                                            na = "", fileEncoding = "UTF-8")
scoreable <- function(x) x %in% c("correct", "incorrect")
wrong_n <- function(x) sum(x == "incorrect", na.rm = TRUE)
row_result <- function(rq, study, measure, condition, n, numerator, note = "") {
  data.frame(research_question = rq, study = study, measure = measure,
             condition = condition, denominator = as.integer(n),
             numerator = as.integer(numerator), rate = if (n > 0) numerator / n else NA_real_,
             note = note, stringsAsFactors = FALSE)
}
out <- list()

# RQ1 / RQ2: same-question GSM-Plus v3 matched MiniMax cases.
g_all <- read_csv("gsmplus_v3_response_level.csv")
g <- g_all[g_all$model == "MiniMax-M3" & g_all$condition %in% c("initial_answer", "self_check", "cross_check", "scripted_wrong_ai_peer"), ]
core <- g[g$condition %in% c("initial_answer", "self_check", "cross_check"), ]
wide <- reshape(core[, c("question_id", "condition", "grade")], idvar = "question_id",
                timevar = "condition", direction = "wide")
names(wide) <- sub("^grade\\.", "", names(wide))
need <- c("initial_answer", "self_check", "cross_check")
wide <- wide[complete.cases(wide[, need]) & apply(wide[, need, drop = FALSE], 1, function(x) all(scoreable(x))), ]
stopifnot(nrow(wide) == 495L)
for (condition in need) out[[length(out) + 1L]] <- row_result("RQ1", "GSM-Plus v3",
  "Matched error rate", condition, nrow(wide), wrong_n(wide[[condition]]),
  "MiniMax; same 495 questions scoreable in all three conditions.")
out[[length(out) + 1L]] <- row_result("RQ2", "GSM-Plus v3",
  "Paired error-count difference (cross-check minus self-check)", "Cross-check vs self-check",
  nrow(wide), wrong_n(wide$cross_check) - wrong_n(wide$self_check),
  "Descriptive difference: -5/495 = -1.01 percentage points; paired interval reaches 0, so no stable superiority claim.")

# RQ1: public-source subset of the revised math bank, M1 initial vs M2 self-check.
m <- read_csv("revised_math_public_responses.csv")
m1 <- m[m$condition == "initial_answer", c("question_id", "grade")]
m2 <- m[m$condition == "self_check", c("question_id", "grade")]
names(m1)[2] <- "m1_grade"; names(m2)[2] <- "m2_grade"
p <- merge(m1, m2, by = "question_id")
p <- p[scoreable(p$m1_grade) & scoreable(p$m2_grade), ]
stopifnot(nrow(p) == 482L)
out[[length(out) + 1L]] <- row_result("RQ1", "Revised math, public-source items",
  "Matched error rate", "M1 initial answer", nrow(p), wrong_n(p$m1_grade),
  "482 matched scoreable public-source questions; six local exam/workbook items excluded.")
out[[length(out) + 1L]] <- row_result("RQ1", "Revised math, public-source items",
  "Matched error rate", "M2 self-check", nrow(p), wrong_n(p$m2_grade),
  "32 wrong-to-correct; 8 correct-to-wrong in this matched set.")
supp <- read_csv("revised_math_m1_m2_mixedroute_pairs_public.csv")
supp <- supp[scoreable(supp$initial_grade) & scoreable(supp$m2_grade), ]
stopifnot(nrow(supp) == 485L)
out[[length(out) + 1L]] <- row_result("RQ1", "Revised math, supplemented mixed-route subset",
  "Matched error rate", "Initial answer", nrow(supp), wrong_n(supp$initial_grade),
  "Later nine-task supplement; separate from the original primary-route comparison.")
out[[length(out) + 1L]] <- row_result("RQ1", "Revised math, supplemented mixed-route subset",
  "Matched error rate", "Self-check", nrow(supp), wrong_n(supp$m2_grade),
  "33 wrong-to-correct; 8 correct-to-wrong. Public-source items only.")

# RQ2: compare corrections only among initially wrong cases with both M2 and actual C1.
c1 <- m[m$condition == "actual_peer_cross_check", c("question_id", "grade")]
names(c1)[2] <- "c1_grade"
q2 <- merge(p[, c("question_id", "m1_grade", "m2_grade")], c1, by = "question_id")
q2 <- q2[q2$m1_grade == "incorrect" & scoreable(q2$m2_grade) & scoreable(q2$c1_grade), ]
stopifnot(nrow(q2) == 63L)
out[[length(out) + 1L]] <- row_result("RQ2", "Revised math, selected initial errors",
  "Conditional error rate", "Self-check (M2)", nrow(q2), wrong_n(q2$m2_grade),
  "Only initially wrong questions with scoreable matched M2 and actual independent DeepSeek cross-check.")
out[[length(out) + 1L]] <- row_result("RQ2", "Revised math, selected initial errors",
  "Conditional error rate", "Cross-check (C1)", nrow(q2), wrong_n(q2$c1_grade),
  "Conditional subset; not a whole-bank cross-check error rate.")

# RQ3: controlled scripted wrong AI advice; retain studies/cohorts separately.
controlled <- g[g$condition == "scripted_wrong_ai_peer" & scoreable(g$grade), ]
out[[length(out) + 1L]] <- row_result("RQ3", "GSM-Plus v3 controlled test",
  "Final wrong-answer rate", "Scripted wrong AI peer advice", 50,
  wrong_n(controlled$grade),
  "50 initially correct cases; zero final errors/adoptions does not establish immunity.")
out[[length(out) + 1L]] <- row_result("RQ3", "GSM-Plus v3 controlled test",
  "False-target adoption rate", "Scripted wrong AI peer advice", nrow(controlled),
  sum(controlled$wrong_target_adopted == "yes", na.rm = TRUE),
  "The numerator is adoptions, not wrong final answers.")
# Actual independent donor: two matched cases had a correct MiniMax initial
# answer and incorrect DeepSeek initial answer; preserve the ambiguous case note.
mm <- g_all[g_all$model == "MiniMax-M3" & g_all$condition == "initial_answer", c("question_id", "grade")]
ds <- g_all[g_all$model == "DeepSeek" & g_all$condition == "initial_answer", c("question_id", "grade")]
cx <- g_all[g_all$model == "MiniMax-M3" & g_all$condition == "cross_check", c("question_id", "grade")]
names(mm)[2] <- "mm_initial"; names(ds)[2] <- "ds_initial"; names(cx)[2] <- "cross_grade"
peer_cases <- merge(merge(mm, ds, by = "question_id"), cx, by = "question_id")
peer_cases <- peer_cases[peer_cases$mm_initial == "correct" & peer_cases$ds_initial == "incorrect", ]
out[[length(out) + 1L]] <- row_result("RQ3", "GSM-Plus v3 actual independent donor",
  "Wrong cross-check final among false-donor cases", "MiniMax initial correct; DeepSeek donor wrong",
  nrow(peer_cases), wrong_n(peer_cases$cross_grade),
  "Two eligible cases; one final was graded wrong, but wording was ambiguous, so this is not clean causal proof.")
for (cond in c("scripted_ai_advice", "scripted_ai_advice_extension")) {
  z <- m[m$condition == cond & scoreable(m$grade), ]
  out[[length(out) + 1L]] <- row_result("RQ3", paste("Revised math", cond),
    "Final wrong-answer rate", "Scripted wrong AI advice", nrow(z), wrong_n(z$grade),
    "Separate selected cohorts; researcher-scripted suggestion, not a real donor reply.")
  out[[length(out) + 1L]] <- row_result("RQ3", paste("Revised math", cond),
    "False-target adoption rate", "Scripted wrong AI advice", nrow(z),
    sum(z$wrong_target_adopted %in% c(TRUE, "TRUE", "yes"), na.rm = TRUE),
    "Separate public-source selected cohort; adoption is distinct from any unrelated calculation error.")
}

# RQ4: neutral vs false-premise first prompt, paired by question and model.
h <- g_all[g_all$condition %in% c("first_prompt_neutral", "first_prompt_human_misconception"), ]
paired_tests <- list()
for (model in c("DeepSeek", "MiniMax-M3")) {
  z <- h[h$model == model, ]
  w <- reshape(z[, c("question_id", "condition", "grade")], idvar = "question_id",
               timevar = "condition", direction = "wide")
  names(w) <- sub("^grade\\.", "", names(w))
  cols <- c("first_prompt_neutral", "first_prompt_human_misconception")
  w <- w[complete.cases(w[, cols]) & apply(w[, cols, drop = FALSE], 1, function(x) all(scoreable(x))), ]
  stopifnot(nrow(w) == 50L)
  out[[length(out) + 1L]] <- row_result("RQ4", paste("GSM-Plus v3", model),
    "Paired error rate", "Neutral first prompt", nrow(w), wrong_n(w$first_prompt_neutral),
    "Same 50 questions also received an independent false-premise first prompt.")
  out[[length(out) + 1L]] <- row_result("RQ4", paste("GSM-Plus v3", model),
    "Paired error rate", "False user-premise first prompt", nrow(w), wrong_n(w$first_prompt_human_misconception),
    "Researcher-scripted user misconception; not a recruited human interaction.")
  adopt <- z[z$condition == "first_prompt_human_misconception" & scoreable(z$grade), ]
  out[[length(out) + 1L]] <- row_result("RQ4", paste("GSM-Plus v3", model),
    "False-target adoption rate", "False user-premise first prompt", nrow(adopt),
    sum(adopt$wrong_target_adopted %in% c(TRUE, "TRUE", "yes"), na.rm = TRUE),
    "Recorded target adoption; see raw response and scoring provenance fields.")
  transition <- table(factor(w$first_prompt_neutral, levels = c("correct", "incorrect")),
                      factor(w$first_prompt_human_misconception, levels = c("correct", "incorrect")))
  transition_df <- as.data.frame(transition, stringsAsFactors = FALSE)
  names(transition_df) <- c("neutral_grade", "false_premise_grade", "count")
  write_csv(transition_df, paste0("rq4_transitions_", gsub("[^A-Za-z0-9]+", "_", model), ".csv"))
  gain <- transition[1, 2]
  loss <- transition[2, 1]
  paired_tests[[model]] <- data.frame(model = model, neutral_correct_to_false_prompt_wrong = gain,
    neutral_wrong_to_false_prompt_correct = loss,
    two_sided_exact_binomial_p = if ((gain + loss) > 0) binom.test(gain, gain + loss, p = 0.5)$p.value else 1)
}

key <- do.call(rbind, out)
write_csv(key, "key_results_reproduced.csv")
write_csv(do.call(rbind, paired_tests), "rq4_paired_tests.csv")
# Refresh a SHA-256 manifest for the complete release (excluding itself).
release_files <- list.files(here, recursive = TRUE, full.names = TRUE)
release_files <- release_files[basename(release_files) != "FILE_MANIFEST.csv"]
hash_cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
hash_file <- function(path) {
  args <- if (identical(hash_cmd, "shasum")) c("-a", "256", shQuote(path)) else c(shQuote(path))
  line <- system2(hash_cmd, args, stdout = TRUE)
  sub("[[:space:]].*$", "", line[1])
}
manifest <- data.frame(path = substring(release_files, nchar(here) + 2),
  bytes = file.info(release_files)$size,
  sha256 = vapply(release_files, hash_file, character(1)), stringsAsFactors = FALSE)
write.csv(manifest, file.path(here, "FILE_MANIFEST.csv"), row.names = FALSE,
          na = "", fileEncoding = "UTF-8")
cat("Wrote", file.path(results_dir, "key_results_reproduced.csv"), "\n")
print(key, row.names = FALSE)
