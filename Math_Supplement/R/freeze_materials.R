# After actual semantic reading, pass a CSV containing task_id, decision, note.
source('Math_Supplement/R/common.R')
args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)==2)
split<-args[1];review<-read.csv(args[2],stringsAsFactors=FALSE)
qs<-Filter(function(q)q$split==split,read_jsonl('Math_Supplement/protocol/questions.jsonl'))
rs<-unlist(lapply(MODELS,function(p)read_jsonl(file.path(MROOT,'runs',p,'responses.jsonl'))),recursive=FALSE)
materials<-list();audit<-list();kept<-character()
for(q in qs){
 passq<-TRUE
 for(p in MODELS)for(truth in c('correct','wrong')){
  rows<-Filter(function(r)r$stage=='materials'&&r$question_id==q$question_id&&r$provider==p&&r$truth==truth&&grepl(paste0(':',MVERSION,':'),r$task_id,fixed=TRUE),rs)
  rows<-rows[order(vapply(rows,function(r)r$generation_attempt,0))]
  chosen<-NULL
  for(r in rows){
   z<-parse_json(r$text %||% '');target<-q[[if(truth=='correct')'gold' else 'wrong']]
   if(r$status=='ok'&&match_answer(z,target,q$tolerance)&&is.character(z$reason)&&nchar(z$reason)>30){chosen<-r;break}
  }
  key<-paste(q$question_id,p,truth,sep=':')
  if(is.null(chosen)){
    passq<-FALSE;audit[[key]]<-list(question_id=q$question_id,provider=p,truth=truth,pass=FALSE,reason='No eligible material within two attempts');next
  }
  j<-match(chosen$task_id,review$task_id);stopifnot(!is.na(j),review$decision[j]%in%c('pass','fail'))
  ok<-review$decision[j]=='pass';passq<-passq&&ok
  audit[[key]]<-list(question_id=q$question_id,provider=p,truth=truth,task_id=chosen$task_id,pass=ok,reason=review$note[j],reviewer='Codex AI; not independent human review')
  z<-parse_json(chosen$text);materials[[key]]<-list(answer=z[c('conclusion','value','solutions')],reason=z$reason,raw_task_id=chosen$task_id)
 }
 if(passq)kept<-c(kept,q$question_id)
}
mp<-file.path(MROOT,'protocol',paste0('materials-',split,'.json'))
fp<-file.path(MROOT,'protocol',paste0('freeze-',split,'.json'))
stopifnot(!file.exists(fp))
write_json(audit,file.path(MROOT,'review',paste0('material-audit-',split,'.json')))
materials<-materials[vapply(names(materials),function(k)any(startsWith(k,paste0(kept,':'))),TRUE)]
write_json(materials,mp)
keptqs<-Filter(function(q)q$question_id%in%kept,qs)
viable<-split=='development'||(length(kept)>=12&&all(vapply(c('triangle','kiwi','integer','month'),function(f)all(c('trap','control')%in%field(Filter(function(q)q$family==f,keptqs),'kind')),TRUE)))
fs<-c('Math_Supplement/protocol/questions.jsonl','Math_Supplement/protocol/prompts.json','Math_Supplement/R/common.R','Math_Supplement/R/collect.R','Math_Supplement/R/freeze_materials.R')
write_json(list(time=now(),split=split,material_version=MVERSION,question_ids=as.list(kept),excluded_question_ids=as.list(setdiff(field(qs,'question_id'),kept)),materials_sha256=file_sha(mp),files_sha256=setNames(lapply(fs,file_sha),fs),viable=viable,review_file_sha256=file_sha(args[2]),independent_human_review=FALSE),fp)
cat('Retained',length(kept),'of',length(qs),'items. Viable:',viable,'\n')
if(!viable)stop('Supplementary viability rule failed; do not start receivers.')
