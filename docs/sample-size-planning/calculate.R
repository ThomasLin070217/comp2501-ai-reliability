# Planning scenarios, not an exact power calculation for the clustered two-model study.
# Run from repository root. No API calls and no observed effect used to choose N.
root <- 'docs/sample-size-planning'
q <- 0.20 # Assumed fraction of questions whose wrong/nonwrong status differs between methods.
power_target <- .80
out <- do.call(rbind,lapply(c(.05,.025),function(alpha){
 d <- c(.15,.10,.05)
 n <- ceiling((qnorm(1-alpha/2)*sqrt(q)+qnorm(power_target)*sqrt(q-d^2))^2/d^2)
 data.frame(alpha=alpha,power=power_target,assumed_discordance=q,difference_pp=100*d,
            independent_question_pairs=n)
}))
write.csv(out,file.path(root,'paired_binary_scenarios.csv'),row.names=FALSE)
counts <- data.frame(fact_questions=c(100,150,200),math_questions=c(41,50,100),models=2,repeats=2,
  fact_conditions=4,math_conditions=3)
counts$fact_answers <- with(counts,fact_questions*models*repeats*fact_conditions)
counts$math_answers <- with(counts,math_questions*models*repeats*math_conditions)
counts$total_answers <- counts$fact_answers+counts$math_answers
write.csv(counts,file.path(root,'record_counts.csv'),row.names=FALSE)
print(out);print(counts)
