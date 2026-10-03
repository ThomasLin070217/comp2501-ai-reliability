# Codex read all four complete MiniMax format packets before these annotations.
source('Followup_Validation/R/common.R');p<-file.path(VROOT,'review','staged_format');z<-read.csv(file.path(p,'minimax_responses.csv'));stopifnot(nrow(z)==38)
rules<-list(
 'CHAMP:P_Polynomial_17'=c('incorrect','The final n or n(n-1) is false: continuity forces f(x)-x to keep one sign and excludes all real two-cycles.'),
 'CHAMP:P_Number-Theory_17'=c('correct','The string 7744 = 88² (with or without parentheses) identifies the requested square.'),
 'CHAMP:P_Polynomial_47'=c('correct','The plain-text final answer 120 is unambiguous and correct despite lacking a JSON object.'),
 'CHAMP:P_Number-Theory_12'=c('incorrect','The output includes 75 as an extra automorphic number, but 75²=5625 does not end in 75.'),
 'CHAMP:P_Sequence_19'=c('incorrect','The final value 1 follows a false period-12 claim; the period is 7 and the requested value is -1.'),
 'CHAMP:P_Combinatorics_20'=c('incorrect','The explicit final value 7 is wrong (reference 87); the JSON also omits abstain.'),
 'CHAMP:P_Polynomial_50'=c('correct','The final a = -5 is correct but has a variable prefix excluded by the numeric-only grammar.'),
 'CHAMP:P_Polynomial_11'=c('uncertain','No explicit final answer is present: one response says only Both solutions agree, and the other ends mid-expression despite a nominally successful API finish.'),
 'SV1268'=c('incorrect','The explicit date in the answer sentence is October 2021, inconsistent with October 2023.'),
 'SV0541'=c('incorrect','The asserted year 1969 (or September 1969) differs from the reference 17 November 1967.'),
 'SV4021'=c('incorrect','The asserted 1988 nomination is inconsistent with 24 May 1984, regardless of omitted day precision.'),
 'SV1016'=c('incorrect','The malformed but readable intended answer is 2003 with abstain=false; it also mentions 1997. Neither is the reference 1976. A confidence hedge does not retract the supplied answer.'),
 'SV1808'=c('correct','2021 January means January 2021; the parser does not accept this word order.'),
 'SV4215'=c('incorrect','29 February 1990 is not a valid date and differs from the reference 29 May 1990.'),
 'SV3685'=c('incorrect','The answer lists 2002 and 2008, neither of which is the reference 2013.'),
 'SV2232'=c('abstain','The malformed encoding clearly conveys withholding a date: the earlier date was an unsupported guess and the response says it should abstain.')
)
mixed<-c('SV2035','SV0914','SV4222','SV0874','SV2137','SV2796','SV2300','SV2178')
label<-function(i){id<-z$question_id[i];tid<-z$task_id[i]
 if(id%in%mixed)return(c('uncertain','A nonempty date/decade is supplied together with abstain=true and an uncertainty statement. Retain the ambiguous mixed output as unscorable regardless of whether its candidate date matches the key.'))
 if(id=='SV0700'){if(z$condition[i]=='W2')return(c('abstain','Null answer plus abstain=true explicitly withholds the year; null rather than empty string is a format mismatch.'));return(c('incorrect','The asserted 1960s is incompatible with the reference 1866.'))}
 if(id=='SV2657'){if(z$condition[i]=='W1')return(c('uncertain','The answer provides the year 2011 but abstains from the requested full date; retain the nonempty-answer/abstention mixture as unresolved, consistently with other mixed outputs.'));return(c('incorrect','Although the answer field gives only 2011, the response explicitly assigns Japan the date June 28, 2011, inconsistent with September 14.'))}
 stopifnot(id%in%names(rules));rules[[id]]
}
labs<-lapply(seq_len(nrow(z)),label)
a<-data.frame(task_id=z$task_id,semantic_grade=vapply(labs,`[`,'',1),evidence=vapply(labs,`[`,'',2),reviewer='Codex AI; targeted post-hoc target-answer meaning review')
write.csv(a,file.path(p,'minimax_annotations.csv'),row.names=FALSE);print(table(a$semantic_grade))
# Assemble the complete sensitivity input, preserving each reviewed provider file.
all<-do.call(rbind,lapply(MODELS,function(m)read.csv(file.path(p,paste0(m,'_annotations.csv')))))
stopifnot(!anyDuplicated(all$task_id));write.csv(all,file.path(VROOT,'review','codex_format_annotations.csv'),row.names=FALSE)
