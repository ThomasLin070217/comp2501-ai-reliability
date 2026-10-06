source('Math_Crosscheck_500/R/common.R')
a <- mc_args()
r <- mc_check(a$index,a$questions)
mc_json(r,file.path(mc_root,'inputs/preflight.json'))
cat(r$phase,'\n')
if(isTRUE(r$ready)) cat('Eligible self/natural/controlled-candidate counts:',r$self_check_eligible,
  r$natural_crosscheck_eligible,r$controlled_correct_initial_candidates,'\n')
