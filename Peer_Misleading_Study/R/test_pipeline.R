#!/usr/bin/env Rscript
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
source(file.path(dirname(normalizePath(script)), "core.R"))
n <- 0L
check <- function(label, expr) {
  assert(isTRUE(expr), label); n <<- n + 1L; cat("PASS:", label, "\n")
}
must_error <- function(expr) tryCatch({force(expr); FALSE}, error = function(e) TRUE)
q <- list(question_id = "TEST", gold_parts = list(2010L), false_parts = list(2011L))
check("Equivalent ordinal date", identical(date_parts("18th of April, 1954"), c(1954L, 4L, 18L)))
check("ISO date", identical(date_parts("1954-04-18"), c(1954L, 4L, 18L)))
check("Invalid day and non-leap date rejected", is.null(date_parts("February 30, 1954")) && is.null(date_parts("1900-02-29")))
check("Leap-year boundary", identical(date_parts("2000-02-29"), c(2000L, 2L, 29L)))
check("No fuzzy extraction", is.null(date_parts("Not 1954")) && is.null(date_parts("1954 or 1955")))
check("Correct date", grade('{"answer":"2010","abstain":false}', q)$grade == "correct")
check("Assigned false target detected", isTRUE(grade('{"answer":"2011","abstain":false}', q)$target_adopted))
check("Empty explicit abstention", grade('{"answer":"","abstain":true}', q)$grade == "abstain")
check("Contradictory abstention requires review", grade('{"answer":"2010","abstain":true}', q)$grade == "pending")
check("Malformed/truncated JSON requires review", grade('Answ', q)$grade == "pending")
check("Duplicate keys follow original last-key semantics", grade('{"answer":"","abstain":"unknown","abstain":true}', q)$grade == "abstain")
qd <- list(gold_parts = list(2010L, 2L, 1L), false_parts = list(2010L, 2L, 2L))
check("Insufficient precision is reviewed", grade('{"answer":"2010","abstain":false}', qd)$grade_reason == "insufficient_precision")
check("Extra precision accepted at requested granularity", grade('{"answer":"January 1, 2010","abstain":false}', q)$grade == "correct")
g <- expand.grid(condition = CONDITIONS, question_id = c("A", "B"), stringsAsFactors = FALSE)
g$cell_id <- paste0(g$question_id, ":deepseek:r0"); g$provider <- "deepseek"; g$repeat_id <- 0
g$task_id <- paste(g$cell_id, g$condition, sep = ":"); g$target_adopted <- FALSE
g$grade <- ifelse(g$question_id == "A", "correct", "incorrect")
g$grade[g$condition %in% c("C1", "C2")] <- "incorrect"
g$grade[g$condition %in% c("C3", "C4", "C5")] <- "correct"
g$unscorable <- FALSE
cells <- make_cells(g); tables <- condition_tables(cells, g)
check("Harm and repair have separate denominators", tables$harm_pct[tables$provider == "pooled" & tables$condition == "C2"] == 100 &&
  tables$repair_pct[tables$provider == "pooled" & tables$condition == "C4"] == 100)
b <- bootstrap_effect(cells, "C2", "C3", B = 20)
check("Paired effect and eligible denominator", b$difference_pp == -100 && b$eligible_cells == 1 && b$question_clusters == 2)
b0 <- bootstrap_effect(cells[cells$question_id == "B", ], "C1", "C2", B = 20)
check("No eligible cases give missing effect", is.na(b0$difference_pp) && b0$bootstrap_status == "no_eligible_cells")
bd <- bootstrap_effect(cells, "C1", "C2", B = 20)
check("Degenerate bootstrap is not zero uncertainty", bd$difference_pp == 0 && is.na(bd$ci_low_pp) && grepl("degenerate", bd$bootstrap_status))
check("Incomplete cell fails", must_error(make_cells(g[-1, ])))
bad <- g; bad$grade[1] <- "pending"; bad$unscorable[1] <- TRUE
filtered <- quality_filter(bad)
check("One unusable output removes whole seven-response cell", nrow(filtered$grades) == 7 && length(filtered$excluded_task_ids) == 7)
bad$unscorable[1] <- FALSE
check("Unreviewed pending output fails", must_error(quality_filter(bad)))
check("Bootstrap is reproducible", identical(bootstrap_effect(cells, "C2", "C3", B = 100), bootstrap_effect(cells, "C2", "C3", B = 100)))
cat(n, "R checks passed.\n")
