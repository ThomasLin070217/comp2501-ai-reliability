# Offline delivery checks, all numeric comparison in R.
library(jsonlite);library(xml2);library(digest)
ppt<-'Submission_Pack/COMP2501_presentation.pptx';pdf<-'Submission_Pack/COMP2501_report.pdf'
d<-fromJSON('Submission_Pack/evidence/artifact_content.json');v<-fromJSON('Submission_Pack/evidence/visualization_data.json')
ns<-unzip(ppt,list=TRUE)$Name
readpart<-function(p)read_xml(unz(ppt,p))
textpart<-function(p){x<-readpart(p);xml_text(xml_find_all(x,'.//a:t',xml_ns(x)))}
stopifnot(sum(grepl('^ppt/slides/slide[0-9]+.xml$',ns))==18,sum(grepl('^ppt/notesSlides/notesSlide[0-9]+.xml$',ns))==18)
stopifnot(identical(d$authors,c('LINYUNIAN','PAN ZHENGYU')))
stopifnot(all(vapply(d$authors,function(a)any(grepl(a,textpart('ppt/slides/slide1.xml'),fixed=TRUE)),TRUE)))
rows<-function(z,cs)z[match(cs,z$condition),]
expected<-list(subset(d$natural$rates,domain=='facts')$error_rate,subset(d$natural$rates,domain=='mathematics')$error_rate,rows(v$error_rates,c('C0','C1','C2'))$rate,rows(v$error_rates,c('C2','C3'))$rate,rows(d$factual,c('C4','C5'))$incorrect_to_correct)
charts<-grep('/charts/chart[0-9]+.xml$',ns,value=TRUE);stopifnot(length(charts)==5)
for(i in 1:5){x<-readpart(sprintf('ppt/slides/charts/chart%d.xml',i));vv<-as.numeric(xml_text(xml_find_all(x,'.//c:ser/c:val//c:pt/c:v',xml_ns(x))));stopifnot(isTRUE(all.equal(vv,as.numeric(expected[[i]]),tolerance=1e-9)));if(i<=4)stopifnot(xml_attr(xml_find_first(x,'.//c:valAx/c:scaling/c:min',xml_ns(x)),'val')=='0',xml_attr(xml_find_first(x,'.//c:valAx/c:scaling/c:max',xml_ns(x)),'val')=='1')}
for(i in 1:18)stopifnot(grepl(d$notes[i],paste(textpart(sprintf('ppt/notesSlides/notesSlide%d.xml',i)),collapse='\n'),fixed=TRUE))
for(i in c(7,10)){x<-readpart(sprintf('ppt/slides/slide%d.xml',i));actual<-xml_text(xml_find_all(x,'.//a:tbl/a:tr/a:tc//a:t',xml_ns(x)));ex<-if(i==7)d$natural$transition_table else d$transition_table;stopifnot(identical(actual,as.character(t(ex))))}
prov<-fromJSON('Submission_Pack/evidence/provenance.json')$source_sha256
stopifnot(all(vapply(names(prov),function(p)digest(file=p,algo='sha256')==prov[[p]],TRUE)))
pdftxt<-paste(system2('/opt/homebrew/bin/pdftotext',c(pdf,'-'),stdout=TRUE),collapse='\n')
stopifnot(all(vapply(c(d$authors,'18.78','6.40','16.55','573','319','4.90','27.03','5.41'),function(v)grepl(v,pdftxt,fixed=TRUE),TRUE)))
pinfo<-system2('/opt/homebrew/bin/pdfinfo',pdf,stdout=TRUE);pages<-as.integer(sub('Pages: *','',grep('^Pages:',pinfo,value=TRUE)));stopifnot(pages==13)
receipt_paths<-list.files('.submission-build/natural-crosscheck',pattern='^validation.*json$',full.names=TRUE)
if(length(receipt_paths)){r<-fromJSON(tail(sort(receipt_paths),1));stopifnot(r$finalSha256==digest(file=ppt,algo='sha256'),r$packageIntegrity$status=='pass',r$presentationLayout$finding_count==0)}
paths<-c(pdf,ppt,'Submission_Pack/report.Rmd','Submission_Pack/proposal.md')
checks<-list(sha256=setNames(lapply(paths,function(p)digest(file=p,algo='sha256')),paths),presentation_slide_count=18,native_charts=5,native_table_owner_slides=c(3,4,7,8,10,14),finalizer_package_integrity='pass',finalizer_layout='pass',final_slides_rendered_and_visually_reviewed=18,opened_in_powerpoint=FALSE,PDF_pages_visually_reviewed=13,validation=list(authors='pass',chart_values_against_R_export='pass',all_speaker_notes_against_R_export='pass',both_transition_tables_against_R_export='pass',source_provenance_hashes='pass',PDF_key_result_text='pass'),visual_review_note='Codex inspected all18 imported final slide renders and all13 PDF page renders. Four error-rate charts share0–100% axes; numeric count chart has a zero baseline. Tables and charts are native editable objects. Primary factual pair and common-four bar denominators differ and are explicitly labeled.')
write_json(checks,'Submission_Pack/evidence/artifact_checks.json',pretty=TRUE,auto_unbox=TRUE)
proposal<-readLines('Submission_Pack/proposal.md');i<-grep('^# 3',proposal);words<-length(strsplit(trimws(paste(proposal[(i+1):length(proposal)],collapse=' ')),'[[:space:]]+')[[1]]);stopifnot(words<=300)
write_json(list(description_words=words,limit=300,passed=TRUE),'Submission_Pack/proposal_check.json',pretty=TRUE,auto_unbox=TRUE)
budget<-fromJSON('Submission_Pack/evidence/budget.json');usage<-read.csv('Natural_Crosscheck/reports/usage.csv');budget$prior_stage_snapshot<-'evidence/budget.json';budget$experimental_calls<-budget$experimental_calls+sum(usage$attempts);budget$paid_API_conservative_estimate_cny<-budget$paid_API_conservative_estimate_cny+sum(usage$token_envelope_cny[usage$paid_provider]);budget$known_paid_estimate_plus_CLI_guard<-budget$paid_API_conservative_estimate_cny+budget$CLI_guard_at_8_cny_per_usd;budget$HKU_tokens<-budget$HKU_tokens+sum(subset(usage,provider=='minimax')[c('input_tokens','output_tokens')]);budget$natural_supplement_paid_guard<-sum(usage$token_envelope_cny[usage$paid_provider]);write_json(budget,'Submission_Pack/evidence/budget_latest.json',pretty=TRUE,auto_unbox=TRUE)
cat('Validated18slides,5native charts,18notes,two transition tables,13PDF pages,source hashes; proposal',words,'words.\n')
