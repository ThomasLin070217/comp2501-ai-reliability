# Mathematical baseline reasoning inspection

All 16 automatically incorrect, scorable N0 mathematical responses were read by Codex while the already-frozen branches continued. All 16 contain a substantive mathematical false step or logical inconsistency. None is classified as a completely correct displayed solution followed only by an incorrect answer field. This is a targeted AI inspection, not blind human annotation, and it does not validate all correct-number responses or unscorable outputs.

The corresponding raw outputs are in responses.csv and wrong_packet_*.md. Annotations are in codex_annotations.csv. Seven independent R arithmetic/enumeration checks are in exact_checks.json. Selection and collection were not changed in response to these results.

The 16 responses come from 11 questions, with repeated mistakes sharing the same mathematical structure. They are not 16 independent mathematical weaknesses. This initial-answer audit does not establish that cross-checking fixes them; that requires the later paired N1/N2 results.
