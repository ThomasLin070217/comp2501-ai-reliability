#!/usr/bin/env Rscript
# Visualize the additional errors in the selected 68 cases. The source CSV
# was reconstructed by R from the private scored ledgers in v18.
suppressPackageStartupMessages({library(ggplot2); library(ragg)})
args <- commandArgs(trailingOnly=TRUE)
source_file <- if (length(args) >= 1) args[[1]] else
  'Submission_Pack/Math_Only_2026-10-07/figures/partial_rollout_v18/bank_level_partial_rollout_v18.csv'
output_file <- if (length(args) >= 2) args[[2]] else
  'Submission_Pack/Math_Only_2026-10-07/figures/added_errors_v19/added_errors_on_68.png'
d <- read.csv(source_file, stringsAsFactors=FALSE)
d <- subset(d, experiment == '68 initially correct selected')
stopifnot(nrow(d) == 4L, all(d$denominator == 493L),
          identical(d$wrong, c(70L,71L,70L,80L)),
          identical(d$tested_n, c(0L,68L,68L,68L)))
base <- d$wrong[d$condition == 'Initial answer']
p <- subset(d, condition != 'Initial answer')
p$added <- p$wrong - base
stopifnot(identical(p$added, c(1L,0L,10L)))
p$condition <- factor(p$condition,
  levels=rev(c('Neutral self-check','Wrong AI advice','False user challenge')))
p$fill <- c('#E9A9A5','#F7E3E1','#C73B34')
p$label <- sprintf('+%d', p$added)
fig <- ggplot(p, aes(x=added, y=condition)) +
  geom_vline(xintercept=0,color='#DDE5EA',linewidth=.8) +
  geom_segment(aes(x=0,xend=added,yend=condition,color=fill),linewidth=2.5,
               show.legend=FALSE) +
  geom_point(aes(fill=fill),shape=21,color='#A6413C',stroke=1.1,
             size=8,show.legend=FALSE) +
  geom_text(aes(label=label),hjust=-.20,fontface='bold',size=6.0,
            color='#163149') +
  geom_text(aes(x=11.5,label=sprintf('%d/493 total wrong',wrong)),hjust=0,
            fontface='bold',size=5.8,color='#163149') +
  scale_color_identity() +
  scale_fill_identity() +
  scale_x_continuous(limits=c(-.65,16.5),breaks=c(0,2,4,6,8,10),
                     expand=expansion(mult=c(0,0))) +
  labs(x='Additional wrong answers among 68 selected cases',y=NULL) +
  theme_minimal(base_family='Arial',base_size=22) +
  theme(panel.grid.minor=element_blank(),panel.grid.major.y=element_blank(),
        axis.text.y=element_text(color='#52677a',size=22),
        axis.text.x=element_text(color='#6a7e91',size=19),
        axis.title.x=element_text(color='#6a7e91',size=20,margin=margin(t=14)),
        plot.margin=margin(12,20,8,10))
dir.create(dirname(output_file),recursive=TRUE,showWarnings=FALSE)
agg_png(output_file,width=1900,height=740,res=160,background='white')
print(fig)
dev.off()
