#!/usr/bin/env Rscript
args<-commandArgs(trailingOnly=TRUE)
if(length(args)!=2)stop('Usage: Rscript verify_readable_workbook.R PAYLOAD_JSON WORKBOOK_XLSX')
library(xml2);library(jsonlite)
p<-fromJSON(args[1],simplifyVector=FALSE)
tmp<-tempfile('review-xlsx-');dir.create(tmp);unzip(args[2],exdir=tmp)
ns<-c(x='http://schemas.openxmlformats.org/spreadsheetml/2006/main')
ss<-read_xml(file.path(tmp,'xl/sharedStrings.xml'))
strs<-vapply(xml_find_all(ss,'.//x:si',ns),function(n)paste0(xml_text(xml_find_all(n,'.//x:t',ns)),collapse=''),'')
results<-list()
for(i in seq_along(p$sheets)){
 spec<-p$sheets[[i]];doc<-read_xml(file.path(tmp,paste0('xl/worksheets/sheet',i,'.xml')))
 value<-function(addr){
  n<-xml_find_first(doc,paste0('.//x:c[@r="',addr,'"]'),ns)
  if(inherits(n,'xml_missing'))return('')
  v<-xml_text(xml_find_first(n,'x:v',ns))
  if(identical(xml_attr(n,'t'),'s'))return(strs[as.integer(v)+1])
  if(identical(xml_attr(n,'t'),'inlineStr'))return(paste0(xml_text(xml_find_all(n,'.//x:t',ns)),collapse=''))
  if(is.na(v))'' else v
 }
 for(r in seq_along(spec$rows))for(col in seq_along(spec$rows[[r]])){
  addr<-paste0(LETTERS[col],r+7)
  if(!identical(value(addr),as.character(spec$rows[[r]][[col]])))stop('Saved value mismatch: ',spec$name,' ',addr)
 }
 stopifnot(value('B3')=='',value('E3')=='',xml_attr(xml_find_first(doc,'.//x:pane',ns),'ySplit')=='7')
 rules<-xml_find_all(doc,'.//x:dataValidation',ns);stopifnot(length(rules)==length(spec$validation))
 for(j in seq_along(rules)){
  stopifnot(xml_attr(rules[[j]],'sqref')==spec$validation[[j]]$range)
  text<-xml_text(xml_find_first(rules[[j]],'x:formula1',ns))
  stopifnot(all(vapply(spec$validation[[j]]$values,function(s)grepl(s,text,fixed=TRUE),TRUE)))
 }
 results[[spec$name]]<-list(rows=length(spec$rows),all_data_cells_match=TRUE,validation_lists=length(rules),frozen_header_rows=7)
}
write_json(list(status='passed',sheets=results,reviewer_inputs_blank=TRUE),file.path(dirname(args[1]),'workbook_verification.json'),pretty=TRUE,auto_unbox=TRUE)
cat('Saved workbook matches all R-prepared data cells; dropdowns, empty inputs and frozen headers verified.\n')
