#!/usr/bin/env Rscript
# R-only scoring inputs and visualisation for the user-approved research questions.
# This script reads safe aggregate summaries; it never opens private question text.
suppressPackageStartupMessages({library(jsonlite); library(ggplot2); library(grid); library(ragg)})
args <- commandArgs(trailingOnly = TRUE)
private_root <- if (length(args) >= 1) args[[1]] else '../Math_Benchmark_500_Private_2026-10-06'
out <- if (length(args) >= 2) args[[2]] else 'Submission_Pack/Math_Only_2026-10-07/figures/rq_alignment_v16'
dir.create(out, recursive = TRUE, showWarnings = FALSE)
base <- file.path(private_root, 'natural_crosscheck_2026-10-07', 'analysis')
cross <- fromJSON(file.path(base, 'conditional_crosscheck_summary_v1.json'))
advice <- fromJSON(file.path(base, 'm3_m4_latest_summary.json'))
stopifnot(cross$m2_c1_paired_n == 63L,
          cross$m2_correct_on_pair == 31L,
          cross$c1_correct_on_pair == 55L,
          advice$m2_m4_paired_n == 68L,
          advice$m2_m4_paired_table[['incorrect|correct']] == 1L,
          advice$m2_m4_paired_table[['correct|incorrect']] == 10L,
          advice$m3$incorrect == 0L,
          advice$m4_wrong_target_adopted == 10L)
N <- cross$m2_c1_paired_n
self_correct <- cross$m2_correct_on_pair
cross_correct <- cross$c1_correct_on_pair
wrong <- c(N, N - self_correct, N - cross_correct)
corrected <- c(self_correct, cross_correct)
stopifnot(identical(as.integer(wrong), c(63L,32L,8L)),
          identical(as.integer(corrected),c(31L,55L)))

rate_label <- function(n, d) sprintf('%d/%d  (%.2f%%)', n, d, 100*n/d)
common_theme <- theme_minimal(base_family = 'Arial', base_size = 17) +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        plot.title = element_text(face='bold', color='#163149', size=19, margin=margin(b=10)),
        axis.title=element_blank(), axis.text.y=element_text(color='#52677a', size=16),
        axis.text.x=element_text(color='#6a7e91', size=14),
        plot.margin=margin(8,65,8,6))
make_plot <- function(names, nums, denoms, fills, title=NULL, max_y=1.18, text_size=5.2,
                      breaks=c(0,.25,.5,.75,1)) {
  dat <- data.frame(name=factor(names, levels=rev(names)), value=nums/denoms,
                    label=mapply(rate_label,nums,denoms), fill=fills)
  ggplot(dat,aes(x=name,y=value,fill=fill)) +
    geom_col(width=.58, show.legend=FALSE) +
    geom_text(aes(label=label), hjust=-.08, color='#163149', fontface='bold', size=text_size) +
    scale_fill_identity() +
    scale_y_continuous(limits=c(0,max_y), breaks=breaks,
      labels=function(x) paste0(round(x*100),'%'), expand=expansion(mult=c(0,0))) +
    coord_flip(clip='off') +
    labs(title=title) + common_theme
}
error_names <- c('Initial answer','Self-check','Cross-check')
error_colors <- c('#52718b','#6c91ad','#91b1c8')
correction_names <- c('Self-check','Cross-check')
correction_colors <- c('#43a869','#168b57')
p_error <- make_plot(error_names,wrong,rep(N,3),error_colors,
                     'Wrong-answer rate on the same selected cases',1.18,4.9)
p_correct <- make_plot(correction_names,corrected,rep(N,2),correction_colors,
                       'Initial errors corrected',1.13,4.9)
# Wide two-panel chart: initial error is 100% by the selection rule, not 500-bank prevalence.
agg_png(file.path(out,'conditional_crosscheck_full_v16.png'),width=2400,height=900,res=160,background='white')
grid.newpage(); pushViewport(viewport(layout=grid.layout(1,2,widths=unit(c(.55,.45),'null'))))
print(p_error,vp=viewport(layout.pos.row=1,layout.pos.col=1),newpage=FALSE)
print(p_correct,vp=viewport(layout.pos.row=1,layout.pos.col=2),newpage=FALSE)
dev.off()
# Reuse the same denominators and design in the two conclusion-panel slots.
agg_png(file.path(out,'rq2_correction_v16.png'),width=1100,height=596,res=160,background='white')
print(make_plot(correction_names,corrected,rep(N,2),correction_colors,NULL,1.16,5.2))
dev.off()
agg_png(file.path(out,'rq2_conditional_error_v16.png'),width=1100,height=596,res=160,background='white')
print(make_plot(error_names,wrong,rep(N,3),error_colors,NULL,1.45,5.0))
dev.off()
# Same 68 initially correct cases for the selected post-answer challenge comparison.
N68 <- advice$m2_m4_paired_n
p_induce <- make_plot(c('Neutral self-check','Scripted AI advice','Scripted user challenge'),
                      c(1L,0L,10L),rep(N68,3),
                      c('#a8bdc9','#41a68f','#d45850'),
                      NULL,.22,5.2,c(0,.05,.10,.15,.20))
agg_png(file.path(out,'rq34_scripted_common68_v16.png'),width=1520,height=633,res=160,background='white')
print(p_induce)
dev.off()
write.csv(data.frame(condition=c('initial','self_check','cross_check'),
                     initial_wrong_selected=N, wrong=wrong,
                     wrong_answer_rate=wrong/N),
          file.path(out,'conditional_error_values.csv'),row.names=FALSE)
write.csv(data.frame(condition=correction_names,initial_wrong_selected=N,
                     corrected=corrected,correction_rate=corrected/N),
          file.path(out,'correction_values.csv'),row.names=FALSE)
write.csv(data.frame(condition=c('neutral_self_check','scripted_ai_advice','scripted_user_challenge'),
                     initially_correct_selected=N68,wrong=c(1L,0L,10L),
                     new_error_rate=c(1L,0L,10L)/N68),
          file.path(out,'scripted_induction_values.csv'),row.names=FALSE)
# RQ1 retains the overall 488-question self-check comparison and adds the
# 63-question targeted cross-check result in a visibly separate panel.
m2 <- read.csv(file.path(private_root,'m2_self_review_2026-10-07','derived',
                         'm2_grade_ledger_v1.csv'),stringsAsFactors=FALSE)
valid <- c('correct','incorrect','explicit_abstention','abstain','abstention')
paired <- m2[m2$initial_grade %in% valid & m2$m2_grade %in% valid,]
overall_n <- nrow(paired)
overall_initial_wrong <- sum(paired$initial_grade!='correct')
overall_self_wrong <- sum(paired$m2_grade!='correct')
stopifnot(overall_n==488L,overall_initial_wrong==66L,overall_self_wrong==42L)
p_overall <- make_plot(c('Initial answer','Self-check'),
  c(overall_initial_wrong,overall_self_wrong),rep(overall_n,2),
  c('#d45b52','#ec8b83'),'Overall sample: 488 matched questions',.23,4.8,
  c(0,.05,.10,.15,.20))
p_conditional <- make_plot(c('Initial answer','Self-check','Cross-check'),
  wrong,rep(N,3),error_colors,'Selected initial errors: 63 questions',1.45,4.8)
agg_png(file.path(out,'rq1_overall_and_cross_v16.png'),width=2400,height=650,
        res=160,background='white')
grid.newpage();pushViewport(viewport(layout=grid.layout(1,2,widths=unit(c(.49,.51),'null'))))
print(p_overall,vp=viewport(layout.pos.row=1,layout.pos.col=1),newpage=FALSE)
print(p_conditional,vp=viewport(layout.pos.row=1,layout.pos.col=2),newpage=FALSE)
dev.off()
write.csv(data.frame(panel=c(rep('overall',2),rep('selected_initial_errors',3)),
  condition=c('initial','self_check','initial','self_check','cross_check'),
  wrong=c(overall_initial_wrong,overall_self_wrong,wrong),
  denominator=c(overall_n,overall_n,rep(N,3)),
  wrong_answer_rate=c(overall_initial_wrong/overall_n,overall_self_wrong/overall_n,wrong/N)),
  file.path(out,'rq1_two_populations_v16.csv'),row.names=FALSE)
