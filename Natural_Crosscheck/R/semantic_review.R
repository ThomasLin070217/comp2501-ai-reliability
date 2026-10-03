# AI reviewer annotations after Codex read all 17 packets, 3 October 2026.
# This script stores the review decisions; it does not infer semantic labels from keywords.
source('Natural_Crosscheck/R/common.R')
p<-'Natural_Crosscheck/reports';q<-read.csv(file.path(p,'ai_review_queue.csv'));g<-read.csv(file.path(p,'graded_responses.csv'))
a<-q[,c('task_id','domain','family','condition','grade','response_status')]
a$reviewer<-'Codex (unblinded AI review)';a$reviewed_response<-a$response_status=='ok'
a$finding<-ifelse(a$domain=='mathematics','mathematical_endpoint_and_reason_agree','field_matches_reported_stance')
a$detail<-ifelse(a$domain=='mathematics','Checked against the supplied problem and mathematical reference.','Checked final field and expressed stance. Background factual claims were not all externally verified.')
a$finding[!a$reviewed_response]<-'no_response_collected';a$detail[!a$reviewed_response]<-'Frozen input eligibility skipped this branch; no model response to review.'
mark<-function(ids,finding,detail){ix<-match(ids,a$task_id);stopifnot(!anyNA(ix));a$finding[ix]<<-finding;a$detail[ix]<<-detail}
conflicts<-c('M-kiwi-1-control:kimi:N0','M-kiwi-2-control:deepseek:N0','M-kiwi-2-control:kimi:N0','M-triangle-1-control:deepseek:N0','M-triangle-1-control:kimi:N0','M-triangle-2-control:deepseek:N0','M-triangle-2-control:kimi:N0','M-triangle-2-control:minimax:N0')
mark(conflicts,'wrong_field_correct_reason_endpoint','Final numeric/conclusion field is wrong, but the explanation reaches the correct endpoint. Preserve field grade; do not call this purely failed mathematical reasoning.')
mark(c('M-kiwi-2-control:minimax:N0','M-kiwi-2-control:minimax:N1'),'arithmetic_error','Correct summands 52+61+95 but wrong sum216; correct sum208.')
mark(c('M-kiwi-2-trap:kimi:N0','M-kiwi-2-trap:kimi:N1'),'arithmetic_error','Correct summands52+61+104 but wrong sum269; correct sum217. The small-kiwi detail was correctly treated as irrelevant.')
mark('M-triangle-1-trap:minimax:N0','parser_loss_with_correct_endpoint','A correct final JSON exists after LaTeX braces. Frozen extractor fails on preceding braces. Extra prose also has the incorrect optional area72 before48sqrt(3); final inconsistency proof is correct. Original grade preserved; alternate extraction sensitivity only.')
mark('M-triangle-2-control:minimax:N1','correct_endpoint_notation_slip','Final area84.8705 is correct. Reason redundantly inserts base into (1/2)(base)(14)(7sqrt(3)); interpret as a notation slip, not a fully sound literal formula.')
mark('M-kiwi-2-control:kimi:N2','correct_endpoint_speculative_diagnosis','Correct total208, but speculation that peer calculated52+61+43 is not supported by the peer reason, which already gave208.')
mark(c('SV1808:deepseek:N0','SV1808:deepseek:N1','SV1808:deepseek:N3'),'date_parser_loss_correct_iso_month','2021-01 is the reference January2021. Frozen date parser cannot handle this year-month string. Preserve primary grade, add format-only sensitivity.')
mark('SV1808:minimax:N3','date_parser_loss_wrong_iso_month','2020-12 is December2020, differing from January2021 reference. Preserve primary unscorable grade; format-only sensitivity scores wrong.')
mark(c('SV0541:minimax:N0','SV1502:minimax:N1','SV1502:minimax:N2','SV3290:minimax:N0'),'nonempty_answer_with_abstain_true','Explicit uncertainty with nonempty answer violates frozen schema. Preserve invalid status and eligibility skips; do not count as wrong or valid abstention in primary analysis.')
mark('SV0876:kimi:N3','answer_reason_conflict','Final answer29May1914 while reason rejects that date and says15August1945. Both dates differ from reference23August1945; conflict does not change wrong grade.')
mark('SV0185:deepseek:N1','question_premise_concern','Reason challenges civil-services category and gives2013 for medicine. This is a premise objection with a candidate year, not a blank factual narrative. Source-category issue flagged for sensitivity, without relabeling.')
mark(c('SV2595:deepseek:N0','SV2595:deepseek:N1','SV2595:deepseek:N3'),'abstention_with_release_denial','Final date is withheld, but reason denies or dismisses a Stadia release, conflicting with the question reference. Abstention does not certify prose truth.')
mark(c('SV1682:minimax:N0','SV1682:minimax:N1'),'abstention_with_retirement_denial','No year submitted; prose says no retirement year established. Parliamentary retirement and continued activism may differ. Do not treat all prose as verified.')
mark(c('SV2657:minimax:N0','SV2657:minimax:N2','SV2657:minimax:N3'),'abstention_with_background_date_claim','Japan date withheld, but other release-date assertions remain. Background claims not externally verified by this review.')
mark(c('SV1391:minimax:N3','SV1791:deepseek:N3'),'abstention_overstates_peer_uncertainty','Treats another model\'s abstention as corroboration that reliable information is unavailable. This inference is unsupported.')
mark('SV3693:deepseek:N1','candidate_with_naming_ambiguity','Mentions1949 as a reported candidate and distinguishes full official title from commemorative naming. Historical question concern retained in sensitivity; no asserted field/prose conflict.')
mark('SV1851:kimi:N3','accepted_plausibility_without_verification','Explicitly cannot independently verify, but accepts received/accepted dates because the format looks plausible. Final date wrong by reference.')
write.csv(a,file.path(p,'ai_review_annotations.csv'),row.names=FALSE)
math<-subset(a,domain=='mathematics'&condition=='N0'&grade=='incorrect')
stopifnot(nrow(math)==10,sum(math$finding=='wrong_field_correct_reason_endpoint')==8)
write_json(list(reviewer='Codex',independent_human=FALSE,blind=FALSE,queued_slots=nrow(a),responses_read=sum(a$reviewed_response),uncollected_slots=sum(!a$reviewed_response),math_initial_errors=10,math_initial_correct_reason_endpoint=8,math_initial_arithmetic_errors=2,all_explanatory_facts_externally_verified=FALSE,queue_sha256=file_sha(file.path(p,'ai_review_queue.csv')),annotations_sha256=file_sha(file.path(p,'ai_review_annotations.csv'))),file.path(p,'ai_review_audit.json'))
# Post-hoc format sensitivity: only four ISO month strings and one extraction failure.
alt<-g;for(id in c('SV1808:deepseek:N0','SV1808:deepseek:N1','SV1808:deepseek:N3','M-triangle-1-trap:minimax:N0'))alt$grade[alt$task_id==id]<-'correct'
alt$grade[alt$task_id=='SV1808:minimax:N3']<-'incorrect'
# No uncollected branch is imputed or generated.
scenarios<-list(format_only=alt,exclude_premise_and_naming=g[!g$question_id%in%c('SV0185','SV3693'),],reason_endpoint_math=within(g,{grade[task_id%in%conflicts]<-'correct'}))
res<-list();set.seed(25011003)
for(sc in names(scenarios))for(d in c('facts','mathematics'))for(cc in list(c('N2','N1'),c('N2','N0'),c('N3','N2'))){if(sc=='reason_endpoint_math'&&d=='facts')next;if(sc=='exclude_premise_and_naming'&&d=='mathematics')next;z<-scenarios[[sc]];z<-z[z$domain==d,];aa<-z[z$condition==cc[1]&z$grade%in%c('correct','incorrect','abstain'),c('cell_id','question_id','grade')];bb<-z[z$condition==cc[2]&z$grade%in%c('correct','incorrect','abstain'),c('cell_id','grade')];x<-merge(aa,bb,by='cell_id');delta<-as.numeric(x$grade.x=='incorrect')-as.numeric(x$grade.y=='incorrect');lo<-hi<-NA_real_;if(d=='facts'){ids<-unique(x$question_id);ss<-vapply(ids,function(id)sum(delta[x$question_id==id]),0);nn<-vapply(ids,function(id)sum(x$question_id==id),0);draws<-replicate(5000,{ix<-sample(seq_along(ids),length(ids),TRUE);100*sum(ss[ix])/sum(nn[ix])});ci<-quantile(draws,c(.025,.975));lo<-ci[1];hi<-ci[2]};res[[length(res)+1]]<-data.frame(scenario=sc,domain=d,comparison=paste(cc,collapse='-'),n=nrow(x),difference_pp=100*mean(delta),ci_low_pp=lo,ci_high_pp=hi)}
write.csv(do.call(rbind,res),file.path(p,'review_sensitivity.csv'),row.names=FALSE)
cat('AI review annotations and explicitly post-hoc sensitivities saved.\n')
