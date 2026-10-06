#!/usr/bin/env Rscript
file_arg <- grep('^--file=',commandArgs(),value=TRUE)
if(length(file_arg)==1L) {
  entry <- gsub('~+~',' ',sub('^--file=','',file_arg),fixed=TRUE)
  setwd(normalizePath(file.path(dirname(entry),'../..')))
}
source('Math_Crosscheck_500/R/selfcheck_runtime.R')
source('Math_Crosscheck_500/R/common.R')
args <- commandArgs(trailingOnly=TRUE)
opts <- list(mode='check',index='Math_Crosscheck_500/inputs/baseline_index.csv',
  prepared='Math_Crosscheck_500/prepared/with_controlled',
  config='Math_Crosscheck_500/inputs/selfcheck_transport.json',
  freeze='Math_Crosscheck_500/prepared/execution',out='Math_Crosscheck_500/runs/followups',
  scope='self',task='')
if(length(args)%%2L) stop('Use --option value pairs. See SELF_CHECK_WORKFLOW.md.')
if(length(args)) for(i in seq(1,length(args),by=2L)) {
  k <- sub('^--','',args[i]); if(!k %in% names(opts)) stop('Unknown option: ',args[i])
  opts[[k]] <- args[i+1L]
}
if(!opts$mode %in% c('check','freeze','run','export') || !opts$scope %in% c('self','joint')) stop('Invalid mode/scope.')
if(opts$mode %in% c('check','freeze')) {
  gate <- mc_check(opts$index,'Math_Crosscheck_500/question_review_v2/model_inputs_500.csv')
  if(!isTRUE(gate$ready)) {cat(sc_json(gate),'\nNo model requests.\n'); quit(status=0)}
  if(opts$mode=='check') {cat(sc_json(gate),'\nNo model requests.\n'); quit(status=0)}
  plan <- sc_freeze(opts$index,opts$prepared,opts$config,opts$freeze)
  cat('Frozen',length(plan$jobs),'joint tasks; no model requests.\n'); quit(status=0)
}
plan <- sc_read(file.path(opts$freeze,'run_manifest.json')); sc_verify(plan)
if(opts$mode=='export') {sc_export(plan,opts$out); quit(status=0)}
dir.create(opts$out,recursive=TRUE,showWarnings=FALSE)
tryCatch({
  for(i in seq_along(plan$jobs)) {
    j <- plan$jobs[[i]]; id <- j$task$task_id
    fp <- file.path(opts$out,sprintf('task_%04d/final.json',i))
    if(file.exists(fp)) {sc_final(fp,j); next}
    if(nzchar(opts$task) && id!=opts$task) next
    if(opts$scope=='self' && j$task$condition!='self_check') {
      cat('Waiting for joint schedule:',id,'\n'); break
    }
    f <- if(j$task$condition=='self_check') run_self_check(plan,id,opts$out) else sc_run_one(plan,id,opts$out)
    cat(id,':',f$status,'\n')
    if(nzchar(opts$task)) break
  }
  if(nzchar(opts$task) && !opts$task %in% vapply(plan$jobs,function(j) j$task$task_id,'')) stop('Unknown selected task ID.')
},finally=sc_export(plan,opts$out))
