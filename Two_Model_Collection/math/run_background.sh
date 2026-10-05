#!/bin/sh
# Run from the repository root; launched with nohup by the coordinator.
Rscript Two_Model_Collection/math/R/run.R
math_exit_code=$?
printf '%s\n' "$math_exit_code" > Two_Model_Collection/math/runs/collector.exitcode
exit "$math_exit_code"
