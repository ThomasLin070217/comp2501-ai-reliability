source('Online_Replication/R/common.R')
p<-file.path(OROOT,'protocol/freeze.json');stopifnot(!file.exists(p))
tests<-read_json(file.path(OROOT,'protocol/tests.json'));stopifnot(all(unlist(tests$checks)))
files<-c(list.files(file.path(OROOT,'R'),full.names=TRUE),list.files(file.path(OROOT,'protocol'),full.names=TRUE),file.path(OROOT,'README.md'),
 'Followup_Validation/R/common.R','Natural_Crosscheck/R/common.R','Math_Supplement/R/common.R','Peer_Misleading_Study/R/core.R',
 'Peer_Misleading_Study/data/main_frozen/materials.json','Math_Supplement/protocol/materials-supplementary.json')
write_json(list(time=now(),status='frozen_before_formal_calls',research='Autonomous native web tool use; no mandatory search or prefetched evidence',
 questions=154,planned_outputs=7146,repeats=2,collection_stop_guard_cny=480,authorized_new_budget_cny=500,max_http_turns_per_answer=4,
 primary='N2-N1 by facts and CHAMP mathematics, question means then equal model means',
 files_sha256=setNames(lapply(files,file_sha),files)),p)
cat('Frozen before formal collection.\n')
