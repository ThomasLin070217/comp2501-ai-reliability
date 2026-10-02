# All chart values and presentation content are prepared in R. JS/Python only lay out documents.
source('Peer_Misleading_Study/R/core.R')
dir.create('Submission_Pack/evidence',showWarnings=FALSE)
f<-read.csv('Peer_Misleading_Study/reports/main_r/tables.csv');f<-f[f$provider=='pooled',]
mfile<-'Math_Supplement/reports/supplementary/tables.csv'
stopifnot(file.exists(mfile))
m<-read.csv(mfile);m<-m[m$scope=='pooled',];ms<-read_json('Math_Supplement/reports/supplementary/summary.json')
data<-list(factual=unname(lapply(seq_len(nrow(f)),function(i)as.list(f[i,]))),math=unname(lapply(seq_len(nrow(m)),function(i)as.list(m[i,]))),math_summary=ms)
source_url<-'https://github.com/ThomasLin070217/comp2501-ai-reliability'
notes<-c(
 '20 seconds. Introduce the concrete question: if we ask an AI to check another AI, do we gain reliability or merely become more cautious? The tested method is one follow-up prompt, not browsing, an ensemble or retraining.',
 '40 seconds. Explain the two separate research questions. RQ1 compares an incorrect answer alone with the same answer plus explanation. RQ2 compares exactly matched peer material under neutral and structured prompts, and also tests whether true corrections survive.',
 '65 seconds. Each baseline creates six separate conversations. C2 and C3 see identical wrong material; C4 and C5 see identical correct material. The arrows people may imagine are comparisons, not a chain of edits. Another model generated the material for an assigned target. Explain C0 as spontaneous rechecking control.',
 '50 seconds. Distinguish questions, responses and paired units. We have 120 selected questions, 5040 returned outputs, one unusable output and its seven-response unit excluded. Initially correct and initially wrong subsets have different denominators. All current processing is R. Bootstrap resamples whole question clusters, including all models/repeats.',
 '50 seconds. Read counts: five, three, zero out of 154 initially correct units. Adding a wrong explanation did not show increased harm. C2 minus C1 is -1.30 percentage points with interval [-5.17,2.31]. Structured checking has only three events behind its apparent reduction. Zero is not a safety guarantee.',
 '55 seconds. Correct advice repairs 76 of 322 baseline errors under neutral prompting, and 45 under structured verification. Paired difference is -9.63 percentage points with question-cluster interval [-14.38,-5.25]. There are 48 adverse discordant units and 17 reverse units. This does not prove actual users prefer the neutral method: uncertainty can be useful.',
 '50 seconds. The stacked bars all use 719 complete units. Structured prompts shift many outputs into abstention. Date accuracy does not validate the explanation or prove evidence was consulted. Mention the correct 1975 candidate with explicit uncertainty as a case of mixed dimensions.',
 '45 seconds. Ask the audience whether area is 50. Side length 10 forces height about 8.66, so conditions are inconsistent. Correct rejection of a contradictory premise is a mathematical conclusion, not the model refusing from uncertainty. This is MathTrap Table 13, a historical GPT-4-0125-preview failure; no claim every current model fails this exact item.',
 '60 seconds. Read the current math counts from the slide, keeping the supplement separate from factual results. None of 55 initially correct units flipped. C0 alone reaches 68/71. Thirteen of 16 initial field errors already have a correct endpoint in the reason, so do not describe all gains as logical repairs. State 13 of 16 planned items passed peer-material quality; only three families have complete trap/control coverage. Numbers and repeated outputs are dependent. This is descriptive evidence and not a benchmark or universal method ranking.',
 '45 seconds. Explain limitations that affect inference: selected dates, low baseline accuracy, few harmful flips, disputed references and partial human review. The math schema cues logical categories. Generated arguments follow assigned faulty routes. The original balanced math viability criterion failed and is transparently documented.',
 '40 seconds. Give the proposed next solution: display candidate, uncertainty and source support separately, then validate through a trusted source or executable check. We did not test that retrieval/tool arm, so it is a future experiment rather than a claimed measured improvement.',
 '20 seconds. Acknowledge data and papers, R packages, and AI assistance. Codex built and checked much of the implementation; Claude Code was configured to Kimi. A user filled 45 targeted records; full independent human annotation remains pending. Invite questions without claiming all generated explanations were human validated.'
)
links<-c(source_url,
 'https://openreview.net/forum?id=IkmD3fKBPQ\nhttps://aclanthology.org/2024.findings-acl.212/',
 paste0(source_url,'/blob/main/docs/experiment-plan-v1.md'),
 'https://huggingface.co/datasets/google/simpleqa-verified',
 paste0(source_url,'/blob/main/Peer_Misleading_Study/reports/main_r/effects.csv'),
 paste0(source_url,'/blob/main/Peer_Misleading_Study/reports/main_r/effects.csv'),
 paste0(source_url,'/blob/main/docs/review-discussion-2026-10-02.md'),
 'https://aclanthology.org/2024.emnlp-main.915/ (Table 13)\nhttps://machinelearning.apple.com/research/gsm-symbolic',
 paste0(source_url,'/tree/main/Math_Supplement'),
 paste0(source_url,'/blob/main/Math_Supplement/protocol/deviations.md'),
 'https://arxiv.org/abs/2005.11401\nhttps://aclanthology.org/2024.findings-acl.212/',
 'https://huggingface.co/datasets/google/simpleqa-verified\nhttps://openreview.net/forum?id=IkmD3fKBPQ\nhttps://aclanthology.org/2024.findings-acl.212/\nhttps://aclanthology.org/2024.emnlp-main.915/\nhttps://machinelearning.apple.com/research/gsm-symbolic')
data$notes<-as.list(paste(notes,'\nSources:',links))
write_json(data,'Submission_Pack/evidence/artifact_content.json')
writeLines(c('# Speaker notes and timing','',
 'Core talk: 9 minutes (540 seconds), matching the solo requirement. Add 1 minute Q&A. This is a suggested rehearsal allocation, not measured speaking time.',
 '',unlist(lapply(seq_along(notes),function(i)c(paste0('## Slide ',i),notes[i],paste('Sources:',links[i]),''))),
 '## If presenting as two students',
 'The course allows 18 minutes plus 2 minutes Q&A. Expand by 9 minutes using the report: 2 minutes on sampling and ground truth, 2 on the paired/bootstrap method, 2 on the uncertainty cases, 2 on math material failures and examples, and 1 on future experiment design. Agree an actual division of work and rehearse; do not claim both members did tasks they did not do.'),'Submission_Pack/speaker_notes.md')
files<-c('Peer_Misleading_Study/reports/main_r/tables.csv','Peer_Misleading_Study/reports/main_r/effects.csv','Peer_Misleading_Study/reports/factual_review_supplement/audit.json','Math_Supplement/reports/supplementary/tables.csv','Math_Supplement/reports/supplementary/summary.json')
for(path in files)file.copy(path,file.path('Submission_Pack/evidence',paste0(if(grepl('Math_Supplement',path))'math_' else 'fact_',basename(path))),overwrite=TRUE)
write_json(list(source_sha256=setNames(lapply(files,file_sha),files),processing='R only; document layout in JS/Python does not calculate experimental results'),'Submission_Pack/evidence/provenance.json')
cat('Artifact text, notes and numeric content exported by R.\n')
