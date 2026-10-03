# Execute the preserved review collector, retaining rejected-request cost reservations.
# Corrected temperature is in the separately amended requests.jsonl.
source('Followup_Validation/R/common.R')
am<-read_json(file.path(VROOT,'protocol/review_temperature_amendment.json'))
src<-file.path(VROOT,'R/review_math.R');stopifnot(file_sha(src)==am$original_implementation_sha256)
code<-paste(readLines(src,warn=FALSE),collapse='\n')
needle<-'used<-sum(vapply(old,function(r)r$cost_guard_cny,0))'
stopifnot(length(gregexpr(needle,code,fixed=TRUE)[[1]])==1)
code<-sub(needle,paste0(needle,'+',format(am$setup_guard_cny,scientific=FALSE,digits=15)),code,fixed=TRUE)
eval(parse(text=code),envir=.GlobalEnv)
