# Selected mathematics examples

Four families, three numerical versions, trap/control pairs. Version 0 is development; versions 1 and 2 are supplementary. Gold conclusions include proof sketches. All are adaptations.

## M-triangle-0-trap
An equilateral triangle has perimeter 30 cm and height 10 cm. What is its area? If these conditions cannot hold simultaneously, say so.
Gold: {"conclusion":"inconsistent","value":null,"solutions":[]}
Proof: All sides are 10, so height is 10*sqrt(3)/2, not 10.

## M-triangle-0-control
An equilateral triangle has perimeter 30 cm and height 10*sqrt(3)/2 cm. What is its area? If these conditions cannot hold simultaneously, say so.
Gold: {"conclusion":"numeric","value":43.3012701892219,"solutions":[]}
Proof: The conditions agree: area = 10^2*sqrt(3)/4.

## M-kiwi-0-trap
Oliver picks 44 kiwis on Friday and 58 on Saturday. On Sunday he picks twice as many as on Friday. Of the kiwis picked on Sunday, 5 are smaller than average. How many kiwis did he pick over all three days?
Gold: {"conclusion":"numeric","value":190,"solutions":[]}
Proof: Size does not remove a kiwi from the count. Total = Friday + Saturday + 2*Friday.

## M-kiwi-0-control
Oliver picks 44 kiwis on Friday and 58 on Saturday. On Sunday he picks twice as many as on Friday. He then throws away 5 of the kiwis picked on Sunday. How many of the kiwis picked over all three days does he keep?
Gold: {"conclusion":"numeric","value":185,"solutions":[]}
Proof: The question asks how many he keeps, so subtract exactly the discarded kiwis.

## M-integer-0-trap
Find all integer solutions of x^2 + x = 3.
Gold: {"conclusion":"no_integer_solution","value":null,"solutions":[]}
Proof: x(x+1) is even for every integer x, whereas 3 is odd.

## M-integer-0-control
Find all integer solutions of x^2 + x = 2.
Gold: {"conclusion":"integer_solutions","value":null,"solutions":[1,-2]}
Proof: (x-1)(x+2)=0, hence x=1 or x=-2.

## M-month-0-trap
Natalia sold 48 hair clips in April. She sold half as many in May. How many did she sell in total in April and June?
Gold: {"conclusion":"insufficient_information","value":null,"solutions":[]}
Proof: June sales are not specified; May sales do not determine June sales.

## M-month-0-control
Natalia sold 48 hair clips in April. She sold half as many in May. How many did she sell in total in April and May?
Gold: {"conclusion":"numeric","value":72,"solutions":[]}
Proof: Both April and May sales are specified; sum April and half of April.

## M-triangle-1-trap
An equilateral triangle has perimeter 36 cm and height 12 cm. What is its area? If these conditions cannot hold simultaneously, say so.
Gold: {"conclusion":"inconsistent","value":null,"solutions":[]}
Proof: All sides are 12, so height is 12*sqrt(3)/2, not 12.

## M-triangle-1-control
An equilateral triangle has perimeter 36 cm and height 12*sqrt(3)/2 cm. What is its area? If these conditions cannot hold simultaneously, say so.
Gold: {"conclusion":"numeric","value":62.3538290724796,"solutions":[]}
Proof: The conditions agree: area = 12^2*sqrt(3)/4.

## M-kiwi-1-trap
Oliver picks 36 kiwis on Friday and 47 on Saturday. On Sunday he picks twice as many as on Friday. Of the kiwis picked on Sunday, 7 are smaller than average. How many kiwis did he pick over all three days?
Gold: {"conclusion":"numeric","value":155,"solutions":[]}
Proof: Size does not remove a kiwi from the count. Total = Friday + Saturday + 2*Friday.

## M-kiwi-1-control
Oliver picks 36 kiwis on Friday and 47 on Saturday. On Sunday he picks twice as many as on Friday. He then throws away 7 of the kiwis picked on Sunday. How many of the kiwis picked over all three days does he keep?
Gold: {"conclusion":"numeric","value":148,"solutions":[]}
Proof: The question asks how many he keeps, so subtract exactly the discarded kiwis.

## M-integer-1-trap
Find all integer solutions of x^2 + x = 7.
Gold: {"conclusion":"no_integer_solution","value":null,"solutions":[]}
Proof: x(x+1) is even for every integer x, whereas 7 is odd.

## M-integer-1-control
Find all integer solutions of x^2 + x = 6.
Gold: {"conclusion":"integer_solutions","value":null,"solutions":[2,-3]}
Proof: (x-2)(x+3)=0, hence x=2 or x=-3.

## M-month-1-trap
Natalia sold 60 hair clips in April. She sold half as many in May. How many did she sell in total in April and June?
Gold: {"conclusion":"insufficient_information","value":null,"solutions":[]}
Proof: June sales are not specified; May sales do not determine June sales.

## M-month-1-control
Natalia sold 60 hair clips in April. She sold half as many in May. How many did she sell in total in April and May?
Gold: {"conclusion":"numeric","value":90,"solutions":[]}
Proof: Both April and May sales are specified; sum April and half of April.

## M-triangle-2-trap
An equilateral triangle has perimeter 42 cm and height 14 cm. What is its area? If these conditions cannot hold simultaneously, say so.
Gold: {"conclusion":"inconsistent","value":null,"solutions":[]}
Proof: All sides are 14, so height is 14*sqrt(3)/2, not 14.

## M-triangle-2-control
An equilateral triangle has perimeter 42 cm and height 14*sqrt(3)/2 cm. What is its area? If these conditions cannot hold simultaneously, say so.
Gold: {"conclusion":"numeric","value":84.870489570875,"solutions":[]}
Proof: The conditions agree: area = 14^2*sqrt(3)/4.

## M-kiwi-2-trap
Oliver picks 52 kiwis on Friday and 61 on Saturday. On Sunday he picks twice as many as on Friday. Of the kiwis picked on Sunday, 9 are smaller than average. How many kiwis did he pick over all three days?
Gold: {"conclusion":"numeric","value":217,"solutions":[]}
Proof: Size does not remove a kiwi from the count. Total = Friday + Saturday + 2*Friday.

## M-kiwi-2-control
Oliver picks 52 kiwis on Friday and 61 on Saturday. On Sunday he picks twice as many as on Friday. He then throws away 9 of the kiwis picked on Sunday. How many of the kiwis picked over all three days does he keep?
Gold: {"conclusion":"numeric","value":208,"solutions":[]}
Proof: The question asks how many he keeps, so subtract exactly the discarded kiwis.

## M-integer-2-trap
Find all integer solutions of x^2 + x = 13.
Gold: {"conclusion":"no_integer_solution","value":null,"solutions":[]}
Proof: x(x+1) is even for every integer x, whereas 13 is odd.

## M-integer-2-control
Find all integer solutions of x^2 + x = 12.
Gold: {"conclusion":"integer_solutions","value":null,"solutions":[3,-4]}
Proof: (x-3)(x+4)=0, hence x=3 or x=-4.

## M-month-2-trap
Natalia sold 72 hair clips in April. She sold half as many in May. How many did she sell in total in April and June?
Gold: {"conclusion":"insufficient_information","value":null,"solutions":[]}
Proof: June sales are not specified; May sales do not determine June sales.

## M-month-2-control
Natalia sold 72 hair clips in April. She sold half as many in May. How many did she sell in total in April and May?
Gold: {"conclusion":"numeric","value":108,"solutions":[]}
Proof: Both April and May sales are specified; sum April and half of April.

