# Independent arithmetic and linkage checks on R analysis outputs.
source('Natural_Crosscheck/R/common.R')
p<-'Natural_Crosscheck/reports'
g<-read.csv(file.path(p,'graded_responses.csv'));c<-read.csv(file.path(p,'cells.csv'));t<-read.csv(file.path(p,'tables.csv'));e<-read.csv(file.path(p,'effects.csv'));tr<-read.csv(file.path(p,'transitions.csv'));b<-read.csv(file.path(p,'missing_bounds.csv'))
checks<-list()
check<-function(name,x){stopifnot(isTRUE(x));checks[[name]]<<-TRUE}
check('planned588_distinct',nrow(g)==588&&!anyDuplicated(g$task_id))
check('147_cells_49_questions',nrow(c)==147&&length(unique(c$question_id))==49)
check('all_conditions_once',all(table(g$cell_id,g$condition)==1))
check('table_denominators',all(t$n==t$correct+t$wrong+t$abstain))
check('error_definition',all(abs(t$error_pct-100*t$wrong/t$n)<1e-9))
check('effect_definition',all(abs(e$difference_pp-(e$a_pct-e$b_pct))<1e-9))
for(i in seq_len(nrow(e))){x<-e[i,];z<-tr[tr$domain==x$domain&tr$provider==x$provider&tr$comparison==x$comparison,];target<-switch(x$metric,error='incorrect',correct='correct',abstain='abstain');stopifnot(sum(z$n)==x$n,abs(100*(sum(z$n[z$to==target])-sum(z$n[z$from==target]))/x$n-x$difference_pp)<1e-9)}
check('all_transition_effects_agree',TRUE)
check('missing_bound_order',all(b$difference_lower_pp<=b$difference_upper_pp))
check('domains_separate',identical(sort(unique(t$domain)),c('facts','mathematics')))
check('no_math_inference',all(is.na(e$ci_low_pp[e$domain=='mathematics'])))
check('ci_contains_point',all(e$ci_low_pp[e$domain=='facts']<=e$difference_pp[e$domain=='facts']&e$ci_high_pp[e$domain=='facts']>=e$difference_pp[e$domain=='facts']))
# Four-output common-sample effects: reported separately from available pairs.
z<-c[c$complete,];common<-do.call(rbind,lapply(split(z,z$domain),function(d)do.call(rbind,lapply(list(c('N2','N1'),c('N2','N0'),c('N3','N2')),function(cc)data.frame(domain=d$domain[1],comparison=paste(cc,collapse='-'),n=nrow(d),difference_pp=100*mean((d[[cc[1]]]=='incorrect')-(d[[cc[2]]]=='incorrect')))))))
write.csv(common,file.path(p,'common_sample_effects.csv'),row.names=FALSE)
# A concise view for reviewing format failures without modifying final grades.
invalid<-g[!g$grade%in%c('correct','incorrect','abstain'),]
write.csv(as.data.frame(table(invalid$domain,invalid$provider,invalid$condition,invalid$response_status)),file.path(p,'missing_by_model_domain.csv'),row.names=FALSE)
write_json(list(checks=checks,checks_passed=length(checks),session=capture.output(sessionInfo()),analysis_sha256=file_sha('Natural_Crosscheck/R/analyse.R')) ,file.path(p,'validation.json'))
print(checks)
