# All experimental reading, selection, arithmetic, charting and exports use R.
# JS/Python builders only lay out these prepared values and text.
library(jsonlite);library(digest);library(ggplot2);library(knitr)
pack<-'Submission_Pack';fdir<-'Followup_Validation/reports'
e<-read.csv(file.path(fdir,'effects.csv'));g<-read.csv(file.path(fdir,'graded_responses.csv'))
legacy<-fromJSON(file.path(pack,'evidence/visualization_data.json'))
pick<-function(domain,comparison,metric='error',provider='pooled'){
 z<-e[e$domain==domain&e$comparison==comparison&e$metric==metric&e$provider==provider,];stopifnot(nrow(z)==1);z
}
fmt<-function(z,adjusted=FALSE){
 z$before_label<-sprintf('%.2f%%',z$before_pct);z$after_label<-sprintf('%.2f%%',z$after_pct)
 z$change_label<-sprintf('%+.2f percentage points',z$difference_pp)
 z$count_label<-sprintf('%d/%d and %d/%d wrong',z$before_n,z$n,z$after_n,z$n)
 z$interval_label<-if(adjusted)sprintf('97.5%% interval [%.2f, %.2f] pp',z$familywise_low,z$familywise_high)else sprintf('95%% interval [%.2f, %.2f] pp',z$ci_low,z$ci_high)
 z
}
f<-fmt(pick('facts','N2-N1'),TRUE);m<-fmt(pick('mathematics','N2-N1'),TRUE)
clean<-fmt(pick('facts','W1-W0'));remind<-fmt(pick('facts','W2-W1'));direct<-fmt(pick('mathematics','N2-N0'))
models<-e[e$domain=='facts'&e$comparison=='N2-N1'&e$metric=='error'&e$provider!='pooled',]
wrong<-legacy$error_rates[match(c('C0','C1','C2'),legacy$error_rates$condition),]
charts<-list()
pairchart<-function(id,z,cats,maxrate=1){charts[[id]]<<-list(categories=cats,values=c(z$before_pct,z$after_pct)/100,counts=c(sprintf('%d/%d',z$before_n,z$n),sprintf('%d/%d',z$after_n,z$n)),max=maxrate,change=z$change_label,interval=z$interval_label)}
pairchart('facts',f,c('Self-check','Cross-model check'))
pairchart('math',m,c('Self-check','Cross-model check'),.10)
pairchart('verification',clean,c('Ordinary recheck','Verification'))
pairchart('reminder',remind,c('Without reminder','With reminder'))
charts$misleading<-list(categories=c('Neutral recheck','Wrong answer','Wrong + reason'),values=wrong$rate,counts=sprintf('%d/%d',wrong$wrong,wrong$n),max=1)
charts$models<-list(categories=c('DeepSeek','Kimi','MiniMax'),series=list(list(name='Self-check',values=models$before_pct/100),list(name='Cross-model check',values=models$after_pct/100)),max=1)
rc<-do.call(rbind,lapply(c('error','correct','abstain'),function(k)pick('facts','W2-W1',k)))
charts$outcomes<-list(categories=c('Wrong','Correct','Abstain'),series=list(list(name='Without reminder',values=rc$before_pct/100),list(name='With reminder',values=rc$after_pct/100)),max=1)
dir.create(file.path(pack,'figures/integrated'),showWarnings=FALSE,recursive=TRUE)
for(id in names(charts)){
 c<-charts[[id]]
 if(is.null(c$series)){
  dd<-data.frame(category=factor(c$categories,levels=c$categories),rate=c$values,label=sprintf('%.2f%%\n%s',100*c$values,c$counts))
  plot<-ggplot(dd,aes(category,rate,fill=category))+geom_col(width=.55)+geom_text(aes(label=label),vjust=-.2,size=4.1)+scale_fill_manual(values=if(id=='misleading')c('#657586','#C45F48','#C45F48')else c('#657586','#147E77'),guide='none')
 }else{
  dd<-do.call(rbind,lapply(c$series,function(s)data.frame(category=factor(c$categories,levels=c$categories),series=s$name,rate=s$values)))
  dd$series<-factor(dd$series,levels=vapply(c$series,`[[`,'','name'))
  plot<-ggplot(dd,aes(category,rate,fill=series))+geom_col(position=position_dodge(.7),width=.6)+geom_text(aes(label=sprintf('%.2f%%',100*rate)),position=position_dodge(.7),vjust=-.4,size=3.9)+scale_fill_manual(values=c('#657586','#147E77'),name=NULL)
 }
 plot<-plot+scale_y_continuous(limits=c(0,c$max),breaks=seq(0,c$max,length.out=5),labels=function(v)paste0(100*v,'%'),expand=expansion(mult=c(0,.08)))+labs(x=NULL,y=if(id=='outcomes')'Responses (%)'else'Wrong answers (%)')+theme_minimal(base_size=13)+theme(panel.grid.minor=element_blank(),panel.grid.major.x=element_blank(),legend.position='bottom')
 ggsave(file.path(pack,'figures/integrated',paste0(id,'.png')),plot,width=9,height=4.6,dpi=180,bg='white')
 write.csv(dd,file.path(pack,'evidence',paste0('integrated_chart_',id,'.csv')),row.names=FALSE)
}
tab<-function(x)paste(capture.output(print(kable(x,format='pipe',row.names=FALSE,digits=2))),collapse='\n')
effecttable<-function(x,adjust=FALSE)data.frame(Domain=x$domain,Comparison=x$comparison,Pairs=x$n,Before=sprintf('%d/%d (%.2f%%)',x$before_n,x$n,x$before_pct),After=sprintf('%d/%d (%.2f%%)',x$after_n,x$n,x$after_pct),Change_pp=sprintf('%+.2f',x$difference_pp),Interval=if(adjust)sprintf('[%.2f, %.2f]',x$familywise_low,x$familywise_high)else sprintf('[%.2f, %.2f]',x$ci_low,x$ci_high))
tables<-list(primary=effecttable(rbind(f,m),TRUE),ablation=effecttable(rbind(clean,remind)),secondary=effecttable(subset(e,provider=='pooled'&metric=='error'&comparison%in%c('N2-N0','N3-N2'))),models=data.frame(Receiver=models$provider,Pairs=models$n,Self_check=sprintf('%.2f%%',models$before_pct),Cross_check=sprintf('%.2f%%',models$after_pct),Change_pp=sprintf('%+.2f',models$difference_pp)),outcomes=data.frame(Outcome=c('Wrong','Correct','Abstain'),Without=rc$before_n,With=rc$after_n,Pairs=rc$n))
fs<-read.csv(file.path(fdir,'format_sensitivity_effects.csv'));rp<-read.csv(file.path(fdir,'reasoning_paired_sensitivity.csv'));bounds<-read.csv(file.path(fdir,'missing_bounds.csv'))
tables$format<-subset(fs,comparison=='N2-N1'&outcome=='incorrect')[,c('domain','n','before','after','difference_pp','ci975_low','ci975_high')]
tables$reasoning<-subset(rp,label=='incorrect')[,c('version','pairs','N1','N2','difference_pp','ci_low','ci_high')]
tables$bounds<-subset(bounds,provider=='pooled'&comparison%in%c('N2-N1','N2-N0','W2-W1'))[,c('domain','comparison','planned','paired','low','high')]
old<-subset(legacy$effects,provider=='pooled'&variant=='primary'&metric=='error')
tables$controlled<-data.frame(Comparison=old$comparison,Pairs=old$left_den,Before=sprintf('%.2f%%',old$left_pct),After=sprintf('%.2f%%',old$right_pct),Change_pp=sprintf('%+.2f',old$difference_pp),CI95=sprintf('[%.2f, %.2f]',old$ci_low_pp,old$ci_high_pp))
write_json(list(charts=charts,facts=f,math=m,clean=clean,reminder=remind,direct_math=direct,tables=tables,authors=c('LINYUNIAN','PAN ZHENGYU'),date='4 October 2026'),file.path(pack,'evidence/integrated_data.json'),pretty=TRUE,auto_unbox=TRUE,digits=NA)
for(n in names(tables))writeLines(tab(tables[[n]]),file.path(pack,'evidence',paste0('integrated_table_',n,'.md')))
sources<-c(file.path(fdir,c('effects.csv','graded_responses.csv','format_sensitivity_effects.csv','reasoning_paired_sensitivity.csv','missing_bounds.csv')),file.path(pack,'evidence/visualization_data.json'))
write_json(list(source_sha256=setNames(lapply(sources,function(f)digest(file=f,algo='sha256')),sources),processing='R only; all charts and displayed numerical labels derive from saved R results',separate_experiments=TRUE),file.path(pack,'evidence/integrated_provenance.json'),pretty=TRUE,auto_unbox=TRUE)
writeLines(trimws(capture.output(sessionInfo()),which='right'),file.path(pack,'evidence/integrated_R_session.txt'))
stopifnot(sum(rc$before_n)==210,sum(rc$after_n)==210,f$n==578,m$n==199,nrow(g)==4032)
cat('Integrated R exports and seven figures prepared.\n')
