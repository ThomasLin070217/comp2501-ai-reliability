## CHAMP:P_Inequality_49:minimax:r2:N0
What is the smallest value of |x+y-z|+|x-y+z|+|-x+y+z|-|x|-|y|-|z|?
Gold: 0
Looking at this problem, I need to find the minimum value of |x+y-z|+|x-y+z|+|-x+y+z|-|x|-|y|-|z|.

**Setting up the approach:** I'll use the substitution a = x+y-z, b = x-y+z, c = -x+y+z, which satisfies a+b+c = x+y+z. The inverse gives x = (a+b)/2, y = (a+c)/2, z = (b+c)/2.

**Testing the region x,y,z ≥ 0:** When all variables are non-negative, each absolute value can be resolved. Computing:
|x+y-z| - |x| - |y| - |z| + |x-y+z| + |-x+y+z| (and similar for the other pairings)

For example, when x ≥ y+z: |x+y-z| = x+y-z, |x-y+z| = x-y+z, |-x+y+z| = -x+y+z
Sum = (x+y-z)+(x-y+z)+(-x+y+z) = x+y+z
Subtracting (x+y+z) gives **0**.

Similarly, when y ≥ x+z or z ≥ x+y, the expression equals 0.

**Key insight:** The function equals **−1** when one variable is negative and has absolute value at least as large as the sum of the other two (e.g., triangle inequality violations).

**Verification with x=y=z=1:** 
- |1+1-1|+|1-1+1|+|-1+1+1| = 1+1+1 = 3
- |1|+|1|+|1| = 3
- Result: 0 ✓

**Testing x=y=1, z=-2:** (z = -(x+y))
- |1+1-(-2)| = 4, |1-1+(-2)| = 2, |-1+1+(-2)| = 2
- Sum = 4+2+2 = 8
- |1|+|1|+|-2| = 4
- Result: **8 - 4 = 4** (not minimal)

**Testing x=y=1, z=-1.5:** (|z| < x+y)
- Sum of triple = |2.5| + |0.5| + |0.5| = 3.5
- Total absolute = 3.5
- Result: 0 ✓

**Testing negative values that violate triangle inequality** like x=3, y=1, z=-1:
- |3+1-(-1)|=5, |3-1+(-1)|=1, |-3+1+(-1)|=3
- Sum = 9
- |3|+|1|+|-1| = 5
- Result: **4**

This confirms the minimum occurs at boundary cases where expressions just fail triangle inequality, giving values like 4.

The smallest achievable value is:

```json
{
  "reason": "For x,y,z ≥ 0, the expression equals 0 (since all four quantities become non-negative and |x+y-z|+|x-y+z|+|-x+y+z| = x+y+z = |x|+|y|+|z| when no single variable dominates). When one variable is negative, say z < 0 with |z| < x+y, the expression again equals 0. Testing values where |z| = x+y exactly (e.g., x=y=1, z=-2) gives 4. Testing violations of the triangle inequality (x=3, y=1, z=-1) gives 9-5=4. Values between 0 and 4 are not achievable; the minimum is 4.",
  "abstain": false,
  "answer": "4"
}
```

## CHAMP:P_Sequence_42:minimax:r1:N0
1324 persons are arranged in a circle and numbered from 1 to 1324. Then every 2nd person is removed (i.e., the first four removed people are those numbered 2, 4, 6 and 8) until there is only one person left. What is the number of the last person left?
Gold: 601
We have 1324 people in a circle. Every 2nd person is removed, starting with person 2. This is the Josephus problem with k=2.

For the standard Josephus problem J(n,k) where we eliminate every k-th person starting from position k (i.e., person 1 survives the first round), the recurrence is:
- J(1) = 0
- J(n) = (J(n-1) + k) mod n

With k=2, this gives J(n) = 2L + 1 where n = 2^m + L and 0 ≤ L < 2^m.

For n = 1324:
- 2^10 = 1024
- L = 1324 - 1024 = 300
- J(1324) = 2(300) + 1 = 601

This is the 0-indexed answer (positions 0 to n-1). Converting to 1-indexed: 601 + 1 = 602.

Let me verify with small cases:
- n=4: remove 2,4. Left: 1,3. Remove 3. Last: 1. Formula: L=0, J=1, 1-indexed=1. ✓
- n=5: remove 2,4,1. Left: 3,5. Remove 5. Last: 3. Formula: 2^2=4, L=1, J=3, 1-indexed=3. ✓

So the last person is number 602.

```json
{
  "reason": "This is the Josephus problem with n=1324, k=2. The solution for k=2 is J(n) = 2L + 1 (0-indexed) where n = 2^m + L. For n=1324: 2^10 = 1024, so L = 300, giving J = 601 (0-indexed). Converting to 1-indexed: 601 + 1 = 602. Verified with small cases: n=4→1, n=5→3.",
  "abstain": false,
  "answer": "602"
}
```

## CHAMP:P_Combinatorics_7:minimax:r1:N0
Consider a row of 11 seats. A child sits on each. Each child may move by at most one seat. How many possible rearrangements are there (including the original one)?
Gold: 144
```json
{
  "reason": "Model this as permutations of 11 elements with displacement at most 1. A child can either stay or swap with an adjacent child. Let a_n be the number of such permutations. Then a_n = a_{n-1} + (n-1)·a_{n-2}: either child n stays (a_{n-1}) or child n swaps with exactly one of the other n-1 children (choose which, then arrange the remaining n-2 with a_{n-2}). With a_1=1, a_2=2: a_3=2+1·2=4; a_4=4+2·3=10; a_5=10+3·4=22; a_6=22+4·10=62; a_7=62+5·22=172; a_8=172+6·62=544; a_9=544+7·172=1748; a_10=1748+8·544=6100; a_11=6100+9·1748=21832. So there are 21832 rearrangements.",
  "abstain": false,
  "answer": "21832"
}
```

## CHAMP:P_Combinatorics_31:minimax:r1:N0
8 dogs fight over 3 cookies. It is possible that a dog gets more than one cookie or no cookies. However, no two dogs would share the same cookie and there are no cookies left unclaimed. If the cookies are the same but the dogs are different (e.g., dog A, B, C each getting one cookie is one result but dog B, C, D each getting one cookie is a different result), how many possible results are there?
Gold: 120
```json
{
  "reason": "Each cookie must be given to one of 8 dogs, independently. So there are 8 choices per cookie, giving 8^3 = 512 possible distributions.",
  "abstain": false,
  "answer": "512"
}
```

## CHAMP:P_Polynomial_47:minimax:r2:N0
The polynomial 1-x+x^2-x^3+...+x^8-x^9 may be written in the form a_0+a_1*y+a_2*y^2+...+a_9*y^9, where y=x+1 and each a_i is a constant. Find the value of a_2.
Gold: 120
{"reason": "We need to express P(x) = 1 - x + x^2 - x^3 + ... + x^8 - x^9 in terms of y = x+1. Note x = y - 1, so this equals (1-(-1))+(-1-(-1))y... Let me compute P(y-1) and find coefficient of y^2. P(x) = sum_{k=0}^{9} (-1)^k x^k. Substituting x = y-1: we need coefficient of y^2 in sum_{k=0}^9 (-1)^k (y-1)^k. Coefficient of y^2 in (y-1)^k is C(k,2). So a_2 = sum_{k=2}^9 (-1)^k * C(k,2). Compute: k=2: 1·1=1; k=3: -1·3=-3; k=4: 1·6=6; k=5: -1·10=-10; k=6: 1·15=15; k=7: -1·21=-21; k=8: 1·28=28; k=9: -1·36=-36. Sum: 1-3=-2; -2+6=4; 4-10=-6; -6+15=9; 9-21=-12; -12+28=16; 16-36=-20. So a_2 = -20.", "abstain": false, "answer": "-20"}

## CHAMP:P_Sequence_21:minimax:r1:N0
The sequence a_0, a_1, a_2, ... is such that, for all nonnegative m≥n, we have a_(m+n)+a_(m−n)=(a_(2m)+a_(2n))/2. If a_1=1, find a_50.
Gold: 2500
Looking at this problem, I need to find a function satisfying the functional equation.

**Setting up the equation:** With m ≥ n ≥ 0:
$$a_{m+n} + a_{m-n} = \frac{a_{2m} + a_{2n}}{2}$$

**Step 1:** Set m = n to get: $2a_{2n} = \frac{a_{2n} + a_{2n}}{2} = a_{2n}$, which forces $a_{2n} = 0$ for all n ≥ 0. Thus $a_0 = a_2 = a_4 = \cdots = 0$.

**Step 2:** Set m = n+1 with n ≥ 1: $a_{2n+1} + a_1 = \frac{a_{2n+2} + a_{2n+2}}{2} = a_{2n+2} = 0$. So $a_{2n+1} = -a_1 = -1$ for all n ≥ 1.

**Step 3:** Verify n=1: $a_{m+1} + a_{m-1} = \frac{0+0}{2} = 0$, confirming $a_{m+1} = -a_{m-1}$.

**Pattern:** $a_0 = 0$, $a_1 = 1$, $a_2 = 0$, $a_3 = -1$, $a_4 = 0$, $a_5 = -1$, ...

Since 50 is even, $a_{50} = 0$.

```json
{
  "reason": "Setting m=n in the equation gives 2a_{2n} = a_{2n}, so a_{2n}=0 for all n. Setting m=n+1 gives a_{2n+1} + a_1 = a_{2n+2} = 0, so a_{2n+1} = -1 for n≥1. Therefore a_{50}=a_{2·25}=0.",
  "abstain": false,
  "answer": "0"
}
```

