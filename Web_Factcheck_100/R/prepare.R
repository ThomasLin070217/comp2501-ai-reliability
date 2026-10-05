source('Web_Factcheck_100/R/common.R')
stopifnot(!file.exists(file.path(WROOT,'protocol/freeze.json')))
qs <- Filter(function(q)q$domain=='facts',read_jsonl('Followup_Validation/protocol/questions.jsonl'))
stopifnot(length(qs)==100,!anyDuplicated(field(qs,'question_id')))
set.seed(25011005);qs<-qs[sample(seq_along(qs))]
dir.create(file.path(WROOT,'protocol'),recursive=TRUE,showWarnings=FALSE)
write_jsonl(qs,file.path(WROOT,'protocol/questions.jsonl'))
cfg<-read_json('Followup_Validation/protocol/models.json')$minimax
write_json(cfg,file.path(WROOT,'protocol/model.json'))
write_json(list(system=WSYSTEM,tools=list(list(type='web_search_20250305',name='web_search')),
               tool_choice=list(type='tool',name='web_search')),file.path(WROOT,'protocol/prompt.json'))
files<-c('Web_Factcheck_100/R/common.R','Web_Factcheck_100/R/collect.R',
 'Web_Factcheck_100/protocol/questions.jsonl','Web_Factcheck_100/protocol/model.json',
 'Web_Factcheck_100/protocol/prompt.json','Followup_Validation/R/common.R',
 'Natural_Crosscheck/R/common.R','Math_Supplement/R/common.R','Peer_Misleading_Study/R/core.R')
write_json(list(frozen_at=now(),questions=100,repeats=1,concurrency=2,
 max_attempts=102,max_transport_retries=2,timeout_seconds=240,
 token_and_search_guard_cny=40,prior_paid_guard_cny=56.9192,
 guard_note='Input CNY20/M, output CNY50/M, search CNY0.08/call for conservative planning only. HKU cash pricing unknown; not invoice. Reservation is per request, not a hard server-side token limit.',
 next_request_reservation_cny=0.50,
 response_policy='No retry for wrong/abstaining/unscorable/truncated/no-search content. At most one retry per HTTP 502/503/504 or no-response transport failure, two globally.',
 comparison='Historical same-question MiniMax N0 and N1, repeated records first averaged within question. Not a randomized contemporaneous no-web control. New answers have one repeat.',
 search_policy='Native web_search explicitly requested through tool_choice; actual tool calls and results recorded. No-search responses remain in all-task outcome table and are separately flagged.',
 grading='Frozen vscore final answer field. correct/abstain are not errors; invalid and transport failure separate. No gold or previous answer sent to model.',
 source_doc='https://platform.minimax.io/docs/guides/server-tools',
 files_sha256=setNames(lapply(files,file_sha),files)),file.path(WROOT,'protocol/freeze.json'))
cat('Frozen 100 existing factual questions, one native-search answer each.\n')
