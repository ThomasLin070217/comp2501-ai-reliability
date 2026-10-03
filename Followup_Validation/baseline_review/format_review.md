# Completed baseline outputs missed by the frozen format rules

Codex read all ten status-ok mathematical N0 responses that the frozen parser marked unscorable. Five have a clear correct final answer; five have a clear wrong final answer. This is a separate post-hoc semantic sensitivity, not a change to the frozen grades. Other baseline unscorable responses were incomplete or transport failures and are not silently recovered.

The parser accepts a numeric answer string, but does not recognize strings such as a = -5 or 7744 = 88²; malformed JSON and plain-text answers also fail its rules. Some nonnumeric answers, such as n(n-1), are substantive wrong conclusions rather than mere encoding issues. Both directions must be retained.

This also affects availability: an invalid N0 object prevents some later branches from being requested. Re-reading its meaning cannot reconstruct those uncollected branches. Bounds and skipped-input records remain necessary.
