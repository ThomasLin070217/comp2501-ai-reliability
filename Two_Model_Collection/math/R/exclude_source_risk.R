# Apply the frozen estimator to separately labelled, whole-question exclusions.
source('Two_Model_Collection/R/runtime.R')
root<-Sys.getenv('MATH_STUDY_ROOT','Two_Model_Collection/math')
scope<-if(root=='Two_Model_Collection/math')'original'else'combined'
flag<-read.csv(paste0('Two_Model_Collection/math/reports/benchmark_risk_questions_',scope,'.csv'),stringsAsFactors=FALSE)$question_id
labels_df<-read.csv(file.path(root,'reports/semantic_final_responses.csv'),stringsAsFactors=FALSE)
labels<-setNames(labels_df$final_semantic_grade,labels_df$id)
tasks<-read.csv(file.path(root,'protocol/tasks.csv'),stringsAsFactors=FALSE)
tasks<-tasks[!tasks$question_id%in%flag,]
records<-Filter(function(r)!r$question_id%in%flag,tm_read(file.path(root,'runs/completed.jsonl')))
skips<-Filter(function(r)!r$question_id%in%flag,tm_read(file.path(root,'runs/skipped.jsonl')))
tmp<-tempfile('math-source-exclusion-');dir.create(file.path(tmp,'runs'),recursive=TRUE);dir.create(file.path(tmp,'protocol'))
write.csv(tasks,file.path(tmp,'protocol/tasks.csv'),row.names=FALSE)
writeLines(vapply(records,tm_json,''),file.path(tmp,'runs/completed.jsonl'));writeLines(vapply(skips,tm_json,''),file.path(tmp,'runs/skipped.jsonl'))
code<-readLines('Two_Model_Collection/math/R/analyse.R');line<-grep('sc<-math_score',code,fixed=TRUE);stopifnot(length(line)==1L)
code[line]<-paste0(code[line],';g<-unname(labels[t$id]);stopifnot(!is.na(g))')
Sys.setenv(MATH_ANALYSIS_ROOT=tmp);eval(parse(text=code),envir=new.env(parent=environment()));Sys.unsetenv('MATH_ANALYSIS_ROOT')
dest<-file.path(root,'reports/source_exclusion_sensitivity');dir.create(dest,recursive=TRUE,showWarnings=FALSE)
file.copy(list.files(file.path(tmp,'reports'),full.names=TRUE),dest,overwrite=TRUE);unlink(tmp,recursive=TRUE)
tm_write(list(scope=scope,excluded_questions=flag,remaining_questions=length(unique(tasks$question_id)),remaining_planned_positions=nrow(tasks),
 caution='Whole-question conservative risk exclusion, not confirmation of copied benchmark answers. Uses documented semantic labels; original scores and full-sample results retained.'),file.path(dest,'PROVENANCE.json'))
writeLines(c('# Whole-question source-risk exclusion sensitivity','',paste('Dataset:',scope),
 paste('Excluded question IDs:',paste(flag,collapse=', ')),
 paste('Remaining questions:',length(unique(tasks$question_id)),'; remaining planned task positions:',nrow(tasks)),
 'All question/model/repetition/condition rows of a flagged question are excluded together. See paired_effects.csv for paired, equal-model estimates. Risk flags do not prove copying; this is a post-collection sensitivity analysis.'),file.path(dest,'RESULTS.md'))
cat('Whole-question source-risk exclusion analysis complete.\n')
