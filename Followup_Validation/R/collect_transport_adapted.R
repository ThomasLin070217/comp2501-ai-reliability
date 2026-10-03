# Transport-only amendment. The frozen original collector remains byte-identical.
source('Followup_Validation/R/common.R')
args<-commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==2,args[1]=='branches',args[2]%in%MODELS)
original<-'Followup_Validation/R/collect.R'
freeze<-read_json('Followup_Validation/protocol/freeze.json')
stopifnot(file_sha(original)==freeze$files_sha256[[original]])
lines<-readLines(original,warn=FALSE)
if(args[2]=='minimax'){
 stopifnot(sum(grepl('batch<-head(jobs,4)',lines,fixed=TRUE))==1,sum(grepl('new_pool(total_con=4,host_con=4)',lines,fixed=TRUE))==1)
 lines<-gsub('batch<-head(jobs,4)','batch<-head(jobs,2)',lines,fixed=TRUE)
 lines<-gsub('new_pool(total_con=4,host_con=4)','new_pool(total_con=2,host_con=2)',lines,fixed=TRUE)
}
eval(parse(text=lines),envir=.GlobalEnv)
