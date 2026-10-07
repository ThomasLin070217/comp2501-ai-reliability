#!/usr/bin/env Rscript
# COMP2501: distinguish observed overall rates, selected-case correction,
# and explicitly hypothetical partial-rollout rates. No question text is read.
suppressPackageStartupMessages({library(jsonlite);library(ggplot2);library(grid);library(ragg)})
args <- commandArgs(trailingOnly=TRUE)
private <- if(length(args)>=1) args[[1]] else '../Math_Benchmark_500_Private_2026-10-06'
out <- if(length(args)>=2) args[[2]] else 'Submission_Pack/Math_Only_2026-10-07/figures/denominator_clarification_v17'
dir.create(out,recursive=TRUE,showWarnings=FALSE)
m2 <- read.csv(file.path(private,'m2_self_review_2026-10-07/derived/m2_grade_ledger_v1.csv'))
cross <- fromJSON(file.path(private,'natural_crosscheck_2026-10-07/analysis/conditional_crosscheck_summary_v1.json'))
human <- read.csv(file.path(private,'natural_crosscheck_2026-10-07/analysis/m2_m4_latest_paired.csv'))
advice <- fromJSON(file.path(private,'natural_crosscheck_2026-10-07/analysis/m3_m4_latest_summary.json'))
valid <- c('correct','incorrect','explicit_abstention','abstain','abstention')
initial <- m2[m2$initial_grade %in% valid,]
paired <- m2[m2$initial_grade %in% valid & m2$m2_grade %in% valid,]
stopifnot(nrow(initial)==493L,sum(initial$initial_grade!='correct')==70L,
          nrow(paired)==488L,sum(paired$initial_grade!='correct')==66L,
          sum(paired$m2_grade!='correct')==42L,
          cross$m2_c1_paired_n==63L,cross$m2_correct_on_pair==31L,
          cross$c1_correct_on_pair==55L,
          identical(as.integer(unlist(cross$m2_c1_table)),c(30L,1L,25L,7L)),
          nrow(human)==68L,all(human$question_id %in% initial$question_id),
          all(initial$initial_grade[match(human$question_id,initial$question_id)]=='correct'),
          sum(human$m2_grade!='correct')==1L,sum(human$m4_grade!='correct')==10L,
          advice$m3$incorrect==0L)
theme_chart <- theme_minimal(base_family='Arial',base_size=17)+
  theme(panel.grid.major.y=element_blank(),panel.grid.minor=element_blank(),
        axis.title=element_blank(),axis.text.y=element_text(color='#52677a',size=16),
        axis.text.x=element_text(color='#6a7e91',size=14),
        plot.title=element_text(face='bold',color='#163149',size=19,margin=margin(b=8)),
        plot.margin=margin(6,65,6,6))
bar <- function(labels,nums,denoms,fills,title,max_rate,breaks){
  stopifnot(length(labels)==length(nums),length(nums)==length(denoms))
  d <- data.frame(label=factor(labels,levels=rev(labels)),rate=nums/denoms,
                  shown=sprintf('%d/%d  (%.2f%%)',nums,denoms,100*nums/denoms),fill=fills)
  ggplot(d,aes(label,rate,fill=fill))+geom_col(width=.58,show.legend=FALSE)+
    geom_text(aes(label=shown),hjust=-.08,color='#163149',fontface='bold',size=5)+
    scale_fill_identity()+scale_y_continuous(limits=c(0,max_rate),breaks=breaks,
      labels=function(x)paste0(round(100*x),'%'),expand=expansion(mult=c(0,0)))+
    coord_flip(clip='off')+labs(title=title)+theme_chart
}
overall <- bar(c('Initial answer','Self-check'),c(66,42),rep(488,2),
  c('#d45b52','#ec8b83'),'Overall wrong-answer rate: same 488 questions',.24,
  c(0,.05,.10,.15,.20))
correction <- bar(c('Self-check','Cross-check'),c(31,55),rep(63,2),
  c('#43a869','#168b57'),'Corrections among 63 initial errors',1.15,
  c(0,.25,.50,.75,1))
agg_png(file.path(out,'overall_and_selected_correction_v17.png'),width=2400,height=900,res=160,background='white')
grid.newpage();pushViewport(viewport(layout=grid.layout(1,2,widths=unit(c(.53,.47),'null'))))
print(overall,vp=viewport(layout.pos.row=1,layout.pos.col=1),newpage=FALSE)
print(correction,vp=viewport(layout.pos.row=1,layout.pos.col=2),newpage=FALSE)
dev.off()
transitions <- data.frame(
  label=factor(c('Both correct','Only cross-check correct','Only self-check correct','Both wrong'),
    levels=rev(c('Both correct','Only cross-check correct','Only self-check correct','Both wrong'))),
  n=c(30,25,1,7),fill=c('#9ab3a5','#168b57','#e8b0a8','#6f8190'))
transitions$shown <- sprintf('%d/63',transitions$n)
p_transition <- ggplot(transitions,aes(label,n,fill=fill))+
  geom_col(width=.6,show.legend=FALSE)+
  geom_text(aes(label=shown),hjust=-.12,color='#163149',fontface='bold',size=5.6)+
  scale_fill_identity()+scale_y_continuous(limits=c(0,39),breaks=c(0,10,20,30),
    expand=expansion(mult=c(0,0)))+coord_flip(clip='off')+
  labs(title=NULL)+theme_chart
agg_png(file.path(out,'paired_outcomes_63_v17.png'),width=1100,height=610,res=160,background='white')
print(p_transition);dev.off()
agg_png(file.path(out,'correction_63_v17.png'),width=1100,height=610,res=160,background='white')
print(correction+theme(plot.title=element_blank()));dev.off()

# These values are intentionally not used as observed full-bank error rates.
# They describe an artificial partial rollout in which all unselected answers
# are held at their original responses; the user may choose to show this
# scenario only with a prominent assumptions label.
scenario <- data.frame(
  condition=c('Initial bank','Self-check on 63 errors only','Cross-check on 63 errors only',
              'Self-check on 68 correct only','AI advice on 68 correct only',
              'User challenge on 68 correct only'),
  wrong=c(70,39,15,71,70,80),denominator=rep(493,6),
  metric='hypothetical_partial_rollout')
scenario$rate <- scenario$wrong/scenario$denominator
measured <- data.frame(
  condition=c('Initial full bank','Initial on full self pair','Self on full self pair',
              'Self on cross pair','Cross on cross pair',
              'Self on selected correct pair','AI advice on selected correct pair',
              'User challenge on selected correct pair'),
  wrong=c(70,66,42,32,8,1,0,10),
  denominator=c(493,488,488,63,63,68,68,68),metric='observed')
measured$rate <- measured$wrong/measured$denominator
write.csv(measured,file.path(out,'observed_rates_v17.csv'),row.names=FALSE)
write.csv(scenario,file.path(out,'hypothetical_partial_rollout_v17.csv'),row.names=FALSE)
write.csv(transitions[,c('label','n','shown')],file.path(out,'paired_outcomes_63_v17.csv'),row.names=FALSE)
