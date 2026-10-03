# Offline verification; never prepares requests, collects responses or changes frozen rules.
source('Followup_Validation/R/common.R')
p<-file.path(VROOT,'reports')
files<-sort(c(list.files(p,pattern='\\.(csv|md|png)$',full.names=TRUE),
 file.path(VROOT,'review',c('annotations.csv','reasoning_counts.csv','codex_reasoning_annotations.csv','codex_review_notes.md'))))
files<-files[basename(files)!='reproduction_hashes.csv']
before<-vapply(files,file_sha,'')
rawfiles<-sort(list.files(file.path(VROOT,'runs'),pattern='responses.jsonl$',full.names=TRUE,recursive=TRUE))
rawfiles<-c(rawfiles,file.path(VROOT,'review/responses.jsonl'))
rawbefore<-vapply(rawfiles,file_sha,'')
steps<-list(c('analyse.R'),c('diagnostics.R'),c('semantic_sensitivity.R'),c('peer_diagnostics.R'),
 c('review_math.R','analyse'),c('codex_reasoning_audit.R'),c('write_report.R'),c('chinese_digest.R'))
logs<-list()
for(step in steps){
 logfile<-tempfile('comp2501-offline-');args<-c(file.path(VROOT,'R',step[1]),step[-1])
 status<-system2(file.path(R.home('bin'),'Rscript'),args,stdout=logfile,stderr=logfile)
 if(status!=0){cat(readLines(logfile),sep='\n');stop('Offline reproduction failed: ',step[1])}
 logs[[step[1]]]<-list(exit_status=status,arguments=args)
}
after<-vapply(files,file_sha,'');same<-before==after
write.csv(data.frame(file=files,before_sha256=unname(before),after_sha256=unname(after),identical=unname(same)),file.path(p,'reproduction_hashes.csv'),row.names=FALSE)
stopifnot(all(same),identical(rawbefore,vapply(rawfiles,file_sha,'')))
freeze<-read_json(file.path(VROOT,'protocol/freeze.json'))
stopifnot(all(vapply(names(freeze$files_sha256),function(f)file_sha(f)==freeze$files_sha256[[f]],TRUE)))
write_json(list(time=now(),model_calls=0,deterministic_artifacts_checked=length(files),all_identical=all(same),raw_files_unchanged=length(rawfiles),original_frozen_files_unchanged=TRUE,steps=logs),file.path(p,'reproduction_validation.json'))
cat('Identical:',length(files),'CSV/Markdown/PNG artifacts; all raw and frozen files unchanged.\n')
