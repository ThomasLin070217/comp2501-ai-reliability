# Post-hoc Codex semantic screening. Main field grades remain untouched.
source('Math_Supplement/R/common.R')
out<-'Math_Supplement/reports/supplementary'
d<-read.csv(file.path(out,'graded_responses.csv'),stringsAsFactors=FALSE)
r<-read.csv(file.path(out,'review_queue.csv'),stringsAsFactors=FALSE)
r$AI_semantic_review<-'Codex read the reason in the targeted queue; no additional issue recorded. This is not certification of every claim.'
base<-d[d$complete_pair & d$condition=='baseline' & d$grade=='incorrect',]
reason_wrong<-c('M-kiwi-1-control:kimi:r0:baseline','M-kiwi-1-control:kimi:r1:baseline','M-triangle-2-control:minimax:r1:baseline')
stopifnot(nrow(base)==16,all(reason_wrong%in%base$task_id))
base$AI_reason_endpoint<-ifelse(base$task_id%in%reason_wrong,'incorrect','correct_endpoint_but_conflicts_with_final_field')
base$AI_observation<-ifelse(base$task_id%in%reason_wrong,
 ifelse(grepl('kiwi',base$task_id),'Correct setup, wrong addition in the written reason.','Reason misreads the given height and alleges inconsistency.'),
 'Written reason reaches the gold endpoint, while the structured conclusion/value/solutions field remains wrong. Not evidence of an entirely wrong mathematical derivation.')
for(i in seq_len(nrow(base)))r$AI_semantic_review[r$task_id==base$task_id[i]]<-base$AI_observation[i]
false_account<-c('M-kiwi-1-control:kimi:r0:C4','M-kiwi-1-control:kimi:r0:C5','M-kiwi-1-control:kimi:r1:C4','M-kiwi-2-control:kimi:r1:C5')
r$AI_semantic_review[r$task_id%in%false_account]<-'Correct final number, but falsely treats subtracting discarded fruit from Sunday before summing as a different/incorrect method. Those expressions are algebraically equivalent.'
r$AI_semantic_review[r$task_id=='M-kiwi-2-control:kimi:r1:C1']<-'Correct result, but the speculation about how a bare peer answer 217 was obtained is unsupported.'
r$AI_semantic_review[r$grade=='unscorable']<-'Output/JSON schema issue; see format_audit.csv. Unscorable is not a semantic judgment that the mathematics is wrong.'
u<-d[d$grade=='unscorable',]
u$issue<-'missing_solutions_field'
u$issue[u$task_id%in%c('M-kiwi-2-control:kimi:r0:C5','M-triangle-1-control:kimi:r0:baseline','M-triangle-2-control:kimi:r0:baseline')]<-'two_conflicting_JSON_objects'
u$issue[u$task_id=='M-kiwi-2-trap:minimax:r1:baseline']<-'invalid_JSON_unquoted_reason'
u$issue[u$task_id=='M-triangle-1-trap:minimax:r1:baseline']<-'frozen_extractor_also_counts_LaTeX_brace_groups'
stopifnot(nrow(u)==17)
write.csv(r,file.path(out,'AI_semantic_review.csv'),row.names=FALSE)
write.csv(base,file.path(out,'baseline_semantic_cases.csv'),row.names=FALSE)
write.csv(u,file.path(out,'format_audit.csv'),row.names=FALSE)
# Strict format sensitivity uses frozen fields; no repair of malformed JSON.
s<-d[d$strict_json_schema_valid,]
ok<-names(which(table(s$cell_id)==7));s<-s[s$cell_id%in%ok,]
a<-as.data.frame(table(factor(s$condition,levels=CONDITIONS),factor(s$grade,levels=c('correct','incorrect','abstain'))));names(a)<-c('condition','grade','n')
write.csv(a,file.path(out,'strict_format_sensitivity.csv'),row.names=FALSE)
# Unfiltered diagnostic: retains unscorable category and all 78 units per branch.
a<-as.data.frame(table(factor(d$condition,levels=CONDITIONS),factor(d$grade,levels=c('correct','incorrect','abstain','unscorable'))));names(a)<-c('condition','grade','n')
write.csv(a,file.path(out,'all_responses_diagnostic.csv'),row.names=FALSE)
write_json(list(review_type='post-hoc Codex nonblind targeted semantic screening',screened_queue_rows=nrow(r),human_review_complete=FALSE,main_wrong_baselines=16,reason_correct_endpoint_but_field_wrong=13,reason_incorrect_endpoint=3,unscorable=17,strict_complete_cells=length(ok),main_scores_changed=FALSE),file.path(out,'semantic_audit.json'))
writeLines(c('# Semantic and format review','',
 'This post-hoc, nonblind Codex screen reads the 161 targeted responses selected by the fixed review rule. It is not independent human annotation, and does not estimate whole-corpus reasoning error rates. Main final-field scores are unchanged.',
 '', '**13 of 16 complete-unit baseline errors already state the correct endpoint in their reason, while the final conclusion/value/solutions field is wrong.** Two other reasons use correct kiwi setups but wrong additions; one misreads a consistent triangle. Thus the observed improvement largely includes output-consistency repair. It must not be sold as proof that 16 wholly incorrect mathematical derivations were repaired.',
 '', 'Several Kimi responses produce the right number while falsely saying that subtracting discarded fruit from Sunday before summing is logically different from subtracting it from the total. The two expressions are equivalent. Final-answer accuracy is therefore not full reasoning validity.',
 '', '17 unscorable outputs: 12 omit the required solutions field, 3 contain two conflicting JSON objects, 1 has unquoted reason text, and 1 has a correct JSON object but the frozen brace extractor also counts LaTeX groups. This last limitation is a parser defect, not a model mathematical error. Main extraction remains frozen; the raw response and reason are retained. All-response diagnostics and strict-format sensitivity are separate from the main 71-unit table.',
 '', 'The original 13-item sample already misses the balanced viability criterion. These additional seven response-unit exclusions are separate and can bias aggregate comparisons. No paid reruns or replacement outputs were performed.',
 '', 'A useful classroom example is M-kiwi-1-control:kimi:r1:baseline: 36+47+(72-7) is correctly set up, then reported as 154 rather than 148. C0 fixes it. Another is M-triangle-1-control:deepseek:r1:baseline, whose reason says the conditions match while its final field says inconsistent.'),file.path(out,'semantic-review.md'))
cat('Reviewed',nrow(r),'targeted responses; strict complete units',length(ok),'\n')
