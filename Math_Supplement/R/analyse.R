source('Math_Supplement/R/common.R')
args<-commandArgs(trailingOnly=TRUE);split<-if(length(args))args[1] else 'supplementary'
out<-if(length(args)>1)args[2] else file.path(MROOT,'reports',split)
dir.create(out,recursive=TRUE,showWarnings=FALSE)
qs<-indexed(read_jsonl(file.path(MROOT,'protocol/questions.jsonl')),'question_id')
frozen<-read_json(file.path(MROOT,'protocol',paste0('freeze-',split,'.json')))
records<-unlist(lapply(MODELS,function(p)read_jsonl(file.path(MROOT,'runs',p,'responses.jsonl'))),recursive=FALSE)
rs<-Filter(function(r)r$stage=='receive'&&r$split==split,records)
stopifnot(length(rs)>0,!anyDuplicated(field(rs,'task_id')))
expected<-length(frozen$question_ids)*3*if(split=='development')7 else 14
stopifnot(length(rs)==expected)
rows<-lapply(rs,function(r){
 q<-qs[[r$question_id]];a<-parse_math(r$text %||% '')
 data.frame(task_id=r$task_id,question_id=r$question_id,family=q$family,kind=q$kind,provider=r$provider,donor=r$donor,
 repeat_id=r$repeat_id,condition=r$condition,cell_id=paste(r$question_id,r$provider,r$repeat_id,sep=':'),
 grade=if(r$status=='ok')math_grade(r$text,q) else 'unscorable',
 strict_json_schema_valid=valid_answer(parse_json(r$text %||% '')),
 conclusion=if(is.list(a))a$conclusion %||% '' else '',
 reason=if(is.list(a))a$reason %||% '' else '',
 reason_missing=!(is.list(a)&&is.character(a$reason)&&nzchar(a$reason)),
 question=q$question,gold=mjson(q$gold),response_text=r$text %||% '',http_status=r$http_status %||% NA,
 response_status=r$status,material_id=r$material_id %||% '',material_sha256=r$material_sha256 %||% '',
 input_tokens=r$input_tokens %||% 0,output_tokens=r$output_tokens %||% 0,cost_guard_cny=r$cost_guard_cny,
 stringsAsFactors=FALSE)
})
d<-do.call(rbind,rows);d<-d[order(d$task_id),];row.names(d)<-NULL
unit<-split(d,d$cell_id)
complete<-vapply(unit,function(z)nrow(z)==7&&setequal(z$condition,CONDITIONS)&&!any(z$grade=='unscorable'),TRUE)
d$complete_pair<-unname(complete[d$cell_id]);main<-d[d$complete_pair,]
cells<-do.call(rbind,lapply(unit,function(z){
 v<-setNames(z$grade,z$condition);data.frame(cell_id=z$cell_id[1],question_id=z$question_id[1],family=z$family[1],kind=z$kind[1],provider=z$provider[1],repeat_id=z$repeat_id[1],complete_pair=complete[z$cell_id[1]],as.list(v[CONDITIONS]),check.names=FALSE)
}));row.names(cells)<-NULL
stopifnot(all(table(d$cell_id)==7))
# Audit request-level pairing, not just score-level grouping.
ri<-indexed(rs,'task_id');materials<-read_json(file.path(MROOT,'protocol',paste0('materials-',split,'.json')))
for(r in rs){
 q<-qs[[r$question_id]];cond<-r$condition
 if(cond=='baseline')expected_msg<-receiver_messages(q) else{
  b<-ri[[r$baseline_id]];stopifnot(!is.null(b),b$condition=='baseline',b$question_id==r$question_id,b$provider==r$provider,b$repeat_id==r$repeat_id)
  m<-if(cond=='C0')NULL else materials[[r$material_id]]
  expected_msg<-receiver_messages(q,cond,b$text,m)
 }
 actual<-r$request$messages
 if(r$provider=='minimax')actual<-c(list(list(role='system',content=r$request$system)),actual)
 stopifnot(identical(actual,expected_msg))
}
summarise<-function(z,label,scope){
 c<-cells[cells$complete_pair&cells$cell_id%in%z$cell_id,];nc<-sum(c$baseline=='correct');nw<-sum(c$baseline=='incorrect')
 do.call(rbind,lapply(CONDITIONS,function(cond){
  s<-z[z$condition==cond,];v<-c[[cond]]
  data.frame(scope=scope,group=label,condition=cond,n=nrow(s),correct=sum(s$grade=='correct'),incorrect=sum(s$grade=='incorrect'),abstain=sum(s$grade=='abstain'),
  baseline_correct=nc,baseline_incorrect=nw,harm=sum(c$baseline=='correct'&v=='incorrect'),repair=sum(c$baseline=='incorrect'&v=='correct'),
  harm_pct=if(nc)100*sum(c$baseline=='correct'&v=='incorrect')/nc else NA_real_,repair_pct=if(nw)100*sum(c$baseline=='incorrect'&v=='correct')/nw else NA_real_)
 }))
}
tabs<-list(summarise(main,'all','pooled'))
for(by in c('provider','family','kind'))for(v in unique(main[[by]]))tabs[[length(tabs)+1]]<-summarise(main[main[[by]]==v,],v,by)
tabs<-do.call(rbind,tabs);row.names(tabs)<-NULL
ids<-unique(c(main$cell_id[main$condition=='baseline'&main$grade!='correct'],
 cells$cell_id[cells$complete_pair&cells$baseline=='correct'&(cells$C2=='incorrect'|cells$C3=='incorrect')],
 cells$cell_id[cells$complete_pair&cells$C4!=cells$C5],d$cell_id[!d$complete_pair]))
review<-d[d$cell_id%in%ids,];review$AI_semantic_review<-'';review$human_review<-''
csv<-function(x,name)write.csv(x,file.path(out,name),row.names=FALSE,na='')
csv(d,'graded_responses.csv');csv(cells,'cells.csv');csv(tabs,'tables.csv');csv(review,'review_queue.csv')
pool<-tabs[tabs$scope=='pooled',]
usage<-do.call(rbind,lapply(MODELS,function(p){z<-Filter(function(r)r$provider==p,records);data.frame(provider=p,calls=length(z),input_tokens=sum(vapply(z,function(r)r$input_tokens %||% 0,0)),output_tokens=sum(vapply(z,function(r)r$output_tokens %||% 0,0)),guard_equivalent_cny=sum(vapply(z,function(r)r$cost_guard_cny,0)),cash_price_verified=p!='minimax')}))
csv(usage,'all_stage_usage.csv')
write_json(list(split=split,planned_viability_met=isTRUE(frozen$viable),partial_supplement=!isTRUE(frozen$viable),selected_items=length(frozen$question_ids),reasoning_families=length(unique(d$family)),responses=nrow(d),expected_responses=expected,complete_cells=sum(complete),excluded_cells=sum(!complete),unscorable_responses=sum(d$grade=='unscorable'),complete_responses=nrow(main),baseline_counts=as.list(table(main$grade[main$condition=='baseline'])),branch_request_audit=TRUE,no_inferential_CI=TRUE,independent_human_review=FALSE),file.path(out,'summary.json'))
library(ggplot2)
plotdata<-as.data.frame(table(factor(main$condition,levels=CONDITIONS),factor(main$grade,levels=c('correct','incorrect','abstain'))));names(plotdata)<-c('condition','grade','n')
g<-ggplot(plotdata,aes(condition,n,fill=grade))+geom_col(width=.7)+scale_fill_manual(values=c(correct='#168478',incorrect='#ce6247',abstain='#93a2b3'))+labs(title=paste('Mathematics:',split),subtitle=sprintf('%d items, %d complete units; four selected reasoning families, not population inference',length(frozen$question_ids),sum(complete)),x=NULL,y='Responses',fill=NULL)+theme_minimal(base_size=12)+theme(legend.position='bottom',panel.grid.major.x=element_blank())
ggsave(file.path(out,'outcomes.png'),g,width=9,height=4.8,dpi=180)
lines<-c(paste0('# Mathematics ',split,' results'),'',if(!isTRUE(frozen$viable)) 'PARTIAL SUPPLEMENT: the planned balanced viability criterion was not met. Only 13 of 16 supplementary items were retained; both integer controls and one integer trap failed material review. A documented amendment authorized descriptive collection before receiver outcomes were viewed.' else '', '',sprintf('%d selected items; %d returned receiver records; %d complete paired units; %d unscorable responses. Each unit has baseline plus six independent branches.',length(frozen$question_ids),nrow(d),sum(complete),sum(d$grade=='unscorable')),
 'Four selected reasoning families. Parameter variants/repeats are dependent. No population confidence interval, significance test or universal method/model ranking is reported.',
 '', '|Condition|Correct|Wrong|Uncertain|Correct-to-wrong|Wrong-to-correct|','|---|---:|---:|---:|---:|---:|',
 vapply(seq_len(nrow(pool)),function(i){z<-pool[i,];sprintf('|%s|%d|%d|%d|%d/%d|%d/%d|',z$condition,z$correct,z$incorrect,z$abstain,z$harm,z$baseline_correct,z$repair,z$baseline_incorrect)},''),
 '', 'A zero denominator means the outcome cannot be estimated, not zero risk or zero benefit. Logical inconsistency, no integer solutions and insufficient information are correct conclusions when proven from the question, not refusal.',
 '', '## Interpretation limits',
 'The schema explicitly offers logical conclusion categories and may cue checking. Wrong peer explanations verbalize researcher-specified flawed routes after development material failures; these do not measure spontaneous peer mistakes. Final-field accuracy does not validate every step of a reason. See the separate semantic review queue and collection audit. These results are not pooled with the factual study.',
 '', 'C0 is neutral rechecking; C1 wrong answer only; C2 wrong explanation; C3 same C2 plus structured check; C4 correct explanation; C5 same C4 plus structured check.')
writeLines(lines,file.path(out,'report.md'))
writeLines(capture.output(sessionInfo()),file.path(out,'sessionInfo.txt'))
cat(paste(lines[1:15],collapse='\n'),'\n')
