# Codex read all six complete Kimi format failures; ambiguous conflicts stay unresolved.
source('Followup_Validation/R/common.R');p<-file.path(VROOT,'review','staged_format');z<-read.csv(file.path(p,'kimi_responses.csv'));stopifnot(nrow(z)==6)
rules<-list(
 'CHAMP:P_Number-Theory_17'=c('correct','The final string 7744 = 88² unambiguously identifies the required square number.'),
 'SV0700'=c('incorrect','The claimed 1960s is incompatible with the reference 1866; it is not merely missing single-year precision.'),
 'SV0541'=c('incorrect','The answer field gives only 1967, but the response explicitly asserts the requested commencement date as 12 October 1967, conflicting with 17 November 1967.'),
 'SV0491'=c('uncertain','Nonempty answer 1983 conflicts with abstain=true and prose explicitly saying the year cannot be determined. Do not force this ambiguous mixed output into either wrong or abstain; retain it as unscorable.')
)
stopifnot(all(z$question_id%in%names(rules)))
a<-data.frame(task_id=z$task_id,semantic_grade=vapply(z$question_id,function(id)rules[[id]][1],''),evidence=vapply(z$question_id,function(id)rules[[id]][2],''),reviewer='Codex AI; targeted post-hoc target-answer meaning review')
write.csv(a,file.path(p,'kimi_annotations.csv'),row.names=FALSE);print(table(a$semantic_grade))
