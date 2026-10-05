# Conservative parameter sensitivity: exclude every question exposed to any
# 6144-token recovery request, even if that attempt was not selected.
source('Two_Model_Collection/R/runtime.R')
root<-'Two_Model_Collection/math/recovery/derived'
http<-tm_read('Two_Model_Collection/math/recovery/runs/http_responses.jsonl')
tasks0<-read.csv(file.path(root,'protocol/tasks.csv'),stringsAsFactors=FALSE)
changed<-Filter(function(r)r$request$max_tokens==6144L,http)
ids<-sub(':recovery[12]$','',tm_fields(changed,'task_id'))
flag<-sort(unique(tasks0$question_id[match(ids,tasks0$id)]));stopifnot(!anyNA(flag))
labels_df<-read.csv(file.path(root,'reports/semantic_final_responses.csv'),stringsAsFactors=FALSE)
labels<-setNames(labels_df$final_semantic_grade,labels_df$id)
tasks<-tasks0[!tasks0$question_id%in%flag,]
records<-Filter(function(r)!r$question_id%in%flag,tm_read(file.path(root,'runs/completed.jsonl')))
skips<-Filter(function(r)!r$question_id%in%flag,tm_read(file.path(root,'runs/skipped.jsonl')))
tmp<-tempfile('math-same-token-limit-');dir.create(file.path(tmp,'runs'),recursive=TRUE);dir.create(file.path(tmp,'protocol'))
write.csv(tasks,file.path(tmp,'protocol/tasks.csv'),row.names=FALSE)
writeLines(vapply(records,tm_json,''),file.path(tmp,'runs/completed.jsonl'));writeLines(vapply(skips,tm_json,''),file.path(tmp,'runs/skipped.jsonl'))
code<-readLines('Two_Model_Collection/math/R/analyse.R');line<-grep('sc<-math_score',code,fixed=TRUE);stopifnot(length(line)==1L)
code[line]<-paste0(code[line],';g<-unname(labels[t$id]);stopifnot(!is.na(g))')
Sys.setenv(MATH_ANALYSIS_ROOT=tmp);eval(parse(text=code),envir=new.env(parent=environment()));Sys.unsetenv('MATH_ANALYSIS_ROOT')
dest<-file.path(root,'reports/same_limit_sensitivity');dir.create(dest,recursive=TRUE,showWarnings=FALSE)
file.copy(list.files(file.path(tmp,'reports'),full.names=TRUE),dest,overwrite=TRUE);unlink(tmp,recursive=TRUE)
write.csv(data.frame(question_id=flag),file.path(dest,'excluded_questions.csv'),row.names=FALSE)
tm_write(list(scope='supplemented_semantic_same_output_limit',excluded_questions=flag,remaining_questions=length(unique(tasks$question_id)),remaining_planned_positions=nrow(tasks),
 rule='Exclude the entire question if ANY recovery HTTP request for it used max_tokens=6144, including unselected/failed attempts. This removes related baseline/donor exposure and all models/repetitions/conditions together. Remaining requests retain max_tokens=1536.',
 caution='Post-collection sensitivity on a smaller set; still includes technical retries at unchanged output limit and post-collection semantic labels. It does not replace the original frozen-parameter dataset or establish generalization.'),file.path(dest,'PROVENANCE.json'))
writeLines(c('# Same output-limit sensitivity','',paste('Excluded questions:',length(flag)),paste('Remaining questions:',length(unique(tasks$question_id))),
 'All selected and unselected 6144-token requests trigger whole-question exclusion, including downstream baseline/donor exposure. The frozen matched equal-model estimator and 97.5% primary question-cluster bootstrap are retained. Source-risk exclusion is a separate analysis.'),file.path(dest,'RESULTS.md'))
cat('Same-output-limit sensitivity complete.\n')
