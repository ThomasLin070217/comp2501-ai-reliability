#!/usr/bin/env Rscript

# Plot fully graded, same-question GSM-Plus v3 wrong-answer rates.
suppressPackageStartupMessages({library(ggplot2); library(jsonlite); library(digest)})
base <- 'Math_Crosscheck_500/collection_v3_followups/analysis'
counts_file <- file.path(base, 'condition_counts_common.csv')
effects_file <- file.path(base, 'paired_error_effects.csv')
counts <- read.csv(counts_file, stringsAsFactors = FALSE)
effects <- read.csv(effects_file, stringsAsFactors = FALSE)
stopifnot(nrow(counts) == 3L,
          identical(as.character(counts$condition),
                    c('initial','self_check','natural_crosscheck')),
          length(unique(counts$n)) == 1L,
          all(counts$correct + counts$incorrect + counts$abstention == counts$n))
order <- c('Initial answer', 'Self-check', 'Cross-check')
counts$label <- factor(order, levels = order)
counts$percent <- 100 * counts$incorrect / counts$n
counts$count_label <- paste0(counts$incorrect, '/', counts$n,
                             '\n', sprintf('%.2f%%', counts$percent))
delta <- effects[effects$comparison == 'natural_grade_minus_self_grade', ]
stopifnot(nrow(delta) == 1L, delta$n == counts$n[[1]])
subtitle <- sprintf('Same %d questions; cross-check minus self-check: %.2f pp (95%% bootstrap %.2f to %.2f pp)',
                    delta$n, delta$delta_pp, delta$ci_low_pp, delta$ci_high_pp)
p <- ggplot(counts, aes(x = label, y = percent, fill = label)) +
  geom_col(width = 0.62, show.legend = FALSE) +
  geom_text(aes(label = count_label), vjust = -0.22, size = 4.5,
            lineheight = 1.05, color = '#13243b') +
  scale_fill_manual(values = c('#64748b', '#3b82f6', '#0f766e')) +
  scale_y_continuous(limits = c(0, max(counts$percent) * 1.38),
                     breaks = seq(0, 4, 1), labels = function(x) paste0(x, '%'),
                     expand = expansion(mult = c(0, 0))) +
  labs(title = 'Wrong-answer rate after double-checking', subtitle = subtitle,
       x = NULL, y = 'Wrong answers / scoreable paired questions',
       caption = paste('GSM-Plus v3; MiniMax initial and receiver, independent DeepSeek donor.',
                       'One question had unscorable replies in both branches and is excluded.',
                       'Correct and explicit abstention are not counted as errors.', sep = '\n')) +
  theme_minimal(base_size = 13, base_family = 'sans') +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = 'bold', size = 18, color = '#10253c'),
        plot.subtitle = element_text(size = 10.5, color = '#334155'),
        plot.caption = element_text(hjust = 0, color = '#475569', size = 8.5),
        axis.text.x = element_text(face = 'bold', color = '#10253c', size = 11),
        axis.text.y = element_text(color = '#475569'))
out <- file.path(base, 'figures')
dir.create(out, recursive = TRUE, showWarnings = FALSE)
ggsave(file.path(out, 'v3_wrong_answer_rates.png'), p, width = 9.4, height = 5.7,
       dpi = 240, bg = 'white')
ggsave(file.path(out, 'v3_wrong_answer_rates.pdf'), p, width = 9.4, height = 5.7,
       device = pdf, bg = 'white')
write_json(list(counts_sha256 = digest(file = counts_file, algo = 'sha256'),
                effects_sha256 = digest(file = effects_file, algo = 'sha256'),
                n = counts$n[[1]],
                note = 'Descriptive bar chart; paired uncertainty is for cross vs self difference.'),
           file.path(out, 'figure_manifest.json'), auto_unbox = TRUE, pretty = TRUE)
