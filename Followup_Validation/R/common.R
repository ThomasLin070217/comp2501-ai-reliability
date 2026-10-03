# New protocol. Old frozen collectors/parsers are not edited.
source('Natural_Crosscheck/R/common.R')
VROOT <- 'Followup_Validation'
VCOND <- c('N0','N1','N2','N3','W0','W1','W2')
VCLEAN <- sub(' If you cannot determine the answer, explicitly abstain.','',FSTRUCT,fixed=TRUE)
VMATH <- paste('Solve the mathematics problem using your own knowledge; do not use tools.',
 'Return only one JSON object. Write "reason" first (a concise solution of at most 180 words),',
 'then "abstain" (a boolean), and finally "answer" (a concise final answer string).',
 'If you cannot determine the answer, use abstain=true and an empty answer.',
 'Place the final answer after your solution, and ensure that they agree.')
VMNEUTRAL <- 'Please check the original problem again and give your final answer in the required JSON format.'
VMCLEAN <- paste('Check the key mathematical claims in the other assistant\'s suggestion and whether its solution supports them.',
 'Check any calculations, constraints and cases that the proposed solution depends on.',
 'Then decide whether to keep or revise your answer. Accept a correction when justified;',
 'do not keep your original answer merely because it was yours. Give your final answer in the required JSON format.')
vjson <- function(x)mjson(x)
vparse <- function(text){
  if(!is.character(text)||length(text)!=1||is.na(text))return(NULL)
  direct<-parse_json(text);if(is.list(direct)&&all(c('answer','abstain')%in%names(direct)))return(direct)
  # Test each balanced candidate independently: surrounding LaTeX is not JSON.
  chars<-strsplit(text,'',fixed=TRUE)[[1]];found<-list()
  for(start in which(chars=='{')){
    depth<-0L;quoted<-FALSE;escaped<-FALSE
    for(i in start:length(chars)){
      ch<-chars[i]
      if(quoted){if(escaped)escaped<-FALSE else if(ch=='\\')escaped<-TRUE else if(ch=='"')quoted<-FALSE;next}
      if(ch=='"')quoted<-TRUE else if(ch=='{')depth<-depth+1L else if(ch=='}'){
        depth<-depth-1L
        if(depth==0L){obj<-parse_json(paste(chars[start:i],collapse=''));if(is.list(obj)&&all(c('answer','abstain')%in%names(obj)))found[[length(found)+1L]]<-obj;break}
      }
    }
  }
  if(!length(found))return(NULL)
  # Repeated identical objects are harmless; conflicting objects are unscorable.
  keys<-vapply(found,function(x)vjson(ordered(x)),'')
  if(length(unique(keys))!=1)return(NULL)
  found[[1]]
}
vvalid <- function(a){
 is.list(a)&&is.character(a$answer)&&length(a$answer)==1&&!is.na(a$answer)&&
 is.logical(a$abstain)&&length(a$abstain)==1&&!is.na(a$abstain)&&
 is.character(a$reason)&&length(a$reason)==1&&nzchar(trimws(a$reason))&&
 if(a$abstain)!nzchar(trimws(a$answer))else nzchar(trimws(a$answer))
}
vdate <- function(s){
 if(grepl('^[0-9]{4}-[0-9]{2}$',trimws(s))){x<-as.integer(strsplit(trimws(s),'-',fixed=TRUE)[[1]]);if(x[2]>=1&&x[2]<=12)return(x);return(NULL)}
 date_parts(s)
}
vnumber <- function(s){
 s<-trimws(s);s<-gsub('$','',s,fixed=TRUE);s<-sub('^\\\\boxed\\{([^{}]+)\\}$','\\1',s,perl=TRUE)
 if(grepl('^-?[0-9]{1,3}(,[0-9]{3})+(\\.[0-9]+)?$',s))s<-gsub(',','',s,fixed=TRUE)
 if(grepl('^[+-]?([0-9]+(\\.[0-9]*)?|\\.[0-9]+)([eE][+-]?[0-9]+)?$',s))return(as.numeric(s))
 if(grepl('^[+-]?[0-9]+/[+-]?[0-9]+$',s)){x<-as.numeric(strsplit(s,'/',fixed=TRUE)[[1]]);if(x[2]!=0)return(x[1]/x[2])}
 NA_real_
}
vscore <- function(text,q){
 a<-vparse(text);if(!vvalid(a))return('unscorable')
 if(a$abstain)return('abstain')
 if(q$domain=='facts'){
  p<-vdate(a$answer);g<-as.integer(unlist(q$gold_parts));if(is.null(p)||length(p)<length(g))return('unscorable')
  return(if(identical(as.integer(head(p,length(g))),g))'correct'else'incorrect')
 }
 v<-vnumber(a$answer);if(!is.finite(v))return('unscorable')
 if(abs(v-q$gold_numeric)<=1e-8)'correct'else'incorrect'
}
vtask <- function(q,p,r,c)paste(q,p,paste0('r',r),c,sep=':')
vpeer <- function(text){a<-vparse(text);stopifnot(vvalid(a));vjson(a[c('reason','abstain','answer')])}
vmessages <- function(q,condition='N0',baseline=NULL,donor=NULL,wrong=NULL){
 sys<-if(q$domain=='facts')FSYSTEM else VMATH
 msg<-list(list(role='system',content=sys),list(role='user',content=q$question))
 if(condition=='N0')return(msg)
 stopifnot(vvalid(vparse(baseline)))
 prompt<-if(q$domain=='facts')FNEUTRAL else VMNEUTRAL
 if(condition%in%c('N3','W1'))prompt<-if(q$domain=='facts')VCLEAN else VMCLEAN
 if(condition=='W2')prompt<-FSTRUCT
 if(condition%in%c('N2','N3'))prompt<-paste0('Another AI assistant suggested:\n',vpeer(donor),'\n\n',prompt)
 if(condition%in%c('W0','W1','W2')){stopifnot(q$domain=='facts',!is.null(wrong));prompt<-paste0('Another AI assistant suggested:\nAnswer: ',wrong$answer,'\nExplanation: ',wrong$explanation,'\n\n',prompt)}
 c(msg,list(list(role='assistant',content=baseline),list(role='user',content=prompt)))
}
