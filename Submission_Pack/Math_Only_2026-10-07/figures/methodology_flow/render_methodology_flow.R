#!/usr/bin/env Rscript

# Standalone, slide-ready methodology diagram. No private question text is used.
suppressPackageStartupMessages(library(grid))

args <- commandArgs(trailingOnly = TRUE)
out_dir <- if (length(args)) args[[1]] else dirname(normalizePath(sys.frame(1)$ofile))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

W <- 1600
H <- 900
navy <- "#153249"
slate <- "#5D7283"
muted <- "#758897"
line <- "#D6E0E7"
teal <- "#008E84"
blue <- "#2F649A"
amber <- "#B76226"
red <- "#B4443F"

xy <- function(x, y) unit(c(x / W, 1 - y / H), "npc")
rect <- function(x, y, w, h, fill, stroke = NA, radius = 16, lwd = 1.4) {
  grid.roundrect(
    x = unit((x + w / 2) / W, "npc"),
    y = unit(1 - (y + h / 2) / H, "npc"),
    width = unit(w / W, "npc"), height = unit(h / H, "npc"),
    r = unit(radius / W, "npc"),
    gp = gpar(fill = fill, col = stroke, lwd = lwd)
  )
}
txt <- function(x, y, label, size = 17, col = navy, bold = FALSE,
                just = "centre", lineheight = 1.15) {
  grid.text(label, x = unit(x / W, "npc"), y = unit(1 - y / H, "npc"),
            just = just, gp = gpar(fontfamily = "Helvetica", fontsize = size,
                                    col = col, fontface = if (bold) "bold" else "plain",
                                    lineheight = lineheight))
}
arrow_line <- function(x0, y0, x1, y1, col = slate, lwd = 2.2, dashed = FALSE) {
  grid.lines(x = unit(c(x0, x1) / W, "npc"),
             y = unit(1 - c(y0, y1) / H, "npc"),
             arrow = arrow(type = "closed", length = unit(6, "pt")),
             gp = gpar(col = col, lwd = lwd, lty = if (dashed) "dashed" else "solid"))
}
plain_line <- function(x0, y0, x1, y1, col = line, lwd = 2.1) {
  grid.lines(x = unit(c(x0, x1) / W, "npc"),
             y = unit(1 - c(y0, y1) / H, "npc"),
             gp = gpar(col = col, lwd = lwd))
}
node <- function(x, y, w, h, title, detail, accent = navy, fill = "#FFFFFF",
                 title_size = 18, detail_size = 15) {
  rect(x, y, w, h, fill, line, 15)
  rect(x, y, 7, h, accent, accent, 2, 0)
  title_y <- if (h < 105) 28 else 32
  detail_y <- if (grepl("\n", detail, fixed = TRUE)) h - 31 else h - 34
  txt(x + 22, y + title_y, title, title_size, navy, TRUE, "left")
  txt(x + 22, y + detail_y, detail, detail_size, slate, FALSE, "left")
}
panel <- function(x, y, w, h, fill, accent, heading, subtitle) {
  rect(x, y, w, h, fill, line, 18)
  rect(x + 17, y + 16, 6, 52, accent, accent, 2, 0)
  txt(x + 36, y + 33, heading, 18, accent, TRUE, "left")
  txt(x + 36, y + 63, subtitle, 14, slate, FALSE, "left")
}

draw <- function() {
  grid.newpage()

  # Three short comparison lanes.
  panel(42, 246, 484, 568, "#F2F7FC", blue,
        "SELF-CHECK", "All 493 scoreable answers")
  panel(558, 246, 484, 568, "#EFF9F7", teal,
        "CROSS-CHECK", "70 initially wrong answers")
  panel(1074, 246, 484, 568, "#FFF8F2", amber,
        "MISLEADING INPUT", "Random 70 of 423 initially correct")

  # Intake and grading, with one-to-many fork.
  node(60, 44, 350, 112, "500 math questions",
       "Revised benchmark", navy, "#FFFFFF", 21, 16)
  node(468, 44, 350, 112, "MiniMax",
       "Initial answer", navy, "#FFFFFF", 21, 16)
  node(876, 44, 662, 112, "initial_error_rate",
       "70 / 493 wrong  ·  7 excluded",
       navy, "#FFFFFF", 21, 16)
  arrow_line(410, 100, 459, 100, navy)
  arrow_line(818, 100, 867, 100, navy)
  plain_line(1207, 156, 1207, 199, slate)
  plain_line(284, 199, 1316, 199, slate)
  arrow_line(284, 199, 284, 242, blue)
  arrow_line(800, 199, 800, 242, teal)
  arrow_line(1316, 199, 1316, 242, amber)

  # Self-check covers the full scoreable initial cohort.
  node(73, 365, 422, 112, "MiniMax self-check",
       "Reviews its own answer", blue,
       "#FFFFFF", 21, 16)
  arrow_line(284, 482, 284, 594, blue)
  node(73, 602, 422, 112, "selfcheck_error_rate",
       "Compared with initial  ·  n = 488", blue,
       "#FFFFFF", 20, 16)

  # Real independent DeepSeek reply, followed by MiniMax cross-check.
  node(589, 335, 422, 111, "DeepSeek",
       "Independent answer", teal,
       "#FFFFFF", 20, 16)
  arrow_line(800, 451, 800, 474, teal)
  node(589, 482, 422, 111, "MiniMax cross-check",
       "Reads DeepSeek's answer", teal,
       "#FFFFFF", 20, 16)
  arrow_line(800, 598, 800, 621, teal)
  node(589, 629, 422, 122, "crosscheck_error_rate",
       "Initially wrong cases  ·  n = 63", teal,
       "#FFFFFF", 20, 16)

  # Two simulated feedback conditions on the same 70 correct initial answers.
  plain_line(1316, 403, 1316, 445, amber)
  plain_line(1211, 445, 1421, 445, amber)
  arrow_line(1211, 445, 1211, 479, amber)
  arrow_line(1421, 445, 1421, 479, red)
  node(1105, 487, 205, 117, "AI advice", "Wrong answer", amber,
       "#FFFFFF", 18, 14)
  node(1322, 487, 205, 117, "User challenge", "Wrong answer", red,
       "#FFFFFF", 18, 14)
  plain_line(1211, 604, 1211, 643, amber)
  plain_line(1421, 604, 1421, 643, red)
  plain_line(1211, 643, 1421, 643, amber)
  arrow_line(1316, 643, 1316, 655, amber)
  rect(1105, 655, 422, 135, "#FFFFFF", line, 15)
  rect(1105, 655, 7, 135, amber, amber, 2, 0)
  txt(1127, 683, "ai_prompt_error_rate", 17, navy, TRUE, "left")
  txt(1127, 720, "human_prompt_error_rate", 17, navy, TRUE, "left")
  txt(1127, 758, "68 matched cases", 14, slate, FALSE, "left")

  txt(800, 858, "AI and user feedback are simulated; DeepSeek gives a real independent answer.", 15, muted)
}

pdf(file.path(out_dir, "comp2501_methodology_flow.pdf"),
    width = 16, height = 9, pointsize = 12, bg = "white", family = "Helvetica")
draw()
dev.off()

pdf_path <- file.path(out_dir, "comp2501_methodology_flow.pdf")
png_prefix <- file.path(out_dir, "comp2501_methodology_flow")
svg_path <- file.path(out_dir, "comp2501_methodology_flow.svg")
stopifnot(system2("pdftoppm", c("-f", "1", "-singlefile", "-r", "200",
                                    "-png", shQuote(pdf_path), shQuote(png_prefix))) == 0)
stopifnot(system2("pdftocairo", c("-svg", shQuote(pdf_path), shQuote(svg_path))) == 0)
