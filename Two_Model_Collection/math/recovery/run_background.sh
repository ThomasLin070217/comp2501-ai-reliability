#!/bin/sh
Rscript Two_Model_Collection/math/recovery/R/collect.R
recovery_exit_code=$?
printf '%s\n' "$recovery_exit_code" > Two_Model_Collection/math/recovery/runs/collector.exitcode
exit "$recovery_exit_code"
