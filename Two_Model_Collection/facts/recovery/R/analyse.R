# Derived overlay only; immutable original run remains the primary analysis.
source('Two_Model_Collection/facts/recovery/R/common.R')
status<-fromJSON(file.path(rc_root,'runs/status.json'),simplifyVector=FALSE)
stopifnot(identical(status$status,'finished'))
original<-tm_read(file.path(rc_original,'runs/completed.jsonl'))
recovered<-tm_read(file.path(rc_root,'runs/completed.jsonl'))
original_skips<-tm_read(file.path(rc_original,'runs/skipped.jsonl'))
out<-file.path(rc_root,'derived');for(d in c('runs','protocol','reports'))dir.create(file.path(out,d),recursive=TRUE,showWarnings=FALSE)
for(f in c('tasks.csv','questions.jsonl','prompts.json'))stopifnot(file.copy(file.path(rc_original,'protocol',f),file.path(out,'protocol',f),overwrite=TRUE))
working<-setNames(original,tm_fields(original,'id'))
for(r in recovered)working[[r$id]]<-r
remaining_skips<-Filter(function(s)!s$id%in%tm_fields(recovered,'id'),original_skips)
write_lines<-function(x,p)writeLines(vapply(x,tm_json,''),p,useBytes=TRUE)
write_lines(unname(working),file.path(out,'runs/completed.jsonl'))
write_lines(remaining_skips,file.path(out,'runs/skipped.jsonl'))
write_lines(c(tm_read(file.path(rc_original,'runs/http_responses.jsonl')),tm_read(file.path(rc_root,'runs/http_responses.jsonl'))),
 file.path(out,'runs/http_responses.jsonl'))
tm_write(list(status='secondary_recovery_overlay',original_records=length(original),
 selected_recovery_records=length(recovered),derived_records=length(working),remaining_dependency_skips=length(remaining_skips),
 original_run_modified=FALSE,selection='First end_turn per recovery target, otherwise final allowed technical attempt; never select by answer correctness.',
 primary='Two_Model_Collection/facts/reports/paired_effects.csv',
 secondary='Two_Model_Collection/facts/recovery/derived/reports/paired_effects.csv'),file.path(out,'provenance.json'))
prev<-Sys.getenv('FACTS_ANALYSIS_ROOT',unset=NA_character_);Sys.setenv(FACTS_ANALYSIS_ROOT=out)
analysis_environment<-new.env(parent=globalenv())
sys.source(file.path(rc_original,'R/analyse.R'),envir=analysis_environment)
if(is.na(prev))Sys.unsetenv('FACTS_ANALYSIS_ROOT')else Sys.setenv(FACTS_ANALYSIS_ROOT=prev)
comparison<-rbind(transform(read.csv(file.path(rc_original,'reports/paired_effects.csv')),analysis='original_frozen'),
 transform(read.csv(file.path(out,'reports/paired_effects.csv')),analysis='recovery_overlay_secondary'))
write.csv(comparison,file.path(rc_root,'reports/original_vs_recovery_effects.csv'),row.names=FALSE)
cat('Wrote',length(working),'derived records and',length(remaining_skips),'remaining skips; original unchanged.\n')
