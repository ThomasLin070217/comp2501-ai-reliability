# Synthetic fixtures live only in a temporary directory, never in research runs.
source('Two_Model_Collection/facts/protocol/scoring.R')
realroot<-'Two_Model_Collection/facts';testroot<-tempfile('facts-analysis-fixture-')
dir.create(file.path(testroot,'protocol'),recursive=TRUE);dir.create(file.path(testroot,'runs'))
for(n in c('tasks.csv','questions.jsonl'))stopifnot(file.copy(file.path(realroot,'protocol',n),file.path(testroot,'protocol',n)))
tasks<-read.csv(file.path(realroot,'protocol/tasks.csv'),stringsAsFactors=FALSE)
ids<-head(read.csv(file.path(realroot,'protocol/mechanism_subset.csv'))$question_id,2)
qs<-indexed(read_jsonl(file.path(realroot,'protocol/questions.jsonl')),'question_id')
tt<-tasks[tasks$question_id%in%ids,]
fixture<-lapply(seq_len(nrow(tt)),function(i){
 t<-tt[i,];q<-qs[[t$question_id]];wrong<-t$condition%in%c('misconception_initial','A1_AI')
 list(id=t$id,status='ok',search_requested=0,text=mjson(list(answer=if(wrong)q$false_target else q$gold,
  abstain=FALSE,reason='SYNTHETIC TEST FIXTURE ONLY, not a research observation.')))
})
write_jsonl(fixture,file.path(testroot,'runs/completed.jsonl'))
Sys.setenv(FACTS_ANALYSIS_ROOT=testroot)
source(file.path(realroot,'R/analyse.R'))
Sys.unsetenv('FACTS_ANALYSIS_ROOT')
res<-read.csv(file.path(testroot,'reports/paired_effects.csv'))
stopifnot(res$difference[res$comparison=='natural_crosscheck']==0,
 res$difference[res$comparison=='propagation_AI']==1,
 res$difference[res$comparison=='attribution_A1']==-1)
paths<-read.csv(file.path(testroot,'reports/propagation_path_counts.csv'))
stopifnot(all(paths$path_per_eligible[paths$condition=='A1_AI']==1),
 all(paths$path_per_eligible[paths$condition=='A1_Human']==0))
ix<-read_json(file.path(testroot,'reports/source_input_interaction.json'))
stopifnot(ix$difference==-1)
summary<-read_json(file.path(testroot,'reports/summary.json'))
stopifnot(summary$completed==56,!summary$scope_complete,summary$not_collected==1544)
write_json(list(status='passed',synthetic_only=TRUE,network_calls=0,
 checks=c('equal_model_paired_effects','full_propagation_denominators','four_branch_interaction','partial_coverage')),
 file.path(realroot,'reports/analysis_fixture_checks.json'))
unlink(testroot,recursive=TRUE)
cat('Synthetic paired-analysis checks passed; fixture directory removed.\n')
