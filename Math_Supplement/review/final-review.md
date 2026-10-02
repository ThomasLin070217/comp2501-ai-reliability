# Additional CLI review (Kimi backend)

**Findings sorted by impact** (defects = wording or presentation errors that could mislead; limitations = disclosed constraints that the main text understates).

**1. Defect – Factual transition counts omit the conditioning denominator.**  
The C4→C5 paragraph states: *“There were 48 units correct in C4 but not C5, and 17 in the reverse direction. The net difference of 31 does not mean there were only 31 adverse cases.”* These counts are meaningful only among the **322 initially wrong units**, yet the sentence does not say so. A reader could apply them to the full 719-unit set and miscompute bases.  
*Fix:* Add the denominator: *“Among the 322 initially wrong units, 48 were correct in C4 but not C5, and 17 in the reverse direction.”*

**2. Defect – Math supplement states “no harmful flips” without qualifying the scoring scope.**  
The claim *“Consequently this supplement observes no harmful flips”* refers only to **final-field matching**. The semantic review finds that some corrected final fields still carry false explanations, and 13/16 baseline errors already stated the correct endpoint in the reason text. The unqualified phrasing risks overstating safety.  
*Fix:* Change to *“no final-field harmful flips”* or append *“(by final-field scoring only).”*

**3. Overlooked scoring limitation – Math wrong-to-correct counts lack the output-consistency caveat in the main results paragraph.**  
The results paragraph reports *“C4 reaches 71/71 and C5 70/71”* and the table shows 16/16 and 15/16 wrong-to-correct rates without noting that post-hoc reading found **13/16 baseline errors already contained the correct answer in the reason text**. A skimming reader can mistake these for pure reasoning repairs.  
*Fix:* Insert immediately after the counts: *“Post-hoc reading suggests many of these ‘corrections’ reflect output consistency rather than wholly revised reasoning; see semantic review.”*

**4. Defect – 17 unscorable responses vs. 7 excluded units is unexplained.**  
The report gives both numbers but never states whether the math supplement follows the factual protocol (one unscorable response excludes the entire seven-response unit) or how multiple failures concentrate. Without that link, the denominator arithmetic looks inconsistent.  
*Fix:* Add: *“These 17 unscorable failures are concentrated in 7 units; because one unscorable response excludes the whole unit, 49 total responses are removed from the main table.”*

**5. Defect – C3–C2 interval [-4.46, 0.00] is presented as a conventional two-sided bootstrap CI when the upper bound is mechanically pinned.**  
Because zero C3 harmful flips were observed, no resampled cluster contributes a positive difference, forcing the percentile upper bound to 0.00. Calling this a standard 95% interval without the boundary note can mislead readers about directional power.  
*Fix:* Append a parenthetical: *“(Upper bound is exactly 0 because no resampled cluster contains a C3 harmful flip.)”*

**6. Defect – Unscorable failure mode is vaguer in the report than in the semantic review.**  
The report lists *“12 missing required fields”*; the semantic review specifies *“12 omit the required solutions field.”* If the failure mode is that specific, the vaguer wording obscures the pattern and could imply unrelated field omissions.  
*Fix:* Align with the review: *“12 omitted the required `solutions` field.”*

**7. Defect – Mischaracterization of the LaTeX brace extraction failure.**  
The report calls it *“a correct JSON object whose surrounding LaTeX braces confuse the frozen extractor.”* The semantic review indicates the extractor miscounts LaTeX braces **inside** the JSON string (likely in the reason field), i.e., it fails to respect quoted string boundaries. *“Surrounding”* misplaces the cause on the model output rather than the parser.  
*Fix:* Change to *“a correct JSON object whose internal LaTeX braces are misclassified because the extractor does not fully respect quoted string boundaries.”*

**8. Mismatch to course requirement – Acknowledgements omit the student’s actual contributions.**  
`COURSE_REQUIREMENTS.md` explicitly requires students to *“describe their actual contributions and inspect all conclusions before submission.”* The acknowledgements disclose what Codex and Claude Code did, but state nothing about the student’s specific role (protocol design, manual source checks, analysis, etc.).  
*Fix:* Add a sentence describing the student’s concrete contributions, e.g., *“Thomas Lin designed the experimental protocol, performed the manual source checks, implemented the R analysis pipeline, and drafted the report.”*
