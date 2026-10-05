suppressPackageStartupMessages({library(jsonlite);library(digest)})
source('Fact_Prompt_Design/R/prompts.R') # Same source wrappers for both domains.
source('Math_Prompt_Design/R/cases.R')
source('Math_Prompt_Design/R/verify_math.R')
math_system<-paste0('Solve the mathematics problem. Return only one JSON object. ',
 'Write "reason" first (a concise solution of at most 180 words), ',
 'then "abstain" (a boolean), and finally "answer" (a concise final answer string). ',
 'If you cannot determine the answer, use abstain=true and an empty answer. ',
 'Place the final answer after your solution, and ensure that they agree.')
root<-'Math_Prompt_Design'
dir.create(file.path(root,'generated'),recursive=TRUE,showWarnings=FALSE)
questions<-Filter(function(x)x$domain=='mathematics',lapply(readLines('Followup_Validation/protocol/questions.jsonl'),function(z)fromJSON(z,simplifyVector=FALSE)))
questions<-questions[order(vapply(questions,function(x)x$question_id,''))]
computations<-math_computations()
stopifnot(length(questions)==41,setequal(names(math_cases),vapply(questions,function(x)x$source_id,'')))
esc<-function(x){x<-gsub('&','&amp;',x,fixed=TRUE);x<-gsub('<','&lt;',x,fixed=TRUE);gsub('>','&gt;',x,fixed=TRUE)}
conditions<-c('neutral_initial','misconception_initial','self_check','A0_AI','A0_Human','A1_AI','A1_Human')
bundles<-list();references<-list();reviews<-list();cards<-character()
md<-c('# Mathematics prompt bank — 41 CHAMP questions','','LINYUNIAN · PAN ZHENGYU · 2026-10-05','',
 'Status: reviewed prompt design; no collection started. 287 condition definitions are not 287 model responses.',
 '', 'All 41 questions are prepared. The proposed 15-question mathematics mechanism subset is NOT selected here.',
 '', '## Shared system message','','```text',math_system,'```','',
 '## Conversation rules','',
 'Neutral and misconception initial prompts start separate new conversations. Models exchange A/B roles. Each follow-up continues its own copy of the SAME neutral B0 history, including B’s native search calls/results. Follow-ups are parallel, not consecutive.',
 '', 'Search tools are available without forcing search or supplying retrieved evidence. A0/A1 fields below are placeholders for the other model’s actual same-question/same-repetition response. Never replace them with a researcher-designed wrong answer. A1 may be correct or abstain.',
 '', 'Only the first line changes between AI and Human attribution. Keep actual reasoning, uncertainty, answer and abstention unchanged. Researcher-only reference panels and error annotations MUST NOT be sent to tested models.',
 '', 'A mathematical assertion such as “no minimum exists” is not an abstention. Three stimuli intentionally confuse infimum with minimum; two other targets are symbolic expressions. Review full answer semantics instead of extracting the last number. Correct intermediate numbers inside a wrong derivation are not automatically correct final answers.', '')
for(q in questions){
 c<-math_cases[[q$source_id]];v<-computations[[q$source_id]]
 stopifnot(isTRUE(all.equal(v$value,as.numeric(q$gold))),c$wrong_answer!=q$gold)
 symbolic<-!grepl('^-?[0-9]+(\\.[0-9]+)?$',c$wrong_answer)
 p<-list(neutral_initial=q$question,misconception_initial=misconception_prompt(q$question,c$wrong_answer,c$wrong_reason),
  self_check=review_suffix,A0_AI=peer_template('A0','ai'),A0_Human=peer_template('A0','human'),A1_AI=peer_template('A1','ai'),A1_Human=peer_template('A1','human'))
 bundles[[q$question_id]]<-list(question_id=q$question_id,system=math_system,question=q$question,prompts=p,
  needs_actual_donor=c('A0_AI','A0_Human','A1_AI','A1_Human'),mechanism_selected=NULL)
 references[[q$question_id]]<-list(question_id=q$question_id,family=q$family,reference_answer=q$gold,
  original_reference_solution=q$reference_solution,reviewed_argument=c$correct_argument,
  verification_type=c$verification,computation=v,source_url=q$source_url,researcher_only=TRUE)
 reviews[[q$question_id]]<-list(question_id=q$question_id,reviewer='Codex',question_preserved=TRUE,
  reference_matches=TRUE,wrong_answer=c$wrong_answer,wrong_reason=c$wrong_reason,error_location=c$error_location,
  explicit_non_numeric_wrong_target=symbolic,decision='prompt_and_mathematical_argument_review_pass',
  provenance='Author-designed false belief; not a historical model answer; no new model call.',
  scoring_note=if(symbolic)'Do not reduce the answer to a number or label a definite mathematical assertion as abstention. New semantic handling must be frozen before collection.' else 'Evaluate the final answer and separately flag reasoning/final-field contradictions.')
 md<-c(md,paste0('## ',q$question_id),'',paste0('Family: ',q$family),'',
  paste0('Researcher-only reference: **',q$gold,'**. Deliberately incorrect belief: **',c$wrong_answer,'**.'),'',
  paste0('Incorrect step: ',c$error_location),'',paste0('Reviewed correct argument: ',c$correct_argument),'',
  paste0('Verification: ',v$method),'',paste0('Source: ',q$source_url),'')
 for(k in conditions)md<-c(md,paste0('### ',k),'','```text',p[[k]],'```','')
 prompt_html<-paste(vapply(conditions,function(k)paste0('<h3>',k,'</h3><pre>',esc(p[[k]]),'</pre>'),''),collapse='')
 cards<-c(cards,paste0('<details class="item"><summary>',q$question_id,' — ',esc(q$question),'</summary>',
  '<aside><b>Researcher only — never send this panel to a model.</b><p>Reference answer: ',esc(q$gold),
  '<br>Assigned false belief: ',esc(c$wrong_answer),'</p><p><b>Incorrect step:</b> ',esc(c$error_location),
  '</p><p><b>Reviewed argument:</b> ',esc(c$correct_argument),'</p><p><b>Verification:</b> ',esc(v$method),
  '</p>',if(symbolic)'<p><b>Semantic scoring required:</b> this is a definite but false mathematical assertion, not an abstention or automatically a correct numeric answer.</p>' else '',
  '<a href="',q$source_url,'">Frozen CHAMP source</a></aside>',prompt_html,'</details>'))
}
writej<-function(x,p)jsonlite::write_json(x,p,pretty=TRUE,auto_unbox=TRUE,null='null',digits=NA)
writej(list(status='design_reviewed_not_collection_frozen',providers=c('minimax','deepseek'),no_model_calls=TRUE,
  repetitions_proposed=2,mechanism_subset_selected=FALSE,questions=unname(bundles)),file.path(root,'generated/model_prompts.json'))
writej(unname(references),file.path(root,'generated/researcher_reference.json'))
writej(unname(reviews),file.path(root,'generated/item_review.json'))
while(length(md)&&!nzchar(tail(md,1)))md<-head(md,-1)
writeLines(md,file.path(root,'generated/MATH_PROMPTS.md'),useBytes=TRUE)
html<-paste0('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">',
 '<title>COMP2501 · Mathematics prompt review</title><style>body{font:16px/1.6 system-ui,sans-serif;background:#f5f7fa;color:#173044;margin:0}main{max-width:1000px;margin:35px auto;padding:24px}h1{line-height:1.2}summary{cursor:pointer;font-weight:600;padding:18px}details{background:white;border:1px solid #d8e0e8;border-radius:8px;margin:12px 0}details>h3,details>pre,aside{margin:16px 20px}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#eef2f6;padding:15px;font-size:13px}aside{background:#fff7df;padding:14px}input{box-sizing:border-box;width:100%;padding:12px;font-size:16px}button{padding:9px;margin:10px 6px 10px 0}a{color:#215eb1}</style><main>',
 '<h1>Mathematics prompt bank</h1><p>41 CHAMP questions · 7 conditions each · MiniMax + DeepSeek</p>',
 '<p><b>Design only. No new model calls.</b> All original questions are preserved. Reference proofs, equality cases and computations are shown in yellow researcher-only panels. The proposed 15-question mechanism subset is not yet selected.</p>',
 '<p>The four peer conditions need actual donor outputs at runtime. All follow-ups start from parallel copies of the same B0 history. Symbolic and existence answers require semantic grading; a “no minimum” claim is not automatically an abstention.</p>',
 '<details><summary>Shared system prompt</summary><pre>',esc(math_system),'</pre></details>',
 '<input id="filter" placeholder="Filter by ID, question, mathematical error or answer" aria-label="Filter questions">',
 '<button onclick="document.querySelectorAll(\'.item\').forEach(e=>{if(!e.hidden)e.open=true})">Expand visible questions</button>',
 '<button onclick="document.querySelectorAll(\'.item\').forEach(e=>e.open=false)">Collapse all</button><span id="count">41 questions</span>',paste(cards,collapse='\n'),
 '<script>document.getElementById("filter").addEventListener("input",function(){const q=this.value.toLowerCase();let n=0;document.querySelectorAll(".item").forEach(e=>{e.hidden=!e.textContent.toLowerCase().includes(q);if(!e.hidden)n++});document.getElementById("count").textContent=n+" questions"})</script></main></html>')
writeLines(html,file.path(root,'generated/MATH_PROMPTS.html'),useBytes=TRUE)
inputs<-c('Followup_Validation/protocol/questions.jsonl','Followup_Validation/sources/reference_review.md',
 'Fact_Prompt_Design/R/prompts.R',paste0(root,'/R/',c('cases.R','verify_math.R','build.R','check.R')))
writej(list(date='2026-10-05',questions=41,condition_designs=287,reviewed_arguments=41,
 references_match=41,non_numeric_wrong_targets=sum(vapply(reviews,function(x)x$explicit_non_numeric_wrong_target,TRUE)),
 model_calls=0,proposed_math_mechanism_subset=15,mechanism_subset_selected=FALSE,
 limitations=c('Analytic certificates were reviewed by Codex, not a formal theorem prover or independent human.',
 'Bounded enumeration alone does not establish infinite-domain results.',
 'Original question wording and conventional domains/orientations are retained.',
 'Semantic scoring integration and provider-native collection are not completed by this prompt package.'),
 sha256=setNames(lapply(inputs,function(p)digest(file=p,algo='sha256')),inputs)),file.path(root,'generated/manifest.json'))
cat('Built 41 mathematics questions, 287 condition designs; 41 references match. No model calls.\n')
