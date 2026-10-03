# Codex read both complete DeepSeek format packets before writing these labels.
source('Followup_Validation/R/common.R');p<-file.path(VROOT,'review','staged_format');z<-read.csv(file.path(p,'deepseek_responses.csv'));stopifnot(nrow(z)==20)
rules<-list(
 'SV1808'=c('correct','2021 January is an unambiguous January 2021 answer; the parser does not recognize this word order.'),
 'CHAMP:P_Polynomial_50'=c('correct','The final a = -5 is the correct value; the numeric-only parser does not accept the variable prefix.'),
 'CHAMP:P_Sequence_21'=c('correct','The final 2500 is correct; literal unescaped newlines inside the JSON reason prevent parsing.'),
 'SV3258'=c('incorrect','The supplied December 1999 is incompatible with the reference 10 July 2010; missing day precision does not make the wrong year correct.'),
 'SV3265'=c('incorrect','The supplied September or October 1994 differs from the April 1994 reference, even though the output omits the requested day.'),
 'SV2035'=c('incorrect','The supplied year 1974 conflicts with the reference December 1972; acknowledging the missing month does not retract that year.')
)
stopifnot(all(z$question_id%in%names(rules)))
a<-data.frame(task_id=z$task_id,semantic_grade=vapply(z$question_id,function(id)rules[[id]][1],''),evidence=vapply(z$question_id,function(id)rules[[id]][2],''),reviewer='Codex AI; targeted post-hoc final-answer meaning review')
write.csv(a,file.path(p,'deepseek_annotations.csv'),row.names=FALSE);print(table(a$semantic_grade))
