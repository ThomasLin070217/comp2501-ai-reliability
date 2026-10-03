# Pre-call reference review

Codex read the complete reference solutions for the initially sampled 45 CHAMP problems before any new experimental model call. This is an AI reference review, not independent human verification. Selection does not use the upstream model conversations or error labels.

Excluded without replacement:

- P_Sequence_33: the requested ratio is 1/8, while the answer field says 8; its own derivation says 1/8. Direct substitution in the R offline test confirms this.
- P_Sequence_10: direct recurrence modulo four yields 2 at index 1964, whereas the source answer says 3. Verified by R through the requested index.
- P_Inequality_7 and P_Inequality_22: the stated maximum is attained in the provided proof only at a zero-length triangle side. The positive-versus-zero-length interpretation of “possibly degenerate” is insufficiently explicit for an unambiguous grading reference.

The remaining 41 final reference answers passed this reading. Some **reference explanations**, however, have errors or typographical slips. Keep the originals and use these explicit notes when inspecting model reasoning:

- P_Inequality_4: set t=sqrt(x^2+1)>=1. The expression is t+1/t>=2 with equality x=0. The source's intermediate '=1' is a typo, not the bound.
- P_Inequality_13: a^2+b^2+c^2-ab-bc-ac is half the sum of squared pairwise differences. Subtracting a+b+c=9 gives lower bound -9, attained at a=b=c=3. Ignore the malformed intermediate product in the source.
- P_Number-Theory_71: the difference is coprime to 2,3,5, excluding magnitudes 0,2,3,4,5,6. The equation 12^m-5^n=1 is impossible modulo 4. For 5^n-12^m=1, modulo 3 implies n=2k. Then (5^k-1)(5^k+1)=2^(2m)3^m. The second factor has exactly one factor of 2; at most one factor contains 3. If the second contains no 3 it equals 2, impossible for k>0. Otherwise they are 2^(2m-1) and 2*3^m; their difference 2 implies 3^m-4^(m-1)=1, impossible modulo 3. Magnitude 7 is attained at m=n=1. The source's factorization of 12^m-1 as (6^m-1)(6^m+1) is wrong and must not be used.
- P_Polynomial_1: for the given f, f(1)=f'(1)=0, so (x-1)^2 divides f and remainder is zero. The derivative of the quotient-product in the source omits a prime, but this does not affect the correct direct argument.
- P_Polynomial_40: put a=1+u, b=1+v. The expression becomes u^2+uv+v^2-3, whose minimum is -3 at u=v=0. The source's intermediate expanded sign is inconsistent.
- P_Polynomial_17: continuity implies g(x)=f(x)-x has a constant nonzero sign. In either case applying the same inequality at f(x) excludes f(f(x))=x. The source's 'f(x)<0' should read 'f(x)-x<0'.
- P_Polynomial_11: use s_n=6*s_(n-1)-s_(n-2), with s_0=2,s_1=6, not an exponent. Modulo 5 the period is (2,1,4,3,4,1); the 60 requested indices include 20 occurrences of 4.
- P_Sequence_21: n=0 gives a_(2m)=4*a_m; m=n gives a_0=0; using m=n+2 yields a_(n+2)=2*a_(n+1)-a_n+2. With a_1=1 this determines a_n=n^2. The source's final induction notation is malformed.

P_Combinatorics_20 (the monomino/L-triomino tiling problem) also has an independent exact R enumeration in the offline tests, returning 87. These checks establish the listed final values and correct arguments; they do not certify every original reference sentence.

Some problems share structures across category labels, notably Fibonacci-type tilings/subsets/adjacent permutations and stars-and-bars counting. Statistical interpretation must retain this limitation; broad mathematical population claims are inappropriate.
