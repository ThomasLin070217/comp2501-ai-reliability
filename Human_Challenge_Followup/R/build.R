source('Two_Model_Collection/R/runtime.R')
source('Two_Model_Collection/math/R/scoring.R')

root <- 'Human_Challenge_Followup'
dir.create(file.path(root, 'protocol'), recursive=TRUE, showWarnings=FALSE)
manifest <- list()
for (domain in c('facts', 'math')) {
  base <- file.path('Two_Model_Collection', domain)
  scores <- read.csv(file.path(base, 'recovery/derived/reports',
    if (domain == 'facts') 'semantic_sensitivity_records.csv' else 'semantic_final_responses.csv'),
    stringsAsFactors=FALSE)
  grade <- if (domain == 'facts') scores$semantic_grade else scores$final_semantic_grade
  scores <- scores[scores$condition == 'neutral_initial' & scores$status == 'ok' & grade == 'correct', ]
  if (domain == 'facts') {
    excluded <- read.csv(file.path(base, 'recovery/derived/reports/source_risk_excluded_questions.csv'))$question_id
    clean_ids <- setdiff(unique(scores$question_id), excluded)
  } else {
    clean_ids <- unique(read.csv(file.path(base,
      'recovery/derived/reports/source_exclusion_sensitivity/question_means.csv'))$question_id)
  }
  scores <- scores[scores$question_id %in% clean_ids, ]
  old <- tm_read(file.path(base, 'recovery/derived/runs/completed.jsonl'))
  by_id <- setNames(old, tm_fields(old, 'id'))
  prompts <- fromJSON(file.path(base, 'protocol/prompts.json'), simplifyVector=FALSE)$questions
  by_q <- setNames(prompts, tm_fields(prompts, 'question_id'))
  candidate_ids <- sort(unique(scores$question_id))
  eligible <- list()
  for (qid in candidate_ids) {
    rec <- list()
    for (provider in c('deepseek','minimax')) {
      s <- scores[scores$question_id == qid & scores$provider == provider, ]
      s <- s[order(s$repeat_id), ]
      s <- s[vapply(s$id, function(id) tm_usable(by_id[[id]]), TRUE), ]
      if (!nrow(s)) break
      rec[[provider]] <- s$id[1]
    }
    if (length(rec) != 2) next
    p <- by_q[[qid]]
    wrong <- p$prompts$misconception_initial
    pattern_match <- regexec('My current view is that the answer is (.*?)\\.\\nMy reason is: (.*)$',
      wrong, perl=TRUE)
    parts <- regmatches(wrong, pattern_match)[[1]]
    if (length(parts) != 3) next
    false_answer <- trimws(parts[2]); false_reason <- trimws(parts[3])
    if (domain == 'math') {
      ref <- fromJSON(file.path(base,'protocol/researcher_reference.json'),simplifyVector=FALSE)
      ref <- ref[[match(qid, tm_fields(ref,'question_id'))]]
      val <- math_numeric(false_answer)
      if (!is.finite(val) || abs(val-as.numeric(ref$reference_answer)) < 1e-9) next
    } else {
      q <- tm_read(file.path(base,'protocol/questions.jsonl'))
      q <- q[[match(qid,tm_fields(q,'question_id'))]]
      if (identical(trimws(false_answer),trimws(q$gold))) next
    }
    eligible[[qid]] <- list(question_id=qid,domain=domain,question=p$question,system=p$system,
      wrong_answer=false_answer,wrong_reason=false_reason,baselines=rec)
  }
  cat(domain, 'eligible after all filters:', length(eligible), '\n')
  stopifnot(length(eligible) >= 19)
  set.seed(if (domain == 'facts') 250110061 else 250110062)
  selected <- sample(sort(names(eligible)), min(20L,length(eligible)))
  manifest <- c(manifest, eligible[selected])
}
stopifnot(length(manifest)==39)
tasks <- list()
for (q in manifest) for (provider in c('deepseek','minimax')) for (arm in c('neutral','human_challenge')) {
  tasks[[length(tasks)+1L]] <- list(id=paste(q$domain,q$question_id,provider,arm,sep=':'),
    domain=q$domain,question_id=q$question_id,provider=provider,arm=arm,
    baseline_id=q$baselines[[provider]])
}
jsonlite::write_json(list(selection_seed=c(facts=250110061,math=250110062),
  criterion='Source-risk-clean questions with a previously verified correct native baseline from both models; first eligible repetition per model; 20 questions per domain selected with fixed seed.',
  estimand='Among correct initial answers, paired difference in wrong final-answer risk: simulated human challenge minus neutral reconsideration.',
  questions=manifest,tasks=tasks),file.path(root,'protocol/manifest.json'),
  pretty=TRUE,auto_unbox=TRUE,null='null',digits=NA)
cat('Frozen',length(manifest),'questions and',length(tasks),'paired follow-up calls.\n')
