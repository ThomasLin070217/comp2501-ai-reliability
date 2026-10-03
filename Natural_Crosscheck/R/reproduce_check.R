source('Natural_Crosscheck/R/common.R')
p<-'Natural_Crosscheck/reports'
files<-list.files(p,pattern='\\.(csv|json|png|md)$',full.names=TRUE)
files<-files[!grepl('reproducibility.json$',files)]
before<-setNames(vapply(files,file_sha,''),files)
source('Natural_Crosscheck/R/analyse.R');source('Natural_Crosscheck/R/validate_analysis.R');source('Natural_Crosscheck/R/semantic_review.R')
after<-setNames(vapply(files,file_sha,''),files)
print(files[before!=after]);stopifnot(identical(before,after))
write_json(list(files_compared=length(files),byte_identical=TRUE,sha256=as.list(after)),file.path(p,'reproducibility.json'))
cat('Reproduced',length(files),'files byte-for-byte.\n')
