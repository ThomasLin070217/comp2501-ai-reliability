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
 '50 seconds. The 100% stacked bars show the proportions correct, wrong and abstaining; all use 719 complete units. Structured prompts shift many outputs into abstention. Date accuracy does not validate the explanation or prove evidence was consulted. Mention the correct 1975 candidate with explicit uncertainty as a case of mixed dimensions.',
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
idir<-'Peer_Misleading_Study/reports/interaction_posthoc'
ie<-read.csv(file.path(idir,'effects.csv'))
ip<-read.csv(file.path(idir,'condition_tables.csv'));ip<-ip[ip$provider=='pooled',]
ip$error_pct<-round(100*ip$incorrect/ip$n,2)
data$interaction<-unname(lapply(seq_len(nrow(ip)),function(i)as.list(ip[i,])))
it<-read.csv(file.path(idir,'transitions.csv'))
tm<-subset(it,comparison=='C3_vs_C2'&provider=='pooled'&baseline_stratum=='all')
mx<-xtabs(n~from+to,tm)[c('correct','incorrect','abstain'),c('correct','incorrect','abstain')]
data$transition_table<-c(list(c('C2 outcome','C3 correct','C3 wrong','C3 abstain')),lapply(1:3,function(i)c(c('Correct','Wrong','Abstain')[i],as.character(mx[i,]))))
data$authors<-c('LINYUNIAN','PAN ZHENGYU')
notes[1]<-'Introduce LINYUNIAN and PAN ZHENGYU. The project asks whether structured checking helps resist misleading input. AI-generated suggestions simulate a person bringing an assumption or explanation into an AI conversation. The actual source label says another AI. We measured no human behavior.'
notes[2]<-'Present original RQ1 and RQ2, then identify the new all-unit comparisons explicitly as post-hoc additions. The original harmful-flip and repair outcomes remain unchanged. The supplement looks at uncertainty becoming a wrong answer, not just initially correct answers becoming wrong.'
notes[10]<-'Explain selected difficult date questions, model differences and source concerns. MiniMax C2 versus C0 error change is -1.67 points with interval [-8.40,5.42], unlike the pooled increase. Both source-exclusion variants preserve pooled directions. The AI semantic review is targeted and unblinded. Human thinking was not measured. Mathematical material eligibility failed the original balanced design and remains a partial supplement.'
notes[11]<-'Connect the results to use: avoid supplying guesses as settled facts, ask for the evidence supporting the exact claim, and preserve uncertainty. A trusted source or executable test is a proposed application design, not a tested intervention here. Ordinary rechecking did not show the structured prompt benefit. Abstention may protect users from misinformation, but its effect on human thinking was not measured.'
notes[12]<-'Name the project team: LINYUNIAN and PAN ZHENGYU. Cite the dataset and papers. Disclose Codex implementation, R analysis and targeted AI review. Earlier Claude Code review used the configured Kimi backend. Do not invent individual student responsibilities or describe AI review as independent human validation.'
extra_notes<-c(
 'Read the two bar charts using their shared 0-100% vertical scale. The left compares C0/C1/C2: wrong input raises error. The right compares identical wrong material in C2/C3: structured checking lowers error. Error rate is wrong divided by correct plus wrong plus abstain; explicit abstentions count as non-errors for this metric but remain a separate outcome. Each denominator is 719. Values follow the existing final-answer score, not a guarantee that every explanation is factually correct. Statistical intervals are retained in the report supplement. Post-hoc analysis of all 719 paired units. Error rates are 46.04% for C0, 64.81% C1, 52.43% C2 and 35.88% C3. C1-C0 is +18.78 points [14.35,23.09], C2-C0 +6.40 [1.94,10.99], and C3-C2 -16.55 [-20.70,-12.38]. Pointwise exploratory intervals use 5000 question-cluster draws, seed 25011003. C0 minus initial error is +1.25 [-3.06,5.56]. The wrong-target counts are 11,251,147,58. C0 matching is spontaneous. These results do not support explanations being more harmful than wrong answers alone.',
 'Read the C2-by-C3 heatmap. Rows are C2, columns are C3. Each cell shows a paired count; darker cells mean more pairs on a shared 0-228 scale. Most prevented errors become abstentions: 144 wrong-to-abstain and 5 wrong-to-correct, offset by 21 abstain-to-wrong and 9 correct-to-wrong. Net wrong outputs fall by 119, but correct outputs also fall by 21. Comparisons use parallel branches, not sequential follow-ups. Relative to C0, C1/C2 include 158/114 abstain-to-wrong pairs and 25/67 reverse pairs, showing how misleading input can fill a knowledge gap.',
 'Notepad++ version 7.8.8 has official release date June 28 2020. The same MiniMax repeat in parallel branches cannot confirm under C0, answers June 29 under C1 and C2, and abstains under C3 because the explanation gives no verifiable evidence. The exact C1 phrase is as confirmed by the official Notepad++ release notes. The receiver had no search tool. A correct date or confident verification phrase does not prove a lookup occurred. Preserve the counterexample: DeepSeek repeat 0 C4 is correct and C5 gives June 4.',
 'Codex read 240 pairs containing 451 distinct responses, including all 144 C2-wrong/C3-abstain pairs. Among the 144, 114 withhold a date, 25 offer only unconfirmed candidates, 3 challenge the premise and 2 retain date assertions. Remaining background claims were not exhaustively checked. Telegram C3 still claims premium animated emoji in December 2021, conflicting with its official August 2022 introduction. No additional manual labeling is required for this delivery, and no independent human validation is claimed.'
)
extra_links<-c(rep(paste0(source_url,'/blob/main/Submission_Pack/补充分析_2026-10-03.md'),2),
 'https://github.com/notepad-plus-plus/notepad-plus-plus/wiki/Changes-v7#788',
 paste0(source_url,'/blob/main/Peer_Misleading_Study/reports/interaction_posthoc/ai_case_review.csv\nhttps://telegram.org/blog/custom-emoji?setln=en'))
notes<-c(notes,extra_notes);links<-c(links,extra_links)
ord<-c(1:5,13,14,6,7,15,16,8:12)
data$order<-ord-1L
notes<-notes[ord];links<-links[ord]
durations<-c(30,60,90,70,60,90,90,70,60,90,60,60,70,60,80,40)
stopifnot(length(notes)==16,sum(durations)==1080)
notes<-paste0(durations,' seconds. ',sub('^[0-9]+ seconds[.] ','',notes))
data$notes<-as.list(paste(notes,'\nSources:',links))
write_json(data,'Submission_Pack/evidence/artifact_content.json')
writeLines(c('# Speaker notes and timing','',
 'Team: LINYUNIAN and PAN ZHENGYU. Suggested two-person talk: 18 minutes (1,080 seconds), plus 2 minutes Q&A. This is a rehearsal allocation, not measured speaking time. Presenter allocation can be agreed by the team and does not imply past contribution claims.',
 '',unlist(lapply(seq_along(notes),function(i)c(paste0('## Slide ',i),notes[i],paste('Sources:',links[i]),''))),
 '## Rehearsal',
 'A possible speaking split is LINYUNIAN for slides 1-7 and PAN ZHENGYU for slides 8-16. This is a suggestion for presenting, not a statement of who performed the research. Rehearse together and redistribute time as needed.'),'Submission_Pack/speaker_notes.md')
files<-c('Peer_Misleading_Study/reports/main_r/tables.csv','Peer_Misleading_Study/reports/main_r/effects.csv','Peer_Misleading_Study/reports/factual_review_supplement/audit.json','Math_Supplement/reports/supplementary/tables.csv','Math_Supplement/reports/supplementary/summary.json')
for(path in files)file.copy(path,file.path('Submission_Pack/evidence',paste0(if(grepl('Math_Supplement',path))'math_' else 'fact_',basename(path))),overwrite=TRUE)
extra_files<-file.path(idir,c('effects.csv','transitions.csv','review_audit.json','reproducibility.json'))
for(path in extra_files)file.copy(path,file.path('Submission_Pack/evidence',paste0('interaction_',basename(path))),overwrite=TRUE)
files<-c(files,extra_files)
write_json(list(source_sha256=setNames(lapply(files,file_sha),files),processing='R only; document layout in JS/Python does not calculate experimental results'),'Submission_Pack/evidence/provenance.json')
cat('Artifact text, notes and numeric content exported by R.\n')
