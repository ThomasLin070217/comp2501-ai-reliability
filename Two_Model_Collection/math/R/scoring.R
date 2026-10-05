# Frozen pre-collection mathematical final-answer scoring. Unknown forms are reviewed,
# never guessed by a last-number extractor. This file performs no model/API calls.
math_parse <- function(text) {
 if(!is.character(text)||length(text)!=1L||is.na(text))return(NULL)
 t<-trimws(text);t<-sub('^```(?:json)?[[:space:]]*','',t,perl=TRUE);t<-sub('[[:space:]]*```$','',t,perl=TRUE)
 x<-tryCatch(jsonlite::fromJSON(t,simplifyVector=FALSE),error=function(e)NULL)
 scalar<-function(z)is.character(z)&&length(z)==1L&&!is.na(z)
 if(!is.list(x)||!scalar(x$answer)||!scalar(x$reason)||!is.logical(x$abstain)||length(x$abstain)!=1L||is.na(x$abstain))return(NULL)
 x
}
math_numeric <- function(answer) {
 a<-trimws(answer);a<-gsub('\u2212','-',a,fixed=TRUE);a<-gsub(',','',a,fixed=TRUE)
 a<-gsub('\\\\(?:boxed|text|mathrm)\\{([^{}]*)\\}','\\1',a,perl=TRUE)
 a<-gsub('\\\\frac\\{(-?[0-9.]+)\\}\\{(-?[0-9.]+)\\}','(\\1/\\2)',a,perl=TRUE)
 a<-gsub('[${}]','',a);a<-trimws(a)
 # An explicit single-value statement can carry units, not another expression.
 a<-sub('^(?:the )?(?:minimum(?: value)?|maximum(?: value)?|smallest value|largest value|remainder|answer|limit(?: difference)?|value|number(?: of [a-z ]+)?|a|a_1964)\\s*(?:is|=|:)\\s*','',tolower(a),perl=TRUE)
 a<-sub('\\s*(?:ways|triples|colorings|colourings|permutations|subsets|questions|terms|integers|solutions|allocations|arrangements|queries|tilings)\\.?$','',a,perl=TRUE)
 a<-sub('\\.$','',trimws(a))
 if(!grepl('^[0-9+*/^(). -]+$',a)||nchar(a)>100L)return(NA_real_)
 # Only numeric constants and arithmetic operators; no symbols/function calls.
 expr<-tryCatch(parse(text=a)[[1]],error=function(e)NULL)
 safe<-function(e){if(is.numeric(e))return(TRUE);if(!is.call(e))return(FALSE);as.character(e[[1]])%in%c('+','-','*','/','^','(')&&all(vapply(as.list(e)[-1],safe,TRUE))}
 if(is.null(expr)||!safe(expr))return(NA_real_)
 v<-tryCatch(eval(expr,envir=baseenv()),error=function(e)NA_real_)
 if(!is.numeric(v)||length(v)!=1L||!is.finite(v))NA_real_ else v
}
math_score <- function(text,question_id,refs=NULL) {
 if(is.null(refs))refs<-jsonlite::fromJSON('Two_Model_Collection/math/protocol/researcher_reference.json',simplifyVector=FALSE)
 ids<-vapply(refs,`[[`,'','question_id');q<-refs[[match(question_id,ids)]]
 if(is.null(q))stop('Unknown mathematics question')
 out<-function(label,reason,conflict=FALSE,review=FALSE,answer=NA_character_)list(label=label,scoring_reason=reason,conflict=conflict,needs_review=review,answer=answer)
 x<-math_parse(text);if(is.null(x))return(out('unscorable','invalid_or_incomplete_json',review=TRUE))
 a<-trimws(x$answer);s<-tolower(gsub('\u2212','-',a,fixed=TRUE));r<-tolower(x$reason)
 if(x$abstain){if(nzchar(a))return(out('unscorable','abstain_true_with_substantive_answer',TRUE,TRUE,a));return(out('abstain','explicit_abstention',answer=a))}
 if(!nzchar(a))return(out('unscorable','empty_answer_without_abstention',TRUE,TRUE,a))
 no_min<-grepl('no (?:finite )?minimum|minimum (?:is |does )?(?:not |never )?(?:attained|exist)|not attained|unattained|only (?:an? )?infimum|infimum.*(?:but|without|not)',s,perl=TRUE)
 # Positive assertion "minimum is attained" must not match a negative claim.
 no_min<-grepl('no (?:finite )?minimum|minimum (?:is not|does not|never|is never)|not attained|unattained|only (?:an? )?infimum|infimum.*(?:but|without|not)',s,perl=TRUE)
 no_min_ids<-paste0('CHAMP:P_Inequality_',c(8,15,24))
 if(question_id%in%no_min_ids && no_min)return(out('wrong','false_nonattainment_assertion',answer=a))
 compact<-gsub('[[:space:]${}]','',s)
 if(question_id=='CHAMP:P_Polynomial_1' && compact%in%c('x-1','x−1','remainder=x-1'))return(out('wrong','nonzero_symbolic_remainder',answer=a))
 if(question_id=='CHAMP:P_Sequence_28' && compact%in%c('u-v','v-u'))return(out('wrong','nonzero_symbolic_limit_difference',answer=a))
 value<-math_numeric(a)
 if(is.na(value))return(out('unscorable','unrecognized_final_answer_requires_semantic_review',review=TRUE,answer=a))
 gold<-as.numeric(q$reference_answer);label<-if(abs(value-gold)<=1e-9)'correct'else'wrong'
 reason_conflict<-question_id%in%no_min_ids && label=='correct' && grepl('no minimum|minimum is not attained|minimum does not exist|infimum is 0 but',r)
 out(label,'single_numeric_final_answer',conflict=reason_conflict,review=reason_conflict,answer=a)
}
