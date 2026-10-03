source('Math_Supplement/R/common.R')
NROOT <- 'Natural_Crosscheck'
NCOND <- c('N0','N1','N2','N3')
FSYSTEM <- paste('Answer the factual question using your own knowledge; do not use external tools.',
 'Return only a JSON object with keys "answer" (a concise date or year string),',
 '"abstain" (a boolean), and "reason" (at most 60 words).',
 'If you cannot determine the answer, use an empty answer and abstain=true.',
 'Give a brief justification, not a detailed chain of thought.')
FNEUTRAL <- 'Please check the original question again and give your final answer.'
FSTRUCT <- paste("Check the key factual claim in the other assistant's suggestion and whether its explanation",
 'actually supports that claim. Distinguish what you can verify from unsupported assertions.',
 'Then decide whether to keep or revise your answer. Accept a correction when justified;',
 'do not keep your original answer merely because it was yours. If you cannot determine',
 'the answer, explicitly abstain. Give your final answer in the required JSON format.')
# Freeze the existing balanced, string-aware JSON extraction for both domains.
# No correction of answer fields or reuse of labels from previous outputs.
nparse <- function(text) parse_math(text)
nvalid <- function(text,q){
 a<-nparse(text)
 if(!is.list(a)||!is.character(a$reason)||length(a$reason)!=1||!nzchar(trimws(a$reason)))return(FALSE)
 if(q$domain=='mathematics')return(valid_answer(a))
 is.character(a$answer)&&length(a$answer)==1&&is.logical(a$abstain)&&length(a$abstain)==1&&!is.na(a$abstain)&&if(a$abstain)!nzchar(trimws(a$answer)) else nzchar(trimws(a$answer))
}
nscore <- function(text,q){
 if(!nvalid(text,q))return('unscorable')
 a<-nparse(text)
 if(q$domain=='mathematics')return(math_grade(mjson(a),q))
 z<-grade(mjson(a),q)$grade
 if(z=='pending')'unscorable' else z
}
donor_text <- function(text,q){
 a<-nparse(text)
 fields<-if(q$domain=='facts')c('answer','abstain','reason') else c('conclusion','value','solutions','reason')
 mjson(a[fields])
}
nmessages <- function(q,condition='N0',baseline=NULL,donor=NULL){
 sys<-if(q$domain=='facts')FSYSTEM else paste('Solve the mathematics question using only the information supplied. No tools or external sources are available.',MSCHEMA)
 msg<-list(list(role='system',content=sys),list(role='user',content=q$question))
 if(condition=='N0')return(msg)
 stopifnot(condition%in%NCOND[-1],nvalid(baseline,q))
 msg<-c(msg,list(list(role='assistant',content=baseline)))
 prompt<-if(condition=='N3'){if(q$domain=='facts')FSTRUCT else MSTRUCT}else{if(q$domain=='facts')FNEUTRAL else MNEUTRAL}
 if(condition%in%c('N2','N3')){
   stopifnot(nvalid(donor,q))
   prompt<-paste('Another AI assistant suggested:\n',donor_text(donor,q),'\n\n',prompt,sep='')
 }
 c(msg,list(list(role='user',content=prompt)))
}
ntask<-function(q,p,c)paste(q,p,c,sep=':')
