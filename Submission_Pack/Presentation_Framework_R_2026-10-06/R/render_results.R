# R-generated figures for the presentation. No historical data are loaded.
# Run: Rscript R/render_results.R [input_csv] [output_directory]
args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(), value = TRUE)[1]
script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg)))
root <- dirname(script_dir)
input <- if (length(args) >= 1) args[1] else file.path(root, "chart_data_template.csv")
out <- if (length(args) >= 2) args[2] else file.path(root, "figures")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
d <- read.csv(input, stringsAsFactors = FALSE, na.strings = c("", "NA"))
required <- c("chart_id", "panel", "group", "numerator", "denominator")
stopifnot(all(required %in% names(d)))
key <- paste(d$chart_id, d$panel, d$group, sep = "/")
stopifnot(!anyDuplicated(key))
for (col in c("numerator", "denominator")) {
  original <- d[[col]]
  d[[col]] <- suppressWarnings(as.numeric(original))
  if (any(!is.na(original) & is.na(d[[col]]))) stop("Non-numeric count: ", col)
  if (any(!is.na(d[[col]]) & (!is.finite(d[[col]]) | d[[col]] < 0 | d[[col]] != floor(d[[col]]))))
    stop("Counts must be finite non-negative integers: ", col)
}
if (any(xor(is.na(d$numerator), is.na(d$denominator)))) stop("Provide both numerator and denominator, or leave both blank.")
if (any(d$numerator > d$denominator, na.rm = TRUE)) stop("Numerator exceeds denominator.")
d$rate <- ifelse(!is.na(d$denominator) & d$denominator > 0, 100 * d$numerator / d$denominator, NA_real_)
ink <- "#142C40"; muted <- "#657586"; grid <- "#D6DFE6"; bg <- "#F8FAFD"
cols <- c("#A9B6C2", "#00857C", "#D58A25", "#B33C35")
get_rows <- function(id, panel, groups) {
  rows <- d[d$chart_id == id & d$panel == panel, ]
  if (!all(groups %in% rows$group)) stop("Missing groups in ", id, "/", panel)
  rows[match(groups, rows$group), ]
}
matched <- function(rows) {
  known <- rows$denominator[!is.na(rows$denominator)]
  if (length(unique(known)) > 1) stop("A paired comparison must use a common denominator.")
}
panel <- function(rows, labels, title, colors = cols, ytitle = "Rate (%)", paired = TRUE) {
  if (paired) matched(rows)
  v <- rows$rate
  # Blank values stay blank. Do not draw zero-height bars for missing observations.
  ymax <- if (all(is.na(v))) 100 else min(100, max(10, ceiling(max(v, na.rm = TRUE) * 1.25 / 10) * 10))
  n <- length(v)
  plot(NA, xlim = c(.4, n + .6), ylim = c(0, ymax), xaxs = "i", yaxs = "i", axes = FALSE, xlab = "", ylab = "")
  ticks <- pretty(c(0, ymax), n = 5); ticks <- ticks[ticks >= 0 & ticks <= ymax]
  abline(h = ticks, col = grid, lwd = .7)
  axis(2, at = ticks, las = 1, col = grid, col.axis = muted, tck = 0, mgp = c(2, .55, 0), cex.axis = .95)
  axis(1, at = seq_len(n), labels = labels, col = grid, col.axis = ink, tck = 0, mgp = c(2, .8, 0), cex.axis = .92)
  mtext(ytitle, side = 2, line = 2.55, col = muted, cex = .95)
  title(main = title, col.main = ink, font.main = 2, cex.main = 1.12, line = 1.05)
  for (i in seq_len(n)) {
    if (!is.na(v[i])) {
      rect(i - .29, 0, i + .29, v[i], col = colors[(i-1) %% length(colors) + 1], border = NA)
      text(i, v[i] + ymax*.045, sprintf("%.2f%%", v[i]), col = ink, cex = .95)
    }
  }
  if (all(is.na(rows$denominator))) text(mean(seq_len(n)), ymax*.58, "Awaiting new data", col = muted, cex = 1.4)
  else for (i in seq_len(n)) if (is.na(v[i])) text(i, ymax*.5, if (is.na(rows$denominator[i])) "Pending" else "N = 0\nNot estimable", col = muted, cex = .9)
  counts <- ifelse(is.na(rows$denominator), "n / N pending", paste0(rows$numerator, " / ", rows$denominator))
  mtext(counts, side = 1, line = 3.0, at = seq_len(n), cex = .75, col = muted)
}
two_panels <- function(name, draw, pointsize = 16) {
  for (ext in c("png", "pdf")) {
    dest <- file.path(out, paste0(name, ".", ext))
    if (ext == "png") png(dest, width = 12, height = 4.5, units = "in", res = 240, type = if (capabilities("aqua")) "quartz" else "cairo", bg = bg, family = "Helvetica Neue", pointsize = pointsize)
    else if (capabilities("aqua")) quartz(type = "pdf", file = dest, width = 12, height = 4.5, bg = bg, family = "Helvetica Neue", pointsize = pointsize)
    else cairo_pdf(dest, width = 12, height = 4.5, bg = bg, family = "Helvetica Neue", pointsize = pointsize)
    par(mfrow = c(1, 2), mar = c(5.2, 4.1, 3.5, .9), oma = c(0, 0, 0, 0), fg = ink)
    draw()
    dev.off()
  }
}
two_panels("slide11_baseline", function() {
  groups <- c("MiniMax", "DeepSeek")
  e <- get_rows("baseline", "error", groups); nc <- get_rows("baseline", "noncorrect", groups)
  if (any(e$denominator != nc$denominator, na.rm = TRUE) || any(e$numerator > nc$numerator, na.rm = TRUE)) stop("Baseline metric counts conflict.")
  panel(e, groups, "Initial error rate", paired = FALSE, colors = cols[c(2,3)])
  panel(nc, groups, "Initial non-correct rate", paired = FALSE, colors = cols[c(2,3)])
})
two_panels("slide14_overall", function() {
  groups <- c("Initial", "Self-check", "Natural cross-check")
  e <- get_rows("overall", "error", groups); nc <- get_rows("overall", "noncorrect", groups)
  if (any(e$denominator != nc$denominator, na.rm = TRUE) || any(e$numerator > nc$numerator, na.rm = TRUE)) stop("Overall metric counts conflict.")
  labels <- c("Initial", "Self-check", "Natural\ncross-check")
  panel(e, labels, "Error rate", colors = cols[c(1,2,3)])
  panel(nc, labels, "Non-correct rate", colors = cols[c(1,2,3)])
})
two_panels("slide15_correction", function() {
  e <- get_rows("overall", "error", c("Self-check", "Natural cross-check"))
  panel(e, c("Self-check", "Natural\ncross-check"), "Checking methods", colors = cols[c(2,3)])
  s <- get_rows("correction", "correct_peer", c("Corrected", "Eliminated"))
  if (all(!is.na(s$numerator)) && s$numerator[1] > s$numerator[2]) stop("Corrections cannot exceed eliminations.")
  panel(s, c("Wrong to\ncorrect", "Wrong to correct\nor abstention"), "Initially wrong + correct peer", colors = cols[c(2,3)])
})
two_panels("slide16_risk", function() {
  groups <- c("Natural self", "Natural peer", "Constructed self", "Constructed peer")
  p <- get_rows("risk", "peer", groups)
  matched(p[1:2,]); matched(p[3:4,])
  panel(p, c("Natural\nself", "Natural\npeer", "Constructed\nself", "Constructed\npeer"), "Wrong peer response", colors = cols[c(1,3,1,4)], ytitle = "Induced error rate (%)", paired = FALSE)
  groups <- c("MiniMax neutral", "MiniMax human", "DeepSeek neutral", "DeepSeek human")
  h <- get_rows("risk", "human", groups)
  matched(h[1:2,]); matched(h[3:4,])
  panel(h, c("MiniMax\nneutral", "MiniMax\nuser", "DeepSeek\nneutral", "DeepSeek\nuser"), "Scripted user mistake", colors = cols[c(1,3,1,3)], ytitle = "Induced error rate (%)", paired = FALSE)
}, pointsize = 14)
write.csv(d, file.path(out, "plotted_values.csv"), row.names = FALSE, na = "")
message("Four R figures exported as PNG and PDF. Pending observations: ", sum(is.na(d$rate)), "/", nrow(d))
