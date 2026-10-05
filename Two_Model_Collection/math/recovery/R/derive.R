source('Two_Model_Collection/math/recovery/R/common.R')
status<-fromJSON(file.path(REC,'runs/status.json'),simplifyVector=FALSE)
stopifnot(identical(status$status,'finished'),status$remaining==0L,!dir.exists(file.path(REC,'runs/collector.lock')))
original<-tm_read(file.path(MAIN,'runs/completed.jsonl'));rec<-tm_read(file.path(REC,'runs/completed.jsonl'))
done<-setNames(original,tm_fields(original,'id'))
# Recovery records are append-only attempt history. The last attempt is the
# selected recovered observation; no best-answer or first-correct selection.
for(r in rec)done[[r$id]]<-r
tasks<-read.csv(file.path(MAIN,'protocol/tasks.csv'),stringsAsFactors=FALSE,na.strings=NULL)
dest<-file.path(REC,'derived');dir.create(file.path(dest,'runs'),recursive=TRUE,showWarnings=FALSE);dir.create(file.path(dest,'protocol'),recursive=TRUE,showWarnings=FALSE)
file.copy(file.path(MAIN,'protocol/tasks.csv'),file.path(dest,'protocol/tasks.csv'),overwrite=TRUE)
writeLines(vapply(unname(done),tm_json,''),file.path(dest,'runs/completed.jsonl'))
missing<-tasks[!tasks$id%in%names(done),]
skip<-lapply(seq_len(nrow(missing)),function(i)c(as.list(missing[i,]),list(reason='dependency_unavailable_after_predeclared_technical_recovery')))
writeLines(vapply(skip,tm_json,''),file.path(dest,'runs/skipped.jsonl'))
provenance<-do.call(rbind,lapply(names(done),function(id){r<-done[[id]];data.frame(id=id,source=if(is.null(r$source))'original'else r$source,
 selected_recovery_attempt=r$recovery_attempt%or%NA_integer_,recovery_mode=r$recovery_mode%or%'none',http_id=r$http_id,status=r$status,request_sha256=r$request_sha256,stringsAsFactors=FALSE)}))
write.csv(provenance,file.path(dest,'provenance.csv'),row.names=FALSE)
stopifnot(!anyDuplicated(tm_fields(unname(done),'id')),length(done)+nrow(missing)==732L)
tm_write(list(derived_at=tm_now(),original_records=length(original),recovery_http_records=length(rec),
 selected_records=length(done),remaining_unavailable_dependencies=nrow(missing),
 selection='Last allowed recovery attempt per task; preserve original if no recovery record. No selection by correctness.',
 limitation='Supplemented analysis includes repeated generation after technical failure and a declared 6144-token subset. It is separate from the original frozen-parameter main analysis.'),file.path(dest,'PROVENANCE.json'))
Sys.setenv(MATH_ANALYSIS_ROOT=dest);source(file.path(MAIN,'R/analyse.R'),local=new.env(parent=globalenv()));Sys.unsetenv('MATH_ANALYSIS_ROOT')
Sys.setenv(MATH_STUDY_ROOT=dest);source(file.path(MAIN,'R/sensitivity.R'),local=new.env(parent=globalenv()));Sys.unsetenv('MATH_STUDY_ROOT')
cat('Supplemented derived records and strict/JSON-recovery analyses saved to',dest,'\n')
