# Post-hoc review only. Preserve the original workbook and frozen main scores.
source('Peer_Misleading_Study/R/core.R')
out<-'Peer_Misleading_Study/reports/factual_review_supplement';dir.create(out,recursive=TRUE,showWarnings=FALSE)
wb<-'outputs/01a0e6a9-review/COMP2501_人工复核.xlsx';before<-file_sha(wb)
tmp<-tempfile();dir.create(tmp);unzip(wb,exdir=tmp)
ns<-c(x='http://schemas.openxmlformats.org/spreadsheetml/2006/main')
ss<-xml2::read_xml(file.path(tmp,'xl/sharedStrings.xml'))
strs<-vapply(xml2::xml_find_all(ss,'.//x:si',ns),function(n)paste0(xml2::xml_text(xml2::xml_find_all(n,'.//x:t',ns)),collapse=''),'')
read_sheet<-function(i,nrows,ncols){
 doc<-xml2::read_xml(file.path(tmp,sprintf('xl/worksheets/sheet%d.xml',i)))
 val<-function(addr){
  n<-xml2::xml_find_first(doc,paste0('.//x:c[@r="',addr,'"]'),ns);if(inherits(n,'xml_missing'))return('')
  if(identical(xml2::xml_attr(n,'t'),'inlineStr'))return(paste0(xml2::xml_text(xml2::xml_find_all(n,'.//x:t',ns)),collapse=''))
  v<-xml2::xml_text(xml2::xml_find_first(n,'x:v',ns));if(identical(xml2::xml_attr(n,'t'),'s'))return(strs[as.integer(v)+1]);if(is.na(v))'' else v
 }
 z<-t(vapply(8:(7+nrows),function(r)vapply(LETTERS[seq_len(ncols)],function(c)val(paste0(c,r)),''),rep('',ncols)))
 as.data.frame(z,stringsAsFactors=FALSE)
}
r<-read_sheet(2,45,9);names(r)<-c('question_short_id','question','answer','abstain_display','reason','human_code_raw','human_conflict_raw','human_note_raw','packet_id')
s<-read_sheet(1,6,8);names(s)<-c('question_short_id','question','reference_answer','original_source','human_source_code_raw','human_corrected_answer','human_source','human_note')
r$provisional_code_interpretation<-ifelse(r$human_code_raw%in%c('T','1'),'correct',ifelse(r$human_code_raw%in%c('F','0'),'incorrect','unresolved'))
r$mapping_status<-'AI interpretation only; original human codes retained; no main-grade update'
r$reviewer_identity_status<-'User reported completion; workbook name/date blank'
map<-read.csv('Peer_Misleading_Study/reports/key_review_r/coordinator/response_mapping.csv',stringsAsFactors=FALSE)
ix<-match(r$packet_id,map$packet_id);stopifnot(!anyNA(ix),!anyDuplicated(r$packet_id))
r$task_id<-map$task_id[ix];r$frozen_main_grade<-map$grade[ix]
r$agrees_if_mapping_accepted<-ifelse(r$provisional_code_interpretation=='unresolved',NA,r$provisional_code_interpretation==r$frozen_main_grade)
write.csv(r,file.path(out,'human_first_batch.csv'),row.names=FALSE,na='')
write.csv(s,file.path(out,'human_sources.csv'),row.names=FALSE,na='')
# These flags measure words in outputs, NOT latent verification or hallucination rates.
d<-read.csv('Peer_Misleading_Study/reports/main_r/analysis_data.csv',stringsAsFactors=FALSE)
parsed<-lapply(d$response_text,parse_json)
d$reason_extracted<-vapply(parsed,function(z)if(is.list(z)&&is.character(z$reason))z$reason else '', '')
d$answer_extracted<-vapply(parsed,function(z)if(is.list(z)&&is.character(z$answer))z$answer else '', '')
d$parse_available<-vapply(parsed,is.list,TRUE)
d$uncertainty_word_flag<-grepl("cannot|can't|not certain|uncertain|not sure|not confident|unable|could not|couldn't|not definitively|unverified",d$reason_extracted,ignore.case=TRUE,perl=TRUE)
d$verification_word_flag<-grepl('verif|confirm|check|source|record|document|evidence',d$reason_extracted,ignore.case=TRUE,perl=TRUE)
d$explicit_abstention_phrase_flag<-grepl('warrants abstention|should abstain|must abstain|will abstain|I abstain',d$reason_extracted,ignore.case=TRUE,perl=TRUE)
d$flag_type<-'posthoc lexical screening, not semantic truth label'
write.csv(d[,c('task_id','question_id','provider','condition','grade','parse_available','answer_extracted','reason_extracted','uncertainty_word_flag','verification_word_flag','explicit_abstention_phrase_flag','flag_type')],file.path(out,'lexical_screen.csv'),row.names=FALSE,na='')
agg<-aggregate(cbind(n=rep(1,nrow(d)),parsed=as.integer(d$parse_available),uncertainty_words=as.integer(d$uncertainty_word_flag),verification_words=as.integer(d$verification_word_flag)),by=list(condition=d$condition,grade=d$grade),FUN=sum)
write.csv(agg,file.path(out,'lexical_summary.csv'),row.names=FALSE)
known<-data.frame(task_id=c('SV3693:minimax:r0:C1','SV1199:minimax:r0:C5'),
 annotation=c('Explanation does not clearly support answer year; distinct naming events may differ. Not a confirmed contradiction.','Correct final date and useful uncertainty statement; explicit abstention recommendation conflicts with abstain=false.'),
 verification_status=c('No external tool trace exists; wording alone cannot establish actual verification.','No external tool trace exists; wording alone cannot establish actual verification.'),
 annotator='Codex AI, post-hoc',stringsAsFactors=FALSE)
known<-merge(known,d[,c('task_id','answer_extracted','reason_extracted','grade')],by='task_id',sort=FALSE)
write.csv(known,file.path(out,'case_annotations.csv'),row.names=FALSE)
stopifnot(nrow(d)==5033,identical(file_sha(wb),before),nrow(known)==2)
write_json(list(workbook_sha256=before,workbook_unchanged=TRUE,rows=45,sources=6,
 raw_counts=as.list(table(r$human_code_raw)),provisional_counts=as.list(table(r$provisional_code_interpretation)),
 comparable=sum(!is.na(r$agrees_if_mapping_accepted)),agreements=sum(r$agrees_if_mapping_accepted,na.rm=TRUE),
 independent_human_review_complete=FALSE,main_grades_changed=FALSE,full_corpus_lexical_rows=nrow(d),
 machine_parse_available=sum(d$parse_available)),file.path(out,'audit.json'))
writeLines(c('# Factual review supplement (post hoc)',
 'The original 120-question experiment and its 5,033 main grades are unchanged. The workbook is read-only and identified by SHA256 in audit.json.',
 '', '## Human first batch',
 '45 records and six source judgments were imported from the user-filled Excel file. Original T/F/1/0/- codes remain verbatim. T/1 -> correct and F/0 -> incorrect are explicit provisional interpretations. A dash stays unresolved; it is not silently converted to abstention. Name/date/conflict fields remain unfilled. This is targeted, partial review, not an independent annotation study.',
 '', '## Additional measurements',
 'The full corpus is screened in R for uncertainty words and verification-related words. These are lexical flags only: negations, quotations, context and wording can cause false positives/negatives. A verification-word flag cannot be reported as a hallucinated verification claim. No half-credit utility score is assigned. No human benefit is inferred from answer accuracy alone.',
 'Two discussed cases receive separate, identifiable AI semantic notes. No extrapolation from these notes to a whole-corpus contradiction rate is permitted.',
 '', '## Remaining human decisions',
 'Confirm the meaning of the three dash codes, add reviewer name/date, and resolve the source controversies if final human adjudication is desired. Remaining 171 response reviews stay pending. AI preparation and checks are complete; these human decisions cannot be invented.'),file.path(out,'README.md'))
unlink(tmp,recursive=TRUE)
cat('Read-only human import and full-corpus lexical screening complete.\n')
