## CHAMP:P_Combinatorics_40
Find the number of ways to fill a 2 x 11 rectangle with 2 x 1 tiles.
Answer: 144
We let a_n be the number of ways to tile a 2 x n rectangle.
For a 2 x (n+1) rectangle, let 2 be the vertical dimension and n+1 be the horizontal direction.
Thus, it could have one vertical tile in the last column, or two horizontal tiles in the last two columns.
Without these new tiles, we have 2 x n or 2 x (n-1) rectangles.
Thus, we have a_(n+1)=a_n+a_(n-1).
Starting from a_1=1 and a_2=2, we have the sequence of number of ways as 3, 5, 8, 13, 21, 34, 55, 89, 144, with a_11=144.
Thus, there are 144 ways to tile a 2 x 11 rectangle.

## CHAMP:P_Combinatorics_21
Each of the faces of a cube is painted by a different color. How many of the colorings are distinct up to rotations?
Answer: 30
We paint a face and put it on the bottom, and consider painting the second face.
We can paint it on top, the remaining four faces have 4! colorings, but we can rotate the cube four times, which makes four colorings the same, so we 4!/4=6 distinct colorings.
If the second face is on the side, we can put it on the front, and the two faces uniquely fix the rotation.
Thus, any coloring of the remaining four faces is distinct, and we have 4!=24 colorings.
In total, we have 30 colorings.

## CHAMP:P_Combinatorics_20
Find the number of ways to fill a 2 x 5 rectangle with 1 x 1 tiles and three-cell L-shaped tiles (i.e., a 2 x 2 tile without a corner).
Answer: 87
We let a_n be the number of ways to tile a 2 x n rectangle.
For a 2 x (n+1) rectangle, let 2 be the vertical dimension and n+1 be the horizontal direction.
We consider possible ways to extend shorter rectangles to get this one.
First, we could add two 1 x 1 tiles to a new column of an 2 x n rectangle.
Second, we could add one 1 x 1 tile and one L-shaped tile to two new columns of an 2 x (n-1) rectangle, and we have four different ways to do so.
Third, we could add two L-shaped tiles to three new columns of an 2 x (n-2) rectangle, and we have two different ways to do so.
Thus, we have a_(n+1)=a_n+4*a_(n-1)+2*a_(n-2).
We have a_1=1 because we can only fill it with two 1 x 1 tiles.
We have a_2=5 because we can fill it with only 1 x 1 tiles or with one of each tile, with four different ways.
We have a_3=11 because we have one way to fill it with only 1 x 1 tiles, 8 ways with three 1 x 1 tiles and one L-shaped tiles (because there are 8 possible locations for the L-shaped tile in a 2 x 3 rectangle), and 2 ways to fill it with two L-shaped tiles.
Continuing on, the sequence of a_n is a_4=33 and a_5=87.
Thus, there are 87 ways to fill an 2 x 5 rectangle.

## CHAMP:P_Combinatorics_38
There are three different toys. We give one toy to each child, selected among four boys and six girls. We want to make sure that at least two boys are selected. In how many ways can this be done?
Answer: 240
For the three children, we can select two boys and one girl, or three boys.
There are C(4, 2)*C(6, 1) ways to perform the first selection.
We can also select three boys.
There are C(4, 3) ways to select three boys.
For each selection, there are 3! ways to give the three toys.
Thus, the total number of ways is (C(4, 2)*C(6, 1)+C(4, 3))*3!=(6*6+4)*6=240.

## CHAMP:P_Combinatorics_5
How many subsets of {1, 2,..., 10} have no two successive numbers?
Answer: 144
For each subset of the set {1, ..., n}, we map it to a length-n string of 0s and 1s, where a digit 1 at i-th place means that i is in the subset.
Thus, the constraint that the subset has no successive numbers means that the string has no two consecutive 1s.
Let P(n) be the number of such strings of length n.
We notice that a length-n string can be constructed from any string of length n-1 by appending 0, or from any string of length n-2 by appending 01, and these two constructions do not share any common string due to the different last digit.
Thus, P(n)=P(n-1)+P(n-2).
We have P(1)=2 (0 and 1) and P(2)=3 (00, 01 and 10).
Thus, P(n) for n from 2 to 10 is 5, 8, 13, 21, 34, 55, 89 and 144.
So there are 144 such subsets.

## CHAMP:P_Combinatorics_30
When (x+y+z)^1999 is expanded and like terms are collected (e.g., collecting 2*x^2*y*z^3 and 3*x^2*y*z^3 into a single term of 5*x^2*y*z^3), how many terms will there be?
Answer: 2001000
For the term x^a*y^b*z^c to appear in the expansion, we must have a+b+c=1999 and a, b, c≥0.
Thus, for any c, we know that a+b=1999-c, and there are 1999-c+1 different values of (a, b), ranging from (0, 1999-c) to (1999-c, 0).
c can range from 0 to 1999.
Thus, the total number of terms in the expansion is 2000+1999+...+1=(2000+1)*2000/2=2001000.

## CHAMP:P_Combinatorics_18
How many different ordered triples (a, b, c) of non-negative integers are there such that a+b+c=99?
Answer: 5050
For any c, we know that a+b=99-c.
Thus, there are 99-c+1 different values of (a, b), ranging from (0, 99-c) to (99-c, 0).
We know that c can range from 0 to 99.
Thus, the total number of ordered triples is 100+99+...+1=(100+1)*100/2=5050.

## CHAMP:P_Combinatorics_7
Consider a row of 11 seats. A child sits on each. Each child may move by at most one seat. How many possible rearrangements are there (including the original one)?
Answer: 144
Let a(n) be the number of possible rearrangements (including the original one) for n seats, and consider the movement of the first child in the row.
If the first child does not move, we have a(n-1) rearrangements, since children 2 to n move subject to the one-seat constraint.
If the first child moves, it can only take the 2nd seat, and the 2nd child must move to the first seat.
Thus, the number of such rearrangements is equal to the number of rearrangements from the 3rd to n-th children, or a(n-2).
So we have a(n)=a(n-1)+a(n-2), and starting from a(1)=1 and a(2)=2, we have the sequence of 3, 5, 8, 13, 21, 34, 55, 89, and 144.
So there are 144 possible rearrangements.

## CHAMP:P_Combinatorics_31
8 dogs fight over 3 cookies. It is possible that a dog gets more than one cookie or no cookies. However, no two dogs would share the same cookie and there are no cookies left unclaimed. If the cookies are the same but the dogs are different (e.g., dog A, B, C each getting one cookie is one result but dog B, C, D each getting one cookie is a different result), how many possible results are there?
Answer: 120
Consider possible configurations of a row of 10 dots, with 7 being black and 3 being white.
We can derive 8 numbers, being the numbers of white dots to the left of the first black dot, in between each black dots, and to the right of the last black dot.
Obviously each number is non-negative and all numbers sum up to 3.
Thus, we can consider this as one possible result of the fight.
Furthermore, each fight result can also be encoded as a dot configuration.
So there are C(10, 7)=C(10, 3)=120 possible results.

## CHAMP:P_Inequality_49
What is the smallest value of |x+y-z|+|x-y+z|+|-x+y+z|-|x|-|y|-|z|?
Answer: 0
We have 2(|x+y-z|+|x-y+z|+|-x+y+z|)=(|x+y-z|+|x-y+z|)+(|x-y+z|+|-x+y+z|)+(|x+y-z|+|-x+y+z|)≥|2x|+|2z|+|2y|=2(|x|+|y|+|z|).
Thus, |x+y-z|+|x-y+z|+|-x+y+z|-|x|-|y|-|z|≥0.
So the smallest value is 0, achieved at e.g., x=y=z=0.

## CHAMP:P_Inequality_8
For positive numbers x_1, ..., x_n, what is the smallest value of x_1^(n+1)+x_2^(n+1)+...+x_n^(n+1)-x_1*x_2*...*x_n*(x_1+x_2+...+x_n)?
Answer: 0
Let A_1=A_2=...=A_(n+1)=(x_1, x_2, ..., x_n), which are all sorted the same way.
Thus, x_1^(n+1)+x_2^(n+1)+...+x_n^(n+1) is the sum of products of n+1 elements, each selected from one sequence and sorted in the same way.
We have x_1*x_2*...*x_n*(x_1+x_2+...+x_n)=(x_1*x_2*...*x_(n-1)*x_n)*x_1+(x_2*x_3*...*x_n*x_1)*x_2+...+(x_3*x_4*...*x_1*x_2)*x_3+...+(x_n*x_1*...*x_(n-2)*x_(n-1))*x_n, which the sum of products of elements, each selected from (x_1, x_2, ..., x_n), (x_2, x_3, ..., x_1), (x_3, x_4, ..., x_2), ..., (x_n, x_1, ..., x_(n-1)), and (x_1, x_2, ..., x_n).
Each of the sequence is a permutation of A_i, so their sum of products is at most x_1^(n+1)+x_2^(n+1)+...+x_n^(n+1).
Thus, We have x_1^(n+1)+x_2^(n+1)+...+x_n^(n+1)-x_1*x_2*...*x_n*(x_1+x_2+...+x_n)≥0, where 0 is achieved when all x_i's are equal.
So the smallest value is 0.

## CHAMP:P_Inequality_4
What's the smallest value of (x^2+2)/sqrt(x^2+1) for real x?
Answer: 2
We have (x^2+2)/sqrt(x^2+1)=(x^2+1)/sqrt(x^2+1)+1/sqrt(x^2+1)=sqrt(x^2+1)+1/sqrt(x^2+1).
In addition, sqrt(x^2+1)+1/sqrt(x^2+1)≥2*sqrt(sqrt(x^2+1)*1/sqrt(x^2+1))=sqrt(1)=1.
So the minimum value of sqrt(x^2+1)+1/sqrt(x^2+1) is 2, which can be achieved at x=0.

## CHAMP:P_Inequality_24
Let a, b>0. What is the smallest value of (a+b)(a^4+b^4)-(a^2+b^2)(a^3+b^3)?
Answer: 0
The expression can be simplified to (a^4*b+a*b^4)-(a^3*b^2+a^2*b^3)=ab((a^3+b^3)-(a^2*b+a*b^2)).
Let u=a^3+b^3 and v=a^2*b+a*b^2.
Consider the two sequences (a^2, b^2) and (a, b) which are sorted in the same way.
u is the sum of products of elements between these two sequences, and v is the sum of products of elements between the first sequence and the reverse of the second sequence.
Thus, u≥v.
So the smallest value of (a+b)(a^4+b^4)-(a^2+b^2)(a^3+b^3) is 0, achieved when a=b.

## CHAMP:P_Inequality_13
For real numbers a, b, c satisfying a+b+c=9, what is the smallest value of a^2+b^2+c^2-(ab+bc+ac)-(a+b+c)?
Answer: -9
We have 2(a^2+b^2+c^2-(ab+bc+ac))=(a^2-2ab-b^2)(b^2-2bc-c^2)(a^2-2ac-c^2)=(a-b)^2+(b-c)^2+(a-c)^2≥0.
So the smallest value of a^2+b^2+c^2-(ab+bc+ac)-(a+b+c) is -9, achieved at a=b=c=3.

## CHAMP:P_Inequality_15
Find the minimum value of a^4+b^4+c^4-a^2*bc-b^2*ac-c^2*ab for positive numbers a, b, c.
Answer: 0
We consider three sequences R=(a^2, b^2, c^2), S=(a, b, c), T=(a, b, c), which are all sorted in the same way.
Thus, both A=a^4+b^4+c^4 and B=a^2*bc+b^2*ac+c^2*ab can be considered as the sum of products of three elements, each selected from one of three sequences.
The elements in A are sorted in the same way, while those in B are not necessarily.
Thus, we have A≥B, which means that A-B≥0, with 0 being achieved when a=b=c.
So the minimum value is 0.

## CHAMP:P_Inequality_26
For real number a, b, what is the largest value of |a+b|/(1+|a+b|)-|a|/(1+|a|)-|b|/(1+|b|)?
Answer: 0
Let x=|a|, y=|b|, z=|a+b|, so the expression is z/(1+z)-x/(1+x)-y/(1+y).
Multiply the expression by (1+x)(1+y)(1+z), we get z(1+x)(1+y)-x(1+y)(1+z)-y(1+x)(1+z)=z+xz+yz+xyz-x-xy-xz-xyz-y-xy-yz-xyz=z-x-y-2xy-xyz.
We have |a+b|≤|a|+|b|, so z-x-y≤0.
With all other terms being non-negative, we can see that this expression is non-positive.
Thus, the largest value of it is 0, achieved when, for example, a=b=0.

## CHAMP:P_Number-Theory_24
Find 2^32+1 mod 641.
Answer: 0
We have 5^4+2^4 | (5^4+2^4)*2^28, which means that 641 | 5^4*2^28+2^32.
We have 5*2^7-(-1) | (5*2^7)^4-(-1)^4, which means that 641 | 5^4*2^28-1.
Thus, 641 | (5^4*2^28+2^32)-(5^4*2^28-1), which is 641 | 2^32+1.

## CHAMP:P_Number-Theory_27
Let n be 22...22, with a total of 1980 digits. What is n mod 1982?
Answer: 0
We have n/2*9=99...99=10^1980-1.
Thus, n=(10^1980-1)*2/9=(10^990+1)(10^990-1)*2/9.
Since 991 is a prime number, we have 10^991≡10 mod 991.
Thus, 10^991-10 mod 991=10(10^990-1) mod 991=0.
Since 991 ∤ 10 and 991 is a prime, we have 991 | 10^990-1.
So 991*2 | (10^990-1)*2.
Thus, n mod 1982=0 (as 9 is not a factor of 991).

## CHAMP:P_Number-Theory_71
What is the smallest value of |12^m-5^n| for positive integers m and n?
Answer: 7
We see that |12^m-5^n| cannot be 0 for positive m, n due to different parity.
Since gcd(12, 5)=1, we have gcd(12^m, 5^n)=1, so 12^m-5^n will not be divisible by factor of 12 or 5 (other than 1), i.e., 2, 3, 4, 5, 6.
We first check if |12^m-5^n|=1 has a solution.
If 12^m-5^n=1, we have 5^n=12^m-1=(6^m+1)(6^m-1), but 6^m+1 ends in 7 and thus is not divisible by 5.
Since 5^n only has prime factor of 5, the equation has no solution.
If 5^n-12^m=1, we need 5^n mod 3=1, which is true only if n is even.
Thus, let n=2k, we have 12^m=(5^k+1)(5^k-1) and 5^k+1 mod 4=1^k+1 mod 4=2.
We have 12^m=2^(2m)*3^m.
Thus, we must have 5^k+1=2*3^v, which means we need 5^k-1=2^(2m-1)3^(m-v).
Since (5^k+1)-(5^k-1)=2, at most one of them is divisible by 3.
Thus, v=0 or v=m.
If v=0, we have 5^k+1=2, which means k=0 and n=2k=0 is not positive.
If v=m, we have (5^k+1)-(5^k-1)=2*3^m-2^(2m-1)=2(3^m-4^(m-1))=2.
So 3^m-4^(m-1)=1, which is not satisfied for any positive integer m.
Thus, we cannot have |5^n-12^m|.
Skipping all the impossible values from 2 to 6, we see that |12^m-5^n|=7 can be solved with m=n=1.
Thus, the answer is 7.

## CHAMP:P_Number-Theory_17
Find a perfect square number that can be written as aabb (i.e., first two digits are the same, and last two digits are the same).
Answer: 7744
Let x^2 be the number, which means x^2=1100a+11b=11(100a+b).
Thus, we have 11 | 100a+b.
Since 100a+b=99a+(a+b) and 11 | 99a, we have 11 | a+b and a+b=11.
So we have n^2=11(99a+(a+b))=11^2*(9a+1), which means that 9a+1 must also be a perfect square.
Trying values of a from 1 to 9, we find a=7 is the only solution.
Thus, b=4 and the number is 7744.

## CHAMP:P_Number-Theory_32
Find 3^105+4^105 mod 11.
Answer: 2
3^105+4^105 mod 11=(3^5)^21 + (4^5)^21 mod 11=1^21+1^21 mod 11=2.

## CHAMP:P_Number-Theory_12
An integer a is called automorphic if a^2 ends in a. For example, 5 is automorphic because 5^2=25 ends in 5. 25 is also automorphic because 25^2=625 ends in 25. Find all two-digit automorphic numbers besides 25.
Answer: 76
We have 10≤a≤99 and since a^2 ends in a, a^2-a ends in 00.
So 100 | a(a-1).
Since gcd(a, a-1)=1, we have one of a and a-1 being a multiple of 4, and the other being a multiple of 25, subject to 10≤a≤99 (or one being a multiple of 100, but this is impossible because a is a two-digit number).
If 25 | a and 4 | a-1, the only solution is a=25, as introduced in the question.
If 25 | a-1 and  4 | a, the only solution is a=76, with 76^2=5776.
So the answer is 76.

## CHAMP:P_Number-Theory_42
Fifty numbers a_1, a_2,..., a_50 are written along a circle. Each of the numbers is +1 or -1. You want to find the product of these numbers. You may find the product of three consecutive numbers in one question. How many questions do you need at least?
Answer: 50
There are 50 products in total: a_1*a_2*a_3, a_2*a_3*a_4, ..., a_50*a_1*a_2.
After 49 questions, one product is unknown, and suppose that it is a_1*a_2*a_3.
We can flip the sign of all a_i with i mod 3≠0 except for a_1, and get the same answer for all 49 products.
However, the product a_1*a_2*a_3 is different, so 49 questions are not sufficient.
On the other hand, 50 questions are sufficient, because (a_1*a_2*a_3)(a_2*a_3*a_4)...(a_50*a_1*a_2)=(a_1*a_2*...*a_50)^3=a_1*a_2*...*a_50 when each of a_i is limited to -1 or 1.

## CHAMP:P_Number-Theory_67
For how many integers n in {1, 2, ..., 99} is n^4+4^n a prime number?
Answer: 1
We have n^4+4^n=5 being a prime number when n=1.
For n>1, if n is even, obviously n^4+4^n is even and greater than two.
Thus, we only need to consider the case of odd n.
We let n=2k+1.
n^4+4^n=n^4+4^(2k+1)=n^4+4*4^(2k)=n^4+4*2^(4k)=n^4+4*(2^k)^4.
n^4+4*(2^k)^4=(n^2+2*(2^k)^2+2n(2^k))(n^2+2*(2^k)^2-2n(2^k)).
The last expression gives a factorization of n^4+4^n.
So n^4+4^n cannot be a prime number for any n>1.
Thus, there is 1 prime number.

## CHAMP:P_Number-Theory_13
What is the smallest value of |36^m-5^n| for positive integers m and n?
Answer: 11
Since 36^m always ends in 6 and 5^n always ends in 5, |36^m-5^n| can only end in 1 or 9.
If |36^m-5^n|=1, we need 36^m-5^n=1.
5^n=36^m-1=(6^m)^2-1=(6^m+1)(6^m-1).
However, 6^m+1 is not divisible by 5 since it ends with 7, but 5^n only has prime factors of 5.
Thus, the equation has no solution.
If |36^m-5^n|=9, we need 5^n-36^m=9.
We have 5^n-36^m mod 6=(-1)^n-0 mod 6=±1, which is not equal to 9 mod 6=3.
Thus, the equation again has no solution.
|36^m-5^n|=11 can be solved by m=1, n=2.
So 11 is the smallest possible value.

## CHAMP:P_Polynomial_32
Let f(x)=x^4+x^3+x^2+x+1. Find the remainder of f(x^5) divided by f(x).
Answer: 5
We have f(x^5)=x^20+x^15+x^10+x^5+1=(x^20-1)+(x^15-1)+(x^10-1)+(x^5-1)+5.
We have x^20-1, x^15-1, x^10-1, x^5-1 all divisible by x^5-1.
We also have f(x) | x^5-1 because (x-1)(x^4+x^3+x^2+x+1)=x^5-1.
Thus, (x^20-1)+(x^15-1)+(x^10-1)+(x^5-1) is divisible by f(x).
So the remainder of f(x^5) divided by f(x) is 5.

## CHAMP:P_Polynomial_23
Finding the remainder when p(x^7) is divided by p(x), where p(x)=x^6+x^5+...+x+1?
Answer: 7
We have p(x)=x^6+x^5+...+x+1=(x^7-1)/(x-1).
Thus, p(x) | x^7-1.
Let y=x^7.
In addition, since y-1 | y^n-1^n for any n, we have y-1 | p(y)-p(1) for the polynomial p.
Since p(x) | y-1, we have p(x) | p(y)-p(1).
Thus, the remainder when p(y)=p(x^7) divides p(x) is p(1)=7.

## CHAMP:P_Polynomial_50
Find the value of a such that the polynomial x^5−ax^2−ax+1 has a root with multiplicity more than 1 at x=-1.
Answer: -5
For -1 to be a root of multiplicity of more than 1, it needs to be a root of f(x)=x^5−ax^2−ax+1 and f'(x)=5x^4−2ax−a.
Thus, f(-1)=-1-a+a+1=0 and f'(-1)=5+2a-a=0.
So we get a=-5.

## CHAMP:P_Polynomial_24
Find the smallest value of the polynomial f(x)=x^3(x^3+1)(x^3+2)(x^3+3).
Answer: -1
Let t=x^3, we have f(x)=t(t+1)(t+2)(t+3)=(t^2+3t)(t^2+3t+2).
Let u=t^2+3t, we have f(x)=u(u+2)=u^2+2u+1-1=(u+1)^2-1≥-1.
Thus, the minimum value is -1.

## CHAMP:P_Polynomial_1
What is the remainder of nx^(n+1)−(n+1)x^n+1 divided by (x−1)^2?
Answer: 0
We have f(x)=(x-1)^2*q(x)+r(x) where r(x) is a polynomial of degree at most 1 (i.e., r(x)=ax+b).
Thus, f(1)=0=r(1).
We have f'(x)=2(x-1)*q(x)+(x-1)^2*q(x)+r'(x), so f'(1)=r'(1)=0.
Since r(x) has the form of ax+b, we have a+b=0, a=0, so b=0.
Thus, r(x)=0 is the remainder.

## CHAMP:P_Polynomial_40
Find the smallest value of a^2+ab+b^2-3a-3b for real numbers a, b.
Answer: -3
Let the smallest value be m, so we have a^2+ab+b^2-3a-3b-m≥0.
Consider the expression as a polynomial in a, which can be written as a^2+(b-3)a+(b^2-3b-m).
To ensure that it is always greater than or equal to 0, we need (b-3)^2-4(b^2-3b-m)≤0.
Expanding the expression out, we get b^2-6b+9-4b^2+12b+4m=-3b^2-6b+9+4m=-3(b^2-2b+1)+12+4m=-3(b-1)^2+12+4m≤0.
Since -3(b-1)^2≤0, we need 12+4m≤0, which means that m≤-3.
We need m to be a value achievable for a^2+ab+b^2-3a-3b, which means that m=-3.

## CHAMP:P_Polynomial_47
The polynomial 1-x+x^2-x^3+...+x^8-x^9 may be written in the form a_0+a_1*y+a_2*y^2+...+a_9*y^9, where y=x+1 and each a_i is a constant. Find the value of a_2.
Answer: 120
We have f(x)=1-x+x^2-x^3+...+x^8-x^9=(1-x^10)/(1+x).
Substituting x=y-1, we have f(x)=(1-(y-1)^10)/y.
We have the coefficient C(10, 3)*y^3*(-1)^7=-120 for the term y^3 in (y-1)^10.
Thus, the coefficient a_2 for y^2 in (1-(y-1)^10)/y is -(-120)=120.

## CHAMP:P_Polynomial_17
Let f(x) be a polynomial of degree n and f(x)=x has no real number solutions. What is the maximum number of real number solutions does f(f(x))=x have?
Answer: 0
Since f(x)=x has no real number solution, we have f(x)-x>0 for all x or f(x)<0 for all x.
Consider the case of f(x)-x>0, which means that f(x)>x for all x.
Thus, f(f(x))>f(x)>x, so f(f(x))-x>0, which means that f(f(x))=x has no real number solution either.
The case of f(x)-x<0 is analogous, also with no solution.
Thus, the maximum number of real number solutions of f(f(x))=x is 0.

## CHAMP:P_Polynomial_11
If x_1, x_2 are the two roots of the polynomial x^2-6x+1, for how many integer n in {61, 62, ..., 120} does x_1^n+x_2^n divided by 5 give a remainder of 4?
Answer: 20
We have x_1+x_2=6, x_1*x_2=1.
Define u=x_1+x_2, v=x_1*x_2 and s_n=x_1^n+x_2^n.
Thus, we have s_0=2, s_1=6 and s_n=u^s_(n-1)-v*s_(n-2)=6s_(n-1)-s_(n-2).
Modulo 5, we have s_n mod 5=(s_(n-1)-s(n-2) mod 5).
The sequence of s_n modulo 5 is 2, 1, 4, 3, 4, 1, 2, 1.
We see that the sequence becomes periodic after the occurrence of 2, 1 in the end, with a period of 6.
In one period, the remainder of 4 appears 2 times.
So for n=61, 62, ..., 120, there are 60 values, or 10 periods, and the remainder of 4 appears 20 times.

## CHAMP:P_Sequence_28
Let u<v and define two sequences {u_n} and {v_n}, as u_0=u, u_n=(u_(n-1)+v_(n-1))/2 and v_0=v, v_n=(u_(n-1)+2v_(n-1))/3. Let the two limits be L_u and L_v respectively. Find L_u-L_v.
Answer: 0
We have v_n-u_n=v_(n-1)/6-u_(n-1)/6=(v_(n-1)-u_(n-1))/6.
So the difference of the sequence decreases to 1/6 after each term.
Thus, they converge to the same limit, and L_u-L_v=0.

## CHAMP:P_Sequence_42
1324 persons are arranged in a circle and numbered from 1 to 1324. Then every 2nd person is removed (i.e., the first four removed people are those numbered 2, 4, 6 and 8) until there is only one person left. What is the number of the last person left?
Answer: 601
When there are 2^m people, the first person will be the last person left, because after every round of selection, there will be 2^p people left, with the first person still being the first.
When there are 2^m+k people, we can first select k people, so that we have 2^m left.
Thus, whoever is the first person at that stage will be the last one left.
In removing k people, we choose the index 2, 4, 6, ..., 2k.
So person 2k+1 is the last person left.
For 1324 people, we have 2^m=1024, k=300.
Thus, the last person left is 300*2+1=601.

## CHAMP:P_Sequence_20
Let a_n be the number of all permutations p of {1, ..., n} with |p(i)−i|≤1 for all i. Find a_10.
Answer: 89
For permuting n numbers, we see that the number n can either stay at the n-th location, or be swapped with n-1.
In the first case, we have a_(n-1) possible choices.
In the second case, we have a_(n-2) possible choices.
Thus, we have a_n=a_(n-1)+a_(n-2), with a_1=1, a_2=2.
So we have the sequence of a_n be 1, 2, 3, 5, 8, 13, 21, 34, 55, 89.
Thus, a_10=89.

## CHAMP:P_Sequence_11
Define a sequence with x_1=1/2, x_(k+1)=x_k^2+x_k. What is the integer part of the sum 1/(x_1+1)+1/(x_2+1)+1/(x_3+1)+...+1/(x_100+1)?
Answer: 1
We have x_(k+1)=x_k^2+x_k=x_k(x_k+1), so 1/x_(k+1)=1/(x_k(x_k+1))=1/x_k-1/(x_k+1).
Thus, 1/(x_k+1)=1/x_k-1/x_(k+1).
So 1/(x_1+1)+1/(x_2+1)+1/(x_3+1)+...+1/(x_100+1)=(1/x_1-1/x_2)+(1/x_2-1/x_3)+...+(1/x_100-1/x_101)=1/x_1-1/x_101.
We have x_1=1/2, x_2=3/4, x_3=21/16>1.
Since x_(n+1)=x_n^2+x_n>x_n, we have x_n>1 for all n≥3.
Thus, 1/x_101<1.
This means that the integer part of 1/x_1-1/x_101 is 1.

## CHAMP:P_Sequence_21
The sequence a_0, a_1, a_2, ... is such that, for all nonnegative m≥n, we have a_(m+n)+a_(m−n)=(a_(2m)+a_(2n))/2. If a_1=1, find a_50.
Answer: 2500
With m=n, we have a_(2n)+a_0=(a_(2n)+a_(2n))/2.
So a_0=0.
With n=0, we have a_m+a_m=(a_(2m)+a_0)/2.
So a_(2m)=4a_m.
With m=n+2, we have a_(2n+2)+a_2=(a_(2n+4)+a_(2n))/2.
Plugging in a_(2m)=4a_m, we have 4(a_(n+1)+a_1)=4*(a_(n+2)+a_n)/2.
With a_1=1, we have a_(n+2)=2a_(n+1)-a_n+2.
Thus, starting from a_0=0, a_1=1, we have the sequence a_0, a_1, a_2, ... to be 0, 1, 4, 9, 16, ...
We see that a_n=n^2, which can be shown with a_(n+2)^2=n^2+4n+4=2(n^2+2n+1)-n^2+2=a_(n+1)^2-a_n^2+2.
Thus, a_50=2500.

## CHAMP:P_Sequence_19
Define a sequence with a_1=a_2=1, a_3=−1, a_n=a_(n−1)*a_(n−3). Find a_1964.
Answer: -1
We see that the first few terms are 1, 1, -1, -1, -1, 1, -1, 1, 1, -1.
The last three terms are the same as the first three terms, and since a_n depends only on the last three terms, the pattern of the first 7 numbers repeats indefinitely.
Thus, a_1964=a_(1964 mod 7)=a_4=-1.

## CHAMP:P_Sequence_40
Let a_n be the number of all permutations p of {1, ..., n} with min(n-|p(i)−i|, |p(i)−i|)≤1 for all i. Find a_10.
Answer: 125
We note that the condition min(n-|p(i)−i|, |p(i)−i|)≤1 is equivalent to keep each number within its left and right neighbor positions when these numbers are arranged in a circle.
Let f_n be the number of permutations which satisfies |p(i)−i|≤1 (i.e., not involving the wrap-around along the circle).
To permute n numbers, we can fix the location of n at the n-th location, which results in the permutation of n-1 numbers that cannot be wrapped around, or f_(n-1).
We can also change the location of n and n-1, or n and 1, and arrange the remaining n-2 numbers without wrap-around.
There are f_(n-2) permutations each.
Finally, we can shift the entire {1, 2, ..., n} sequence clockwise and counterclockwise, which results in two permutations.
So a_n=f_(n-1)+2f(n-2)+2.
To find f_n, we see that the number n can either stay at the n-th location, or be swapped with n-1.
In the first case, we have f_(n-1) possible choices.
In the second case, we have f_(n-2) possible choices.
Thus, we have f_n=f_(n-1)+f_(n-2), with f_1=1, f_2=2.
So the sequence f_1, f_2, f_3, ... is 1, 2, 3, 5, 8, 13, 21, 34, 55, 89.
We have a_10=f_9+2f_8+2=55+2*34+2=125.

