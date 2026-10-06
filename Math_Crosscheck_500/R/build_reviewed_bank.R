# Reproducible, pre-collection semantic review edition. Original bank is untouched.
suppressPackageStartupMessages({library(jsonlite); library(digest)})
src <- 'Reasoning_Math_500'; out <- 'Math_Crosscheck_500/question_review_v2'
q <- read.csv(file.path(src,'model_inputs_500.csv'),stringsAsFactors=FALSE,check.names=FALSE)
k <- read.csv(file.path(src,'scoring_key_500.csv'),stringsAsFactors=FALSE,check.names=FALSE)
stopifnot(nrow(q)==500L,identical(q$eval_id,k$eval_id))
original_q <- q; original_k <- k
changes <- list()
change <- function(i, type, evidence, text=NULL, answer=NULL) {
  if(!is.null(text)) q$input_text[i] <<- text
  if(!is.null(answer)) k$reference_answer[i] <<- as.character(answer)
  changes[[length(changes)+1L]] <<- data.frame(question_order=i,eval_id=q$eval_id[i],
    issue_type=type,original_question=original_q$input_text[i],reviewed_question=q$input_text[i],
    original_reference=original_k$reference_answer[i],reviewed_reference=k$reference_answer[i],
    rationale=evidence,stringsAsFactors=FALSE)
}
replace <- function(i,old,new,type,evidence) {
  stopifnot(grepl(old,q$input_text[i],fixed=TRUE))
  change(i,type,evidence,sub(old,new,q$input_text[i],fixed=TRUE))
}
replace(18,'an entire week','all 7 days of a week','clarification','30*7-100=110; specify days actually worked.')
replace(49,'but it expires','but it has already expired','ambiguity','Expired coupon cannot be redeemed; 8*5+8*3=64.')
replace(59,'a series of 22 matches','a series of 22 matches with no draws','missing_condition','With draws, W-L=8 and W+L+D=22 do not fix W. With D=0, W=15.')
replace(66,'2 times more shells than','twice as many shells as','ambiguity','Twice as many means 2*(20+5)=50; times more is ambiguous.')
replace(79,'at a profit of 25%','with the same 25% markup on the cost of each fruit type','missing_condition','Overall profit alone does not identify watermelon price: apple prices 1.25 or 1.50 imply watermelon prices 2 or 1.85. Uniform markup gives (80/50)*1.25=2.')
replace(81,'June worms','June bugs','entity_consistency','Use one name for the insects counted; (39+78+78+48+57)/5=60.')
# sub() changes one occurrence; unify the second one too.
q$input_text[81] <- gsub('June worms','June bugs',q$input_text[81],fixed=TRUE)
changes[[length(changes)]]$reviewed_question <- q$input_text[81]
change(87,'wrong_reference','The question specifies 6 existing teams, not 9 teams of 6. Additional teams=12-6=6.',answer=6)
change(110,'clarification','Explicit drop height avoids conventions about floor numbering; 72*(2/3)^2=32.',
 'Nathan has a ball that rebounds to 2/3 of its previous drop height on each bounce. He drops it from a mall balcony 72 feet above the ground. Each level is 24 feet tall. How high does it reach on its second bounce?')
change(117,'ambiguity','Group elapsed time and summed animal-hours differ. Define the sum: each kangaroo takes 6 hours, each turtle 12, four turtles total 48.',
 'Three kangaroos each cross a highway in 6 hours; their individual travel times sum to 18 hours. Two rabbits have individual travel times totaling 12 hours. Four turtles each travel at half a kangaroo\'s speed. What is the sum of the four turtles\' individual crossing times?')
change(130,'ambiguity','Both completed portions must fall inside the measured hour; 250+500=750.',
 'Teddy has three sets of 500-piece puzzles. During one hour, he places half the pieces of one puzzle and then all the pieces of another puzzle. How many puzzle pieces does he place during that hour?')
change(132,'clarification','Explicit equal allocation: 144/(6+4+2)=12.',
 'Monica has 6 presents for family, 4 for friends, and 2 for teachers. She uses all 144 inches of ribbon, divided equally among their bows. How many inches of ribbon does each bow receive?')
change(133,'ambiguous_scope','Pearls may themselves count as bracelet beads. Restrict the relatives\' comparisons and the requested count to metallic beads: 20+30+40=90.',
 'Adrianne\'s mother gives her 20 metallic beads and 15 pearls. Her sister gives her 10 more metallic beads than her mother did, and her friend gives her twice as many metallic beads as her mother did. How many metallic beads does Adrianne have altogether?')
change(134,'missing_condition','60 grams must be per cat per meal: 720/(3*2*60)=2 days.',
 'Imma has 3 cats and a parrot. Each cat eats 60 grams of cat food twice a day; the parrot eats 10 grams of bird food once a day. She has 720 grams of cat food and 200 grams of bird food. How many days will the cat food last?')
change(136,'wrong_reference','Forks are utensils and cannot be ignored: 24 cups+16 spoons-6 gifted spoons+48 forks=82.',answer=82)
change(139,'mislabelled_missing_information','Original three cages and other three cages undermine the claimed unknown cage count. Remove the guinea-pig cage count; total=30+5*g with g unspecified.',
 'A pet shop has several cages of rodents. Three cages each contain 10 hamsters. All the other cages each contain 5 guinea pigs, but their number is not given. How many rodents does the pet shop have in total?')
change(146,'missing_condition','Apple pie purchase is not stated in the original. Specify all purchased items: 20-2*2-8-1=7.',
 'Gus spends exactly $20 on 2 bags of chips at $2 each, a bucket of fried chicken at $8, a bottle of soda at $1, and one apple pie. These are his only purchases. He finds $10 on his way home. How much does the apple pie cost?')
replace(154,'6 times greater than','6 times as far as','ambiguity','Tuesday=6*4=24; Wednesday=41-4-24=13.')
change(170,'ambiguity','Times older is ambiguous; explicit age multipliers give 3*2*4=24.',
 'Caroline is three times as old as Ben, who has a 2-year-old sister. Ben is twice as old as Chris. If Chris is 4 years old, how old is Caroline?')
change(186,'reference_and_scope','Original half-of-remainder then equal split does not support source10. Clarify that only half of20 is sold across these two periods:10/2=5.',
 'A bakery produces 60 loaves each day, priced at $5 each. Two-thirds are sold in the morning. Of the remaining loaves, half are sold later and half remain unsold. The loaves sold later are split equally between afternoon and evening sales. How many loaves are sold in the afternoon?',answer=5)
replace(189,'a different direction','opposite directions along the same straight track','ambiguity','The sum-speed distance applies only to opposite collinear travel: (60+30)*3=270.')
replace(193,'Stetson ate 2/5 of the oranges they picked','Stetson ate no apples and ate 2/5 of the oranges they picked','missing_condition','Unspecified apple consumption makes total payment unknown. With no apples, 60*(2/5)*10=240.')
change(217,'entity_consistency','Dennis/Denise and Danyll/Daniel are inconsistent names. Compare the same two readers across both days: 10+18-13=15.',
 'Dennis and Daniel are reading the same book. Yesterday Dennis read 10 pages and Daniel read 13. Today Dennis reads 5 more pages than Daniel did yesterday, and Daniel reads none. Across these two days, how many more pages did Dennis read than Daniel?')
replace(220,'three times larger than','three times as large as','ambiguity','Timothy=3*18=54; Sarah=27.')
replace(228,'100 pages to the inch','100 sheets to the inch','unit_mismatch','Pages and sheets differ: 1.5*100 sheets*2 pages per sheet=300.')
replace(241,'in a month','in a four-week month','clarification','A calendar month is not uniformly four weeks; explicit duration gives 2*30*4=240.')
replace(247,"There's a 2% interest rate applied to each device.","A one-time 2% charge is applied to each device's price.",'ambiguity','Specify total one-time charge rather than monthly compounding: 5*150*1.02/3=255.')
change(254,'entity_consistency','Jason and RJ are inconsistent names. Use one name for the fourth owner: (8+10+1+5)/4=6.',
 'Nick, Richard, Jason, and DJ each have paintball guns. DJ has 8 guns, four of which are blue; Nick has 10, Jason has 1, and Richard has 5. If they share all their guns equally, how many guns does each get?')
replace(260,'twice the number of boys','twice as many boys as girls','missing_comparison','Explicit reference group: boys=2*6, children=6+12=18; adults are excluded.')
change(286,'ambiguous_scope','Original target could mean Steve alone (14 vines). For both people: (6+3)*7/3=21.',
 'Steve eats 6 cherry tomatoes per day, twice as many as his girlfriend. He also eats 20 cherries a day. Each tomato vine produces 3 tomatoes per week. How many vines does he need to supply all the tomatoes eaten by both himself and his girlfriend?')
change(290,'wrong_reference','Geb is younger by 26/2-10=3 years; Geb\'s actual age is 26-3=23.',answer=23)
replace(293,'Jean is two years older than Mark.','Jean and Jan are different people. Jean is two years older than Mark.','entity_consistency','Clarify Jan is not a typo for Jean; Jan\'s age is missing, so Jean cannot be determined.')
replace(306,'and has 10 more than Richard','and has 10 more cherries than Richard','ambiguous_scope','Specify cherries rather than total fruit: Richard20, Jerry10, Robert-Jerry20.')
replace(313,'and the remaining oranges','with these three groups not overlapping, and the remaining oranges','clarification','Without non-overlap, spoiled/sour/unripe counts can overlap; 25-1-5-2=17.')
replace(336,'Peter, Paul, and Jean','Peter, Paul, and John','entity_consistency','Jean/John mismatch creates an unconstrained fourth person. With John throughout, Peter=100/2=50.')
replace(341,'1/3 red of his shoeboxes','1/3 of his red shoeboxes','ambiguity','Use 3 blue and 3 red, leaving (7-3)+(9-3)=10.')
change(353,'ambiguous_event_and_unit','Six-roll event and relative percentage are ambiguous. Define single-roll and first-two-roll events; 50%-25%=25 percentage points.',
 'Jerry rolls a fair six-sided die six times. Compare the probability that the first roll is greater than 3 with the probability that the first two rolls are both even. How much larger is the first probability, in percentage points?')
change(357,'wrong_reference','During the stated hour Ezra300 and Ahmed150; an additional150 for Ezra makes 600, not675. Specify the time boundary; avoid assigning an unstated additional75 to Ahmed.',
 'During one hour Ezra reads 300 books, twice as many as Ahmed reads during that hour. After that hour Ezra reads another 150 books, while Ahmed reads no more. How many books have they read in total?',answer=600)
replace(376,'How many fish were they able to catch?','How many animals were they able to catch in total?','mislabelled_missing_information','Starfish are not fish. Counting fish alone yields 17 without knowing starfish; counting all animals correctly requires the missing starfish count.')
replace(392,'a bulk of 48 trainers','48 pairs of trainers','unit_mismatch','Inventory and sales must both count pairs: 17*20+31*25-576=539.')
change(403,'inconsistent_process','Depleted ink cannot create pens. State residual-ink recycling and repeated recycling: 25+5+1=31 usable pens over time.',
 'Ram buys 25 pens. After normal use, each pen retains a little ink. Combining the leftover ink from 5 used pens makes one full pen. He uses and recycles the new pens by the same rule. How many full pens can he use in total, including the original 25?')
replace(412,'a bull that has a weight of 750kg','750kg of saleable meat from a bull','missing_condition','Live weight is not saleable meat weight; explicit saleable weight gives 750/(15*10)=5 days.')
replace(431,"five times greater than her turtle's speed","five times as fast as her turtle",'ambiguity','Turtle speed=15/5=3 feet/s, distance=120.')
change(442,'wrong_reference','The source omits the discounted CD player. Total cost=(10*15+75)*0.6=135; resale revenue40, net outlay95. Specify resale total.',
 'James buys 10 CDs at a list price of $15 each and a CD player at a list price of $75. All items are discounted by 40%. He resells 5 CDs for $40 in total. What is his net cash outlay after the resale?',answer=95)
change(456,'wrong_reference','The current total after receiving marbles is explicitly 60. Losing 10 leaves 50; do not subtract from the pre-gift 36.',answer=50)
change(463,'background_convention','Basketball quarters conventionally imply four periods. Use a game with an explicitly unspecified period count so insufficient information is defensible.',
 'Sarah\'s game consists of an unspecified number of periods, each 12 minutes long. A tie at the end adds 5 minutes of overtime. How long does the entire game last?')
replace(468,'their offspring','their one child','missing_condition','Offspring does not identify the number of children. Two adults, one child and popcorn cost 24+8+6=38.')
replace(469,'Ethal','Ethel','entity_consistency','Standardize the name; Jimmy=2*8+2=18.')
replace(478,'4 times that amount on Friday and half the amount of his Friday\'s catch on Saturday','4 times as much of each species on Friday and half as much of each species as on Friday on Saturday','ambiguous_scope','A combined catch multiplier does not fix species mix. Explicit species-wise multipliers yield crawfish3+12+6=21 pounds, 7 servings.')
replace(482,'each hour after that is twice the cost','each subsequent paid hour costs twice the first paid hour','ambiguity','Recursive doubling gives105, while source intends fixed30 for each later hour:15+30+30=75.')
change(488,'clarification','Specify sequential operations instead of overlapping:90/6+90/(30/10)=45 minutes.',
 'Emily peels 6 shrimp per minute and sautes 30 shrimp in 10 minutes. She drinks coffee every 15 minutes without interrupting cooking. She has 90 shrimp and 3 cups of coffee. If she peels all the shrimp before cooking them, how many minutes does peeling and cooking take?')
replace(500,'three times more hot dogs than','three times as many hot dogs as','ambiguity','Thomas6, John3, John-Luke1; times more is ambiguous.')
rev <- do.call(rbind,changes)
stopifnot(!anyDuplicated(rev$question_order),all(nchar(q$input_text)<=300L),
          sum(k$answer_kind=='numeric')==350L,sum(k$answer_kind!='numeric')==150L,
          !anyDuplicated(q$input_text))
k$original_reference_answer <- original_k$reference_answer
k$original_source_solution <- original_k$source_solution
k$review_basis <- 'AI semantic screening plus pinned-source arithmetic validation; no independent human validation'
k$reviewed_solution <- k$source_solution
for(j in seq_len(nrow(rev))) {
  i <- rev$question_order[j]
  k$reviewed_solution[i] <- rev$rationale[j]
  k$review_basis[i] <- paste('AI pre-collection repair:',rev$issue_type[j])
}
# source_solution remains original source evidence; never silently rewrite it.
k$question_chars <- nchar(q$input_text)
k$max_number_in_question <- vapply(q$input_text,function(s) {
  z <- regmatches(s,gregexpr('[0-9][0-9,]*(\\.[0-9]+)?',s,perl=TRUE))[[1L]]
  if(!length(z)) return(0)
  max(as.numeric(gsub(',','',z,fixed=TRUE)))
},0.0)
stopifnot(all(k$max_number_in_question<=1000))
ledger <- data.frame(question_order=q$question_order,eval_id=q$eval_id,
  review_status=ifelse(q$question_order %in% rev$question_order,'repaired_before_collection','screened_no_clear_issue'),
  reference_answer=k$reference_answer,reviewer='Codex AI-assisted review',review_date='2026-10-06',
  scope='All 500 full questions and references read; source arithmetic checked; repairs individually reasoned',
  stringsAsFactors=FALSE)
first <- q[k$planned_batch=='first_100',]
stopifnot(nrow(first)==100L,identical(as.integer(table(factor(k$perturbation_type[k$planned_batch=='first_100'],
  levels=c('distraction insertion','critical thinking','problem understanding')))),c(40L,30L,30L)))
dir.create(out,recursive=TRUE,showWarnings=FALSE)
for(n in c('model_inputs_500','scoring_key_500','first_batch_100','revisions','review_ledger')) {
  obj <- switch(n,model_inputs_500=q,scoring_key_500=k,first_batch_100=first,revisions=rev,review_ledger=ledger)
  write.csv(obj,file.path(out,paste0(n,'.csv')),row.names=FALSE,na='')
}
files <- c(file.path(src,c('model_inputs_500.csv','scoring_key_500.csv','selection_manifest.json')),
           file.path(out,c('model_inputs_500.csv','scoring_key_500.csv','first_batch_100.csv','revisions.csv','review_ledger.csv')))
write_json(list(edition='review_v2_2026-10-06',reviewer='Codex AI-assisted; not independent human review',
  n_questions=500L,changed_items=nrow(rev),changed_questions=sum(rev$original_question!=rev$reviewed_question),
  changed_keys=sum(rev$original_reference!=rev$reviewed_reference),
  no_model_requests=TRUE,license='CC BY-SA 4.0; adapted from GSM-Plus v1',
  sha256=setNames(as.list(vapply(files,function(p)digest(file=p,algo='sha256'),'')),files)),
  file.path(out,'review_manifest.json'),auto_unbox=TRUE,pretty=TRUE)
cat('Reviewed 500; repaired',nrow(rev),'items; changed',sum(rev$original_reference!=rev$reviewed_reference),'keys.\n')
