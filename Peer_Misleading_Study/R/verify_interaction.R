#!/usr/bin/env Rscript
# Compare a second full offline run with committed supplemental outputs.
source('Peer_Misleading_Study/R/core.R')
args<-commandArgs(trailingOnly=TRUE)
assert(length(args)==1,'Usage: Rscript .../verify_interaction.R SECOND_OUTPUT_DIR (containing report.md)')
first<-'Peer_Misleading_Study/reports/interaction_posthoc';second<-args[1]
files<-c('paired_outcomes.csv','transitions.csv','effects.csv','condition_tables.csv',
 'ai_review_queue.csv',sprintf('review_packet_%02d.md',1:12),'audit.json',
 'ai_case_review.csv','withdrawal_review_counts.csv','target_flows_by_baseline.csv','review_audit.json')
checks<-lapply(files,function(f){x<-file_sha(file.path(first,f));y<-file_sha(file.path(second,f));
 assert(identical(x,y),paste('Reproduction mismatch',f));list(file=f,sha256=x,equal=TRUE)})
x<-file_sha('Submission_Pack/补充分析_2026-10-03.md');y<-file_sha(file.path(second,'report.md'))
assert(identical(x,y),'Report reproduction mismatch')
write_json(list(method='Two complete independent R executions; byte-for-byte SHA-256 comparison',
 generated_data_and_review_artifacts=length(files),report_identical=TRUE,report_sha256=x,checks=checks,
 note='Saved AI annotations are inputs, not independently regenerated judgments. Runtime sessionInfo excluded.'),
 file.path(first,'reproducibility.json'))
cat(length(files),'data/review artifacts plus report identical.\n')
