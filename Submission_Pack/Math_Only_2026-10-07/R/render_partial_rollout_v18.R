#!/usr/bin/env Rscript
# Reconstruct explicitly labelled bank-level partial-intervention scenarios.
# Untested questions keep their observed initial answer; no model result is
# imputed or represented as an observed all-question check.
suppressPackageStartupMessages({library(ggplot2);library(jsonlite);library(grid);library(ragg)})
args <- commandArgs(trailingOnly=TRUE)
private <- if(length(args)>=1) args[[1]] else '../Math_Benchmark_500_Private_2026-10-06'
out <- if(length(args)>=2) args[[2]] else 'Submission_Pack/Math_Only_2026-10-07/figures/partial_rollout_v18'
dir.create(out,recursive=TRUE,showWarnings=FALSE)
m2 <- read.csv(file.path(private,'m2_self_review_2026-10-07/derived/m2_grade_ledger_v1.csv'))
cross <- read.csv(file.path(private,'natural_crosscheck_2026-10-07/analysis/paired_70_m1_m2_b1_c1_v1.csv'))
human <- read.csv(file.path(private,'natural_crosscheck_2026-10-07/analysis/m2_m4_latest_paired.csv'))
advice <- read.csv(file.path(private,'natural_crosscheck_2026-10-07/analysis/m3_m4_latest_selection_audit.csv'))
valid <- c('correct','incorrect','explicit_abstention','abstain','abstention')
initial <- subset(m2, initial_grade %in% valid)
self_pair <- subset(m2, initial_grade %in% valid & m2_grade %in% valid)
cross_pair <- subset(cross, m1_grade %in% valid & m2_grade %in% valid & c1_grade %in% valid)
ai_on_68 <- subset(advice, condition=='wrong_agent' & question_id %in% human$question_id)
stopifnot(nrow(initial)==493L, !anyDuplicated(initial$question_id),
          nrow(self_pair)==488L,sum(self_pair$initial_grade!='correct')==66L,
          sum(self_pair$m2_grade!='correct')==42L,
          nrow(cross_pair)==63L,!anyDuplicated(cross_pair$question_id),
          all(cross_pair$question_id %in% initial$question_id),
          all(cross_pair$m1_grade!='correct'),
          nrow(human)==68L,!anyDuplicated(human$question_id),
          all(human$question_id %in% initial$question_id),
          all(initial$initial_grade[match(human$question_id,initial$question_id)]=='correct'),
          nrow(ai_on_68)==68L,!anyDuplicated(ai_on_68$question_id),
          all(ai_on_68$final_grade %in% valid))
n <- nrow(initial);base_wrong <- sum(initial$initial_grade!='correct')
selected_wrong <- nrow(cross_pair)
unchanged_wrong_63 <- base_wrong-selected_wrong
self_wrong_63 <- sum(cross_pair$m2_grade!='correct')
cross_wrong_63 <- sum(cross_pair$c1_grade!='correct')
self_corrected_63 <- sum(cross_pair$m2_grade=='correct')
cross_corrected_63 <- sum(cross_pair$c1_grade=='correct')
self_new_68 <- sum(human$m2_grade!='correct')
ai_new_68 <- sum(ai_on_68$final_grade!='correct')
user_new_68 <- sum(human$m4_grade!='correct')
stopifnot(base_wrong==70L, unchanged_wrong_63==7L,
          self_wrong_63==32L,cross_wrong_63==8L,
          self_corrected_63==31L,cross_corrected_63==55L,
          self_new_68==1L,ai_new_68==0L,user_new_68==10L)

scenario <- data.frame(
  experiment=c(rep('63 initially wrong selected',3),rep('68 initially correct selected',4)),
  condition=c('Initial answer','Self-check','Cross-check',
              'Initial answer','Neutral self-check','Wrong AI advice','False user challenge'),
  wrong=c(base_wrong,
          unchanged_wrong_63+self_wrong_63,
          unchanged_wrong_63+cross_wrong_63,
          base_wrong,base_wrong+self_new_68,base_wrong+ai_new_68,base_wrong+user_new_68),
  denominator=n,
  tested_n=c(0,63,63,0,68,68,68),
  assumption='Only the named selected cases receive the intervention; all others retain their initial answer.')
scenario$rate <- scenario$wrong/scenario$denominator
write.csv(scenario,file.path(out,'bank_level_partial_rollout_v18.csv'),row.names=FALSE)

theme_chart <- theme_minimal(base_family='Arial',base_size=17)+
  theme(panel.grid.major.y=element_blank(),panel.grid.minor=element_blank(),
        axis.title=element_blank(),axis.text.y=element_text(color='#52677a',size=16),
        axis.text.x=element_text(color='#6a7e91',size=14),
        plot.title=element_text(face='bold',color='#163149',size=18,margin=margin(b=8)),
        plot.margin=margin(6,62,6,5))
error_fill <- function(rate){
  anchor_rate <- c(0,.02,.10,.20,.60,1)
  anchor_rgb <- t(col2rgb(c('#FCE8E6','#F3B7B1','#DE6B62','#C53932','#8B0000','#670000')))
  out <- vapply(seq_len(3),function(j)approx(anchor_rate,anchor_rgb[,j],xout=rate,rule=2)$y,
                numeric(length(rate)))
  rgb(out[,1]/255,out[,2]/255,out[,3]/255)
}
draw_rate <- function(d,title='',max_rate=.22,breaks=c(0,.05,.10,.15,.20),font_size=5){
  d$condition <- factor(d$condition,levels=rev(d$condition))
  d$shown <- sprintf('%d/%d  (%.2f%%)',d$wrong,d$denominator,100*d$rate)
  d$fill <- error_fill(d$rate)
  ggplot(d,aes(condition,rate,fill=fill))+
    geom_col(width=.58,show.legend=FALSE)+
    geom_text(aes(label=shown),hjust=-.06,color='#163149',fontface='bold',size=font_size)+
    scale_fill_identity()+scale_y_continuous(limits=c(0,max_rate),breaks=breaks,
      labels=function(x)paste0(round(100*x),'%'),expand=expansion(mult=c(0,0)))+
    coord_flip(clip='off')+labs(title=title)+theme_chart
}
cross_d <- subset(scenario,experiment=='63 initially wrong selected')
induct_d <- subset(scenario,experiment=='68 initially correct selected')
cross_bar <- draw_rate(cross_d,'Illustrative bank rate /493: 63 selected checks')
observed_self_d <- data.frame(condition=c('Initial answer','Self-check'),
  wrong=c(sum(self_pair$initial_grade!='correct'),sum(self_pair$m2_grade!='correct')),
  denominator=rep(nrow(self_pair),2))
observed_self_d$rate <- observed_self_d$wrong/observed_self_d$denominator
observed_self_bar <- draw_rate(observed_self_d,'Observed self-check: 488 matched answers')
induct_bar <- draw_rate(induct_d,'Illustrative bank rate /493: 68 selected challenges',.22,
                        c(0,.05,.10,.15,.20),4.8)
correction_d <- data.frame(condition=factor(c('Self-check','Cross-check'),
  levels=rev(c('Self-check','Cross-check'))),n=c(self_corrected_63,cross_corrected_63),
  shown=sprintf('%d/%d  (%.2f%%)',c(self_corrected_63,cross_corrected_63),63,
                100*c(self_corrected_63,cross_corrected_63)/63),
  fill=c('#43a869','#168b57'))
correction_bar <- ggplot(correction_d,aes(condition,n/63,fill=fill))+
  geom_col(width=.58,show.legend=FALSE)+
  geom_text(aes(label=shown),hjust=-.07,color='#163149',fontface='bold',size=5)+
  scale_fill_identity()+scale_y_continuous(limits=c(0,1.15),
    breaks=c(0,.25,.50,.75,1),labels=function(x)paste0(round(100*x),'%'),
    expand=expansion(mult=c(0,0)))+coord_flip(clip='off')+
  labs(title='Correction among the same 63 errors')+theme_chart

agg_png(file.path(out,'cross_total_and_correction_v18.png'),width=2400,height=900,res=160,background='white')
grid.newpage();pushViewport(viewport(layout=grid.layout(1,2,widths=unit(c(.53,.47),'null'))))
print(cross_bar,vp=viewport(layout.pos.row=1,layout.pos.col=1),newpage=FALSE)
print(correction_bar,vp=viewport(layout.pos.row=1,layout.pos.col=2),newpage=FALSE)
dev.off()
agg_png(file.path(out,'observed_self_and_partial_cross_v18.png'),width=2400,height=650,res=160,background='white')
grid.newpage();pushViewport(viewport(layout=grid.layout(1,2,widths=unit(c(.52,.48),'null'))))
print(observed_self_bar,vp=viewport(layout.pos.row=1,layout.pos.col=1),newpage=FALSE)
print(cross_bar,vp=viewport(layout.pos.row=1,layout.pos.col=2),newpage=FALSE)
dev.off()
agg_png(file.path(out,'cross_total_compact_v18.png'),width=1100,height=610,res=160,background='white')
print(cross_bar+theme(plot.title=element_blank()));dev.off()
agg_png(file.path(out,'induction_total_v18.png'),width=1700,height=760,res=160,background='white')
print(induct_bar);dev.off()
agg_png(file.path(out,'induction_total_no_title_v18.png'),width=1700,height=680,res=160,background='white')
print(induct_bar+theme(plot.title=element_blank(),plot.margin=margin(0,55,20,6)));
dev.off()
agg_png(file.path(out,'induction_total_compact_v18.png'),width=1400,height=600,res=160,background='white')
print(induct_bar+theme(plot.title=element_blank(),axis.text.y=element_text(size=14)));
dev.off()
