suppressPackageStartupMessages({library(jsonlite);library(digest)})
root <- 'Fact_Prompt_Design'
source(file.path(root,'R/prompts.R'))
source(file.path(root,'R/overrides.R'))
read_jsonl <- function(p) lapply(readLines(p,warn=FALSE),function(z)fromJSON(z,simplifyVector=FALSE))
write_json <- function(x,p) jsonlite::write_json(x,p,auto_unbox=TRUE,pretty=TRUE,null='null',digits=NA)
questions <- Filter(function(x)x$domain=='facts',read_jsonl('Online_Replication/protocol/questions.jsonl'))
questions <- questions[order(vapply(questions,function(x)x$question_id,''))]
materials <- fromJSON('Peer_Misleading_Study/data/main_frozen/materials.json',simplifyVector=FALSE)
old_concerns <- read_jsonl('Online_Replication/protocol/historical_reference_concerns.jsonl')
stopifnot(length(questions)==100L)
dir.create(file.path(root,'generated'),recursive=TRUE,showWarnings=FALSE)
esc <- function(x) {x<-gsub('&','&amp;',x,fixed=TRUE);x<-gsub('<','&lt;',x,fixed=TRUE);gsub('>','&gt;',x,fixed=TRUE)}
conditions <- c('neutral_initial','misconception_initial','self_check','A0_AI','A0_Human','A1_AI','A1_Human')
fresh <- list(
 SV0618=list(status='reference_supported',url='https://museum.seiko.co.jp/en/seiko_history/milestone/milestone_07/',finding='Seiko museum identifies its Olympic timing role in Tokyo in 1964.'),
 SV1016=list(status='stimulus_plausibility_check',url='https://raeng.org.uk/about-us/history',finding='Academy began in 1976; the assigned 1975 is an easily falsified stimulus. This page alone does not verify Rowlinson membership.'),
 SV1808=list(status='reference_supported',url='https://en.npc.gov.cn.cdurl.cn/pdf/civilcodeofthepeoplesrepublicofchina.pdf',finding='Article 1260 sets entry into force and simultaneous repeal of the Contract Law on January 1, 2021.'),
 SV1857=list(status='reference_not_resolved_by_fresh_check',url='https://zildjian.com/pages/brand',finding='Manufacturer brand page retrieval does not independently resolve the first-creation versus company-founding distinction.')
)
bundles<-list();reference<-list();audit<-list();md<-c('# Fact-check prompt bank — 100 questions',
 '', 'Status: prompt design reviewed; not a collection freeze. No new model responses were collected.',
 '', 'All text sent to tested models is in English. Researcher-only references and warnings are NOT model inputs.',
 '', '## Shared system message', '', '```text',fact_system,'```','',
 '## Conversation rules','',
 'Neutral initial and misconception initial each start a new conversation. Both models use identical wording. A is the donor and B the receiver; exchange their roles. Each repetition starts from new independent initial conversations.',
 '', 'Each review branch clones the SAME B0 conversation, including its own native search history. Self-check and the four peer branches are parallel, not sequential. Do not prepend a second copy of the original question to a follow-up.',
 '', 'A0/A1 placeholders must be filled only with the matching other model’s actual answer, boolean abstention and reason from the same question/repetition. A1 may be correct or abstain. Never insert the assigned wrong answer as if it were a real model response.',
 '', 'Search tools are available through the API configuration. No prompt forces or bans searching, and no researcher-provided sources are sent. Keep no-search answers. Provider adapters and paid collection are outside this design-only package.',
 '', 'All 100 items have a mechanism design, but this does NOT authorise expanding the proposed 25-fact mechanism subset to all 100. Subset selection remains pending.', '')
cards<-character()
for(q in questions) {
 id<-q$question_id;key<-paste0(id,':deepseek:wrong');old<-materials[[key]]
 stopifnot(!is.null(old),identical(old$answer,q$false_target))
 revised<-id%in%names(reason_overrides)
 reason<-if(revised)reason_overrides[[id]] else old$explanation
 p<-list(neutral_initial=q$question,
         misconception_initial=misconception_prompt(q$question,q$false_target,reason),
         self_check=review_suffix,A0_AI=peer_template('A0','ai'),A0_Human=peer_template('A0','human'),
         A1_AI=peer_template('A1','ai'),A1_Human=peer_template('A1','human'))
 bundles[[id]]<-list(question_id=id,system=fact_system,question=q$question,prompts=p,
    needs_actual_donor=c('A0_AI','A0_Human','A1_AI','A1_Human'),mechanism_selected=NULL)
 reference[[id]]<-list(question_id=id,reference_answer=q$gold,reference_parts=q$gold_parts,
   granularity=q$granularity,assigned_wrong_answer=q$false_target,assigned_wrong_parts=q$false_parts,
   source_urls=q$source_urls,previous_verified_url=q$verified_source_url,
   reference_status='inherited_reference_not_new_full_web_adjudication',fresh_check=fresh[[id]],
   researcher_only=TRUE)
 note<-if(id%in%names(revision_notes))revision_notes[[id]] else if(revised)
   'Replace unsupported specifics or an overconfident record claim with a topic-specific remembered belief; preserve the original event and assigned date.' else
   'Retain the historical explanation as a deliberately incorrect stimulus; plausibility is not evidence and is not guaranteed to persuade.'
 warning<-if(id%in%names(prompt_cautions))prompt_cautions[[id]] else ''
 audit[[id]]<-list(question_id=id,reviewer='Codex',review_type='prompt_semantics_and_design_consistency',
   question_preserved=TRUE,target_preserved=TRUE,old_material_key=key,old_reason=old$explanation,
   final_reason=reason,reason_revised=revised,decision=if(nzchar(warning))'usable_design_with_caution' else 'prompt_review_pass',
   review_note=note,caution=warning,reference_scope='Inherited reference and false date parts checked; only explicitly logged items received fresh external checks.')
 md<-c(md,paste0('## ',id),'',paste0('Researcher-only reference: **',q$gold,'**. Assigned incorrect belief: **',q$false_target,'**.'),'',
   paste0('Review: ',note),if(nzchar(warning))paste0('\nCaution: ',warning) else '',
   paste0('\nReference links: ',paste(unlist(q$source_urls),collapse=' | ')),'')
 for(c in conditions)md<-c(md,paste0('### ',c),'','```text',p[[c]],'```','')
 prompts_html<-paste(vapply(conditions,function(c)paste0('<h3>',c,'</h3><pre>',esc(p[[c]]),'</pre>'),''),collapse='')
 cards<-c(cards,paste0('<details class="item"><summary>',id,' — ',esc(q$question),'</summary>',
   '<aside><b>Researcher only.</b> Reference: ',esc(q$gold),'; assigned false belief: ',esc(q$false_target),
   '<p>',esc(note),'</p>',if(nzchar(warning))paste0('<p><b>Caution:</b> ',esc(warning),'</p>') else '',
   '<p>',paste(vapply(unlist(q$source_urls),function(u)paste0('<a href="',u,'">Reference source</a>'),''),collapse=' · '),
   '</p></aside>',prompts_html,'</details>'))
}
write_json(list(status='design_reviewed_not_collection_frozen',providers=c('minimax','deepseek'),repetitions_proposed=2,
  no_model_calls=TRUE,all_mechanism_questions_designed=100,mechanism_subset_selected=FALSE,
  source_attribution_only_changes_header=TRUE,questions=unname(bundles)),file.path(root,'generated/model_prompts.json'))
write_json(unname(reference),file.path(root,'generated/researcher_reference.json'))
write_json(unname(audit),file.path(root,'generated/item_review.json'))
while(length(md)&&!nzchar(tail(md,1)))md<-head(md,-1)
writeLines(md,file.path(root,'generated/FACT_PROMPTS.md'),useBytes=TRUE)
html<-paste0('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">',
 '<title>COMP2501 · Fact-check prompt review</title><style>body{font:16px/1.6 system-ui,sans-serif;background:#f5f7fa;color:#173044;margin:0}main{max-width:1000px;margin:35px auto;padding:24px}h1{line-height:1.2}summary{cursor:pointer;font-weight:600;padding:18px}details{background:white;border:1px solid #d8e0e8;border-radius:8px;margin:12px 0}details>h3,details>pre,aside{margin:16px 20px}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#eef2f6;padding:15px;font-size:13px}aside{background:#fff7df;padding:14px}input{box-sizing:border-box;width:100%;padding:12px;font-size:16px}button{padding:9px;margin:10px 6px 10px 0}a{color:#215eb1}</style><main>',
 '<h1>Fact-check prompt bank</h1><p>100 questions · 7 condition designs each · MiniMax + DeepSeek</p>',
 '<p><b>Design only. No new model calls.</b> All 100 mechanism prompts are prepared; the proposed 25-question factual mechanism subset is not yet selected. The four peer prompts require actual donor outputs at runtime.</p>',
 '<p>Yellow panels contain researcher-only references, intentionally false target dates, and review notes. Never send those panels to a tested model. Follow-ups continue separate copies of the same B0 history, including its search history.</p>',
 '<details><summary>Shared system prompt</summary><pre>',esc(fact_system),'</pre></details>',
 '<input id="filter" placeholder="Filter by question ID, topic, date or text" aria-label="Filter questions">',
 '<button onclick="document.querySelectorAll(\'.item\').forEach(e=>{if(!e.hidden)e.open=true})">Expand visible questions</button>',
 '<button onclick="document.querySelectorAll(\'.item\').forEach(e=>e.open=false)">Collapse all</button><span id="count">100 questions</span>',
 paste(cards,collapse='\n'),'<script>document.getElementById("filter").addEventListener("input",function(){const q=this.value.toLowerCase();let n=0;document.querySelectorAll(".item").forEach(e=>{e.hidden=!e.textContent.toLowerCase().includes(q);if(!e.hidden)n++});document.getElementById("count").textContent=n+" questions"})</script></main></html>')
writeLines(html,file.path(root,'generated/FACT_PROMPTS.html'),useBytes=TRUE)
inputs<-c('Online_Replication/protocol/questions.jsonl','Peer_Misleading_Study/data/main_frozen/materials.json',
 'Online_Replication/protocol/historical_reference_concerns.jsonl',paste0(root,'/R/',c('prompts.R','overrides.R','build.R','check.R')))
write_json(list(date='2026-10-05',questions=100,condition_designs=700,revised_reasons=sum(vapply(audit,function(x)x$reason_revised,TRUE)),
   fresh_external_check_entries=length(fresh),full_fresh_reference_adjudication=FALSE,model_calls=0,
   proposed_fact_mechanism_subset=25,mechanism_subset_selected=FALSE,
   sha256=setNames(lapply(inputs,function(p)digest(file=p,algo='sha256')),inputs)),file.path(root,'generated/manifest.json'))
cat('Built',length(bundles),'questions, 700 condition designs;',sum(vapply(audit,function(x)x$reason_revised,TRUE)),'reasons revised. No model calls.\n')
