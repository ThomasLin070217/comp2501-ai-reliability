# Frozen strict date scoring. Existing historical outputs/scoring are unchanged.
source('Followup_Validation/R/common.R')
fact_grade <- function(text,q,status='ok') {
 if(!identical(status,'ok'))return('unscorable')
 vscore(text,q)
}
# The final answer is scored at the question's reference granularity. Extra date
# precision does not change a year-only target. Insufficient precision and
# noncanonical/prose dates are unscorable, not automatically wrong or abstention.
# JSON answer/reason conflicts are reviewed separately, never silently repaired.
