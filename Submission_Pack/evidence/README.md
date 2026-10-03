# Evidence exports by artifact version

The current 4 October integrated PPT/report uses **`integrated_*`** files. R reads the completed follow-up and the earlier controlled-study exports, retaining separate samples and denominators. `integrated_provenance.json` records source hashes; `integrated_R_session.txt` records software versions.

Files without that prefix, including `artifact_content.json`, `artifact_checks.json`, `visualization_data.json`, `budget_latest.json` and `natural_*`, belong to earlier artifact versions unless explicitly cited as the historical controlled-study input. They remain for provenance. Their page counts, natural-checking sample sizes and earlier cumulative costs do not describe the current integrated deliverables.

Current layout validation receipts and temporary renders remain in the ignored `.submission-build/integrated-20261004` directory. The reproducible checker is `Submission_Pack/validate_integrated.R`; it validates native chart values against R exports and confirms frozen experiment hashes without making model calls.
