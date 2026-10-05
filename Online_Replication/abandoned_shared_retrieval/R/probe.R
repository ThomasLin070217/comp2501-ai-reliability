source('Online_Replication/R/search.R')
cfg<-read_json('Followup_Validation/protocol/models.json')$minimax
queries<-c('Nobel Prize official website homepage','site:mathworld.wolfram.com Pythagorean theorem')
summary<-list()
for(i in seq_along(queries)){
 id<-paste0('probe:retrieval:',i);old<-indexed(oread(file.path(OROOT,'runs/responses.jsonl')),'id')[[id]]
 r<-if(is.null(old))ohttp(search_request(queries[i],cfg),cfg,id,'probe',2,budget=5)else old
 ev<-extract_evidence(r$raw_response)
 summary[[i]]<-list(id=id,status=r$status,actual_search=ev$search_calls,accepted_sources=length(ev$sources),valid=ev$valid,guard_cny=r$guard_cny)
 print(summary[[i]])
}
write_json(summary,file.path(OROOT,'probe/retrieval_validation.json'))
