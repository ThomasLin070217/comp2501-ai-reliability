source('Math_Crosscheck_500/R/common.R')
a <- mc_args(); gate <- mc_check(a$index,a$questions)
if(!isTRUE(gate$ready)) {cat(gate$phase,'; no follow-up tasks prepared.\n',sep=''); quit(status=0)}
b <- mc_read_csv(a$index); q <- mc_read_csv(a$questions)
p <- fromJSON(file.path(mc_root,'protocol/prompts.json'))
mm <- b[b$model=='minimax',]; mm <- mm[match(q$eval_id,mm$question_id),]
ds <- b[b$model=='deepseek',]; ds <- ds[match(mm$question_id,ds$question_id),]
materials <- NULL
if(!is.null(a$materials)) {
  materials <- mc_read_csv(a$materials)
  needed <- c('question_id','wrong_answer','peer_text','error_type','why_wrong','review_status','reviewer','reviewed_at')
  if(!all(needed %in% names(materials)) || anyDuplicated(materials$question_id) ||
     any(!materials$question_id %in% mm$question_id[mm$grade=='correct']))
    stop('Materials must be unique, reviewed candidates for initially correct MiniMax questions.')
  if(any(!materials$review_status %in% c('approved','excluded','pending'))) stop('Unknown material review status.')
  approved <- materials$review_status=='approved'
  for(n in setdiff(needed,c('question_id','review_status'))) if(any(!nzchar(materials[[n]][approved])))
    stop('An approved material lacks its stimulus or review evidence.')
  if(any(materials$review_status=='pending')) stop('All supplied material decisions must be finalized before preparation.')
}
rows <- list(); add <- function(i,condition,peer='',target='',material_id='') {
  follow <- p$review_suffix
  if(condition!='self_check') {
    parts <- strsplit(p$peer_wrapper,'{peer_response}',fixed=TRUE)[[1]]
    follow <- paste0(parts[1],peer,parts[2])
  }
  rows[[length(rows)+1L]] <<- data.frame(task_id=paste0(mm$question_id[i],':minimax:',condition),
    question_id=mm$question_id[i],family_id=mm$family_id[i],receiver='minimax',
    condition=condition,baseline_id=mm$initial_record_id[i],
    donor_id=if(condition=='natural_crosscheck') ds$initial_record_id[i] else '',
    initial_grade=mm$grade[i],donor_initial_grade=ds$grade[i],
    conversation_path=mm$conversation_path[i],settings_id=mm$settings_id[i],
    peer_origin=if(condition=='natural_crosscheck') 'actual_deepseek_initial' else if(condition=='manipulated_crosscheck') 'researcher_constructed' else 'none',
    material_id=material_id,wrong_target=target,followup_prompt=follow,stringsAsFactors=FALSE)
}
for(i in seq_len(nrow(mm))) {
  if(!mm$grade[i] %in% c('correct','incorrect','abstention')) next
  add(i,'self_check')
  if(ds$grade[i] %in% c('correct','incorrect','abstention')) add(i,'natural_crosscheck',ds$answer_text[i])
  if(!is.null(materials) && mm$grade[i]=='correct') {
    j <- match(mm$question_id[i],materials$question_id)
    if(!is.na(j) && materials$review_status[j]=='approved')
      add(i,'manipulated_crosscheck',materials$peer_text[j],materials$wrong_answer[j],
        paste0('synthetic:',materials$question_id[j]))
  }
}
if(!length(rows)) stop('No replayable MiniMax initial answers; report coverage rather than collecting replacements.')
tasks <- do.call(rbind,rows)
set.seed(as.integer(p$run_seed))
order_questions <- sample(unique(tasks$question_id))
tasks <- do.call(rbind,lapply(order_questions,function(id){t <- tasks[tasks$question_id==id,,drop=FALSE];t[sample.int(nrow(t)),,drop=FALSE]}))
tasks$run_order <- seq_len(nrow(tasks)); rownames(tasks) <- NULL
out <- file.path(mc_root,'prepared',if(is.null(materials)) 'natural' else 'with_controlled')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
task_path <- file.path(out,'tasks.csv'); manifest_path <- file.path(out,'manifest.json')
if(file.exists(task_path) || file.exists(manifest_path)) stop('Prepared manifest already exists; do not overwrite a frozen preparation.')
write.csv(tasks,task_path,row.names=FALSE,na='')
write.csv(as.data.frame(table(mm$grade,ds$grade)),file.path(out,'initial_outcome_table.csv'),row.names=FALSE)
mc_json(list(status='prepared_not_collected',gate=gate,receiver='minimax',donor='deepseek',
  logical_followup_tasks=nrow(tasks),conditions=as.list(table(tasks$condition)),
  material_file=a$materials,material_sha256=if(is.null(a$materials)) NULL else mc_hash(a$materials),
  controlled_eligible=sum(tasks$condition=='manipulated_crosscheck'),
  initially_correct_without_controlled_material=sum(mm$grade=='correct')-sum(tasks$condition=='manipulated_crosscheck'),
  script_sha256=mc_hash('Math_Crosscheck_500/R/prepare.R'),
  common_sha256=mc_hash('Math_Crosscheck_500/R/common.R'),
  prompts_sha256=mc_hash(file.path(mc_root,'protocol/prompts.json')),
  tasks_sha256=mc_hash(task_path),R_seed=p$run_seed),manifest_path)
cat('Prepared',nrow(tasks),'logical tasks; no API calls.\n')
