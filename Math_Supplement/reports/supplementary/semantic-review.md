# Semantic and format review

This post-hoc, nonblind Codex screen reads the 161 targeted responses selected by the fixed review rule. It is not independent human annotation, and does not estimate whole-corpus reasoning error rates. Main final-field scores are unchanged.

**13 of 16 complete-unit baseline errors already state the correct endpoint in their reason, while the final conclusion/value/solutions field is wrong.** Two other reasons use correct kiwi setups but wrong additions; one misreads a consistent triangle. Thus the observed improvement largely includes output-consistency repair. It must not be sold as proof that 16 wholly incorrect mathematical derivations were repaired.

Several Kimi responses produce the right number while falsely saying that subtracting discarded fruit from Sunday before summing is logically different from subtracting it from the total. The two expressions are equivalent. Final-answer accuracy is therefore not full reasoning validity.

17 unscorable outputs: 12 omit the required solutions field, 3 contain two conflicting JSON objects, 1 has unquoted reason text, and 1 has a correct JSON object but the frozen brace extractor also counts LaTeX groups. This last limitation is a parser defect, not a model mathematical error. Main extraction remains frozen; the raw response and reason are retained. All-response diagnostics and strict-format sensitivity are separate from the main 71-unit table.

The original 13-item sample already misses the balanced viability criterion. These additional seven response-unit exclusions are separate and can bias aggregate comparisons. No paid reruns or replacement outputs were performed.

A useful classroom example is M-kiwi-1-control:kimi:r1:baseline: 36+47+(72-7) is correctly set up, then reported as 154 rather than 148. C0 fixes it. Another is M-triangle-1-control:deepseek:r1:baseline, whose reason says the conditions match while its final field says inconsistent.
