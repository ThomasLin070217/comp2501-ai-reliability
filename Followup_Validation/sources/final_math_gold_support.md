# Compact support for the 41 retained mathematical answer keys

This is an additional Codex mathematical check written during collection, after the source review and after inspection of N0 mistakes. It does not change the frozen selection, reference keys, prompts or primary grades. These are transparent mathematical arguments, not independent human validation. Original source proofs and their pre-call corrections remain available separately. R exact checks for selected counting and arithmetic claims are in `../baseline_review/exact_checks.json`.

## Combinatorics

| Source ID | Answer | Key justification |
|---|---:|---|
| P_Combinatorics_40 | 144 | Domino tilings satisfy T(n)=T(n−1)+T(n−2), T(0)=T(1)=1, so T(11)=144. The first column is covered by one vertical domino or two horizontal dominoes. |
| P_Combinatorics_21 | 30 | Six distinct colors give 6! face assignments. Each orbit has 24 elements because no nonidentity cube rotation fixes all six differently colored faces. Thus 720/24=30. |
| P_Combinatorics_20 | 87 | Exact enumeration places a monomino or each legal L-triomino at the first uncovered cell. The frozen R test counts each complete tiling once, yielding 87. |
| P_Combinatorics_38 | 240 | Choose 2 boys and 1 girl, or 3 boys, then assign three distinct toys: [choose(4,2)·6+choose(4,3)]·3!=240. Each selected child receives one toy. |
| P_Combinatorics_5 | 144 | Binary strings of length 10 with no adjacent ones satisfy S(n)=S(n−1)+S(n−2), S(0)=1, S(1)=2. |
| P_Combinatorics_30 | 2001000 | Nonnegative exponent triples sum to 1999; stars and bars gives choose(2001,2). All multinomial coefficients are positive. |
| P_Combinatorics_18 | 5050 | Nonnegative triples summing to 99 number choose(101,2). |
| P_Combinatorics_7 | 144 | On a line, the leftmost child either stays or swaps with the adjacent child. This gives T(11)=144; exact permutation counting independently agrees. |
| P_Combinatorics_31 | 120 | Three identical cookies among eight distinct dogs correspond to nonnegative solutions of a sum equal to 3: choose(10,7)=120. |

## Inequalities: both a bound and an attaining point

- **P_Inequality_49 = 0.** Let A=x+y−z, B=x−y+z, C=−x+y+z. Triangle inequalities for A+B, A+C, B+C give 2(|A|+|B|+|C|)≥2(|x|+|y|+|z|). Equality is attained at x=y=z=0.
- **P_Inequality_8 = 0.** Write P=∏x_j. For each i, AM–GM applied to n+1 positive terms (two copies of x_i^(n+1) and one copy of every other x_j^(n+1)) gives P·x_i≤[2x_i^(n+1)+∑_(j≠i)x_j^(n+1)]/(n+1). Sum over i. Equality occurs when all x_i equal any common positive value.
- **P_Inequality_4 = 2.** With t=√(x²+1)≥1, the expression is t+1/t≥2, attained at x=0.
- **P_Inequality_24 = 0.** The expression factors as ab(a+b)(a−b)²≥0 for a,b>0. Equality at a=b>0.
- **P_Inequality_13 = −9.** The expression is [(a−b)²+(b−c)²+(a−c)²]/2−9. Equality at a=b=c=3 satisfies the constraint.
- **P_Inequality_15 = 0.** Weighted AM–GM gives a²bc≤(2a⁴+b⁴+c⁴)/4, with the two cyclic analogues. Their sum is at most a⁴+b⁴+c⁴. Equality at a=b=c>0.
- **P_Inequality_26 = 0.** Set x=|a|, y=|b|, z=|a+b|. Multiplication by the positive denominator (1+x)(1+y)(1+z) gives z−x−y−2xy−xyz≤0 because z≤x+y. Equality at a=b=0.

## Number theory

- **P_Number-Theory_24 = 0.** Direct modular exponentiation gives (2^32+1) mod 641=0; these integers are exactly representable in R doubles.
- **P_Number-Theory_27 = 0.** The R recurrence r←(10r+2) mod 1982, repeated 1980 times, gives zero without representing the enormous integer. It agrees with the modulo-991 Fermat argument plus evenness.
- **P_Number-Theory_71 = 7.** Use the corrected all-exponents argument in `reference_review.md`, not finite search. Parity and residues exclude 0 and 2 through 6. The difference ±1 is impossible by modulo 4 and the factorization of 5^(2k)−1, respectively. m=n=1 attains 7.
- **P_Number-Theory_17 = 7744.** A four-digit aabb is 11(100a+b). If square, 11 divides a+b, hence a+b=11. Then the square is 121(9a+1). For a∈{1,…,9}, only a=7 makes 9a+1 square; b=4.
- **P_Number-Theory_32 = 2.** Both 3^5 and 4^5 are 1 modulo 11. Raise to the 21st power and add.
- **P_Number-Theory_12 = 76.** Enumerating a∈{10,…,99} with a² mod 100=a yields exactly 25 and 76; remove the supplied example 25.
- **P_Number-Theory_42 = 50.** Encode signs by bits over GF(2). The 50 cyclic triple-query vectors form a full-rank 50×50 matrix (exact R elimination). The all-ones target vector is the sum of all 50 rows and, by invertibility, has no other representation. Omitting any row leaves the target outside the observed span, so an unseen sign assignment can change the target while preserving all observed answers. This applies to each path of an adaptive strategy too. All 50 suffice.
- **P_Number-Theory_67 = 1.** n=1 gives prime 5. For even n≥2 the expression is even and greater than 2. For odd n=2k+1≥3, set b=2^k and factor n⁴+4b⁴=(n²−2nb+2b²)(n²+2nb+2b²). The smaller factor is (n−b)²+b²≥4, so both factors exceed 1.
- **P_Number-Theory_13 = 11.** 36^m−5^n ends in 1, so the absolute difference can be below 11 only if it is 1 or 9. Positive difference 1 would make 5^n=(6^m−1)(6^m+1), impossible because the second factor ends in 7. Negative difference −9 would imply 5^n−36^m≡3 mod 6, but it is ±1 mod 6. m=1,n=2 attains 11.

## Polynomials

- **P_Polynomial_32 = 5.** Modulo f(x)=1+x+…+x⁴, x⁵≡1, so f(x⁵)≡f(1)=5.
- **P_Polynomial_23 = 7.** Modulo p(x)=1+x+…+x⁶, x⁷≡1, so p(x⁷)≡7.
- **P_Polynomial_50 = −5.** f(−1)=0 for every a; f′(−1)=5+a. A repeated root requires and is obtained by a=−5.
- **P_Polynomial_24 = −1.** Set t=x³. The expression is (t²+3t+1)²−1≥−1. The equation t²+3t+1=0 has real roots, each attained by a real cube root x, so the bound is attained.
- **P_Polynomial_1 = 0.** For the polynomial interpretation of n, f(1)=f′(1)=0. Thus (x−1)² divides f. The source implicitly assumes n is a nonnegative integer, as required for its stated polynomial.
- **P_Polynomial_40 = −3.** With a=1+u,b=1+v, the expression is u²+uv+v²−3=[(u+v)²+u²+v²]/2−3. Attained at a=b=1.
- **P_Polynomial_47 = 120.** In ∑_(k=0)^9(−1)^k(y−1)^k, the y² coefficient is ∑_(k=2)^9(−1)^k choose(k,2)(−1)^(k−2)=∑ choose(k,2)=choose(10,3)=120.
- **P_Polynomial_17 = 0.** By continuity, f(x)−x has a constant strict sign on the real line. Then either f(f(x))>f(x)>x everywhere or the reverse inequalities hold. In neither case is there a real fixed point of f∘f.
- **P_Polynomial_11 = 20.** The integer power sums satisfy s_0=2,s_1=6,s_n=6s_(n−1)−s_(n−2). Modulo 5 the period is (2,1,4,3,4,1), with two 4s per six terms; indices 61–120 cover ten periods.

## Sequences

- **P_Sequence_28 = 0.** The difference v_n−u_n=(v−u)/6^n tends to zero. The u sequence increases, the v sequence decreases, and both remain between the starting values, so both limits exist and agree.
- **P_Sequence_42 = 601.** For one-based Josephus numbering with step 2, 1324=1024+300 gives 2·300+1. The exact standard recurrence independently yields 601.
- **P_Sequence_20 = 89.** The same line-adjacent-swap recurrence as P_Combinatorics_7 at size 10 gives 89.
- **P_Sequence_11 = 1.** The sum telescopes to 2−1/x_101. All terms are positive and x_3=21/16>1, with x_k increasing thereafter. Thus 1<2−1/x_101<2 exactly; taking a floating-point limit of 2 would incorrectly give floor 2.
- **P_Sequence_21 = 2500.** The supplied identity yields a_0=0, a_(2m)=4a_m and a_(n+2)=2a_(n+1)−a_n+2. Together with a_1=1, this uniquely gives a_n=n² and a_50=2500.
- **P_Sequence_19 = −1.** The state of the last three signs recurs after seven steps. Direct iteration to index 1964 also yields −1.
- **P_Sequence_40 = 125.** Circular permutations comprise disjoint adjacent swaps (123 cycle matchings) plus the two full-cycle one-step rotations. Exact permanent-style subset dynamic programming independently returns 125.

These checks support the retained final keys. They do not show that every source explanation is flawless or that every model response with the right number has sound reasoning. Several problems reuse closely related counting structures, so question count overstates the number of independent mathematical ideas.
