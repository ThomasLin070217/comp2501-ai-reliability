#!/usr/bin/env Rscript

# R-only descriptive chart for frozen-key, selected first-prompt pairs.
d <- 'Math_Crosscheck_500/collection_v3_human_first'
files <- c(DeepSeek = file.path(d, 'derived/deepseek_first_prompt_summary.csv'),
           MiniMax = file.path(d, 'derived/minimax_first_prompt_summary.csv'))
z <- lapply(files, read.csv, stringsAsFactors = FALSE)
stopifnot(all(vapply(z, function(x) x$pairs[1L], integer(1)) == 50L))
counts <- rbind(c(z$DeepSeek$neutral_wrong[1L], z$DeepSeek$misconception_wrong[1L]),
                c(z$MiniMax$neutral_wrong[1L], z$MiniMax$misconception_wrong[1L]))
stopifnot(identical(as.integer(counts), c(0L,1L,3L,5L)))
rate <- 100 * counts / 50
rownames(rate) <- c('DeepSeek', 'MiniMax')
colnames(rate) <- c('Neutral first prompt', 'False user premise in first prompt')
figdir <- file.path(d, 'analysis/figures')
dir.create(figdir, recursive = TRUE, showWarnings = FALSE)
draw <- function() {
  par(mar = c(8,7,3,1), family = 'sans')
  mids <- barplot(rate, beside = TRUE, ylim = c(0,12),
                  col = c('#2474B5','#E37D3B'), border = NA,
                  ylab = 'Wrong-answer rate (%)',
                  main = 'False human premise in the first prompt',
                  names.arg = c('Neutral', 'False premise'), las = 1,
                  axes = FALSE,
                  cex.names = .95, cex.main = 1.2)
  axis(2, at = seq(0,12,2), labels = paste0(seq(0,12,2),'%'), las = 1)
  box(bty = 'l')
  abline(h = 0, col = '#333333')
  text(mids, rate + 0.5, labels = paste0(counts, '/50'), cex = 1.1)
  legend('topleft', legend = rownames(rate), fill = c('#2474B5','#E37D3B'),
         bty = 'n', horiz = TRUE)
  mtext('Selected questions previously answered correctly by both models. Error = wrong final answer; no explicit abstentions.',
        side = 1, line = 5.1, cex = .72)
  mtext('Each model: 50 independent neutral / false-premise prompt pairs. Bars are descriptive; exact discordance p = 0.25 (DeepSeek), 0.125 (MiniMax).',
        side = 1, line = 6.2, cex = .69)
}
png(file.path(figdir, 'first_prompt_wrong_answer_rates.png'),
    width = 1500, height = 950, res = 150)
draw(); dev.off()
pdf(file.path(figdir, 'first_prompt_wrong_answer_rates.pdf'),
    width = 10, height = 6.3)
draw(); dev.off()
cat('Wrote PNG/PDF descriptive grouped bar chart.\n')
