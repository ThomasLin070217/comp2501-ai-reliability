# Exact bounded computations plus checks of equality witnesses/identities.
# General analytic arguments live in cases.R; finite checks are not proofs of
# infinite-domain claims and are labelled accordingly in the researcher report.
modpow <- function(a,n,m) {r<-1;while(n>0){if(n%%2==1)r<-(r*a)%%m;a<-(a*a)%%m;n<-n%/%2};r}
fibtiling <- function(n){v<-c(1,1);if(n>=2)for(i in 2:n)v[i+1]<-v[i]+v[i-1];v[n+1]}
poly_trim <- function(v){while(length(v)>1&&tail(v,1)==0)v<-head(v,-1);v}
poly_rem <- function(a,b){a<-poly_trim(a);b<-poly_trim(b);while(length(a)>=length(b)&&any(a!=0)){k<-length(a)-length(b);a[(k+1):length(a)]<-a[(k+1):length(a)]-tail(a,1)/tail(b,1)*b;a<-poly_trim(a)};a}
permanent_allowed <- function(n,circular=FALSE){
 memo<-new.env(parent=emptyenv())
 rec<-function(i,mask){if(i>n)return(1);key<-paste(i,mask);if(exists(key,memo,inherits=FALSE))return(memo[[key]])
  d<-abs(seq_len(n)-i);allowed<-if(circular)pmin(n-d,d)<=1 else d<=1
  out<-0;for(j in which(allowed))if(bitwAnd(mask,bitwShiftL(1L,j-1))==0)out<-out+rec(i+1,bitwOr(mask,bitwShiftL(1L,j-1)))
  memo[[key]]<-out;out};rec(1,0L)
}
l_tilings <- function(n){
 cells<-matrix(seq_len(2*n),nrow=2);shapes<-lapply(seq_len(2*n),function(i)i)
 for(j in seq_len(n-1)){s<-as.vector(cells[,j:(j+1)]);for(k in 1:4)shapes[[length(shapes)+1]]<-s[-k]}
 memo<-new.env(parent=emptyenv())
 count<-function(filled){if(all(filled))return(1);key<-paste(as.integer(filled),collapse='');if(exists(key,memo,inherits=FALSE))return(memo[[key]])
  first<-which(!filled)[1];out<-0;for(s in shapes)if(first%in%s&&!any(filled[s])){f<-filled;f[s]<-TRUE;out<-out+count(f)}
  memo[[key]]<-out;out};count(rep(FALSE,2*n))
}
gf2rank <- function(a){r<-0L;for(j in seq_len(ncol(a))){if(r==nrow(a))break;p<-which(a[(r+1):nrow(a),j]==1);if(!length(p))next;p<-p[1]+r;r<-r+1L;t<-a[r,];a[r,]<-a[p,];a[p,]<-t;for(k in setdiff(which(a[,j]==1),r))a[k,]<-(a[k,]+a[r,])%%2};r}
math_computations <- function(){
 out<-list();put<-function(id,value,method){out[[id]]<<-list(value=as.numeric(value),method=method)}
 put('P_Combinatorics_40',fibtiling(11),'Exact domino recurrence with T_0=T_1=1.')
 put('P_Combinatorics_21',factorial(6)/(6*4),'24 rotations; free action because all colours differ.')
 put('P_Combinatorics_20',l_tilings(5),'Independent exhaustive exact-cover count of monominoes and all four L orientations.')
 g<-expand.grid(i=1:10,j=1:10,k=1:10)
 put('P_Combinatorics_38',sum(g$i!=g$j&g$i!=g$k&g$j!=g$k&((g$i<=4)+(g$j<=4)+(g$k<=4)>=2)),'Exhaustive ordered recipients for three distinct toys.')
 subset_count<-sum(vapply(0:1023,function(m){b<-as.integer(intToBits(m))[1:10];!any(b[-1]+b[-10]==2)},TRUE))
 put('P_Combinatorics_5',subset_count,'Exhaustive enumeration of 1024 subsets, including empty set.')
 put('P_Combinatorics_30',sum(1:2000),'Enumerate allowed exponent counts for each value of one exponent.')
 put('P_Combinatorics_18',sum(1:100),'Enumerate ordered pairs conditional on c=0,...,99.')
 put('P_Combinatorics_7',permanent_allowed(11),'Exact subset DP of all permitted one-seat permutations.')
 count_alloc<-function(d,k){if(d==1)return(1);sum(vapply(0:k,function(j)count_alloc(d-1,k-j),0))}
 put('P_Combinatorics_31',count_alloc(8,3),'Recursive enumeration of indistinguishable-cookie allocations.')
 f49<-function(x,y,z)abs(x+y-z)+abs(x-y+z)+abs(-x+y+z)-abs(x)-abs(y)-abs(z)
 put('P_Inequality_49',f49(0,0,0),'Equality witness; universal lower bound is established by the written triangle-inequality argument.')
 stopifnot(f49(1,1,1)==0)
 for(n in 1:8){x<-rep(1,n);stopifnot(sum(x^(n+1))-prod(x)*sum(x)==0)}
 put('P_Inequality_8',sum(c(1,1)^3)-prod(c(1,1))*2,'Positive equality witnesses; the all-n proof uses convexity and AM-GM, not these finitely many checks.')
 put('P_Inequality_4',(0^2+2)/sqrt(0^2+1),'Equality witness x=0; analytic AM-GM certificate proves optimality.')
 f24<-function(a,b)(a+b)*(a^4+b^4)-(a^2+b^2)*(a^3+b^3)
 g<-expand.grid(a=c(.5,1,2,3),b=c(.5,1,2,3));stopifnot(all(f24(g$a,g$b)==g$a*g$b*(g$a+g$b)*(g$a-g$b)^2))
 put('P_Inequality_24',f24(1,1),'Positive equality witness plus factorization checks; general factorization is supplied in writing.')
 f13<-function(a,b,c)a*a+b*b+c*c-a*b-b*c-a*c-a-b-c
 put('P_Inequality_13',f13(3,3,3),'Feasible equality witness; sum-of-squares identity proves lower bound.')
 f15<-function(a,b,c)a^4+b^4+c^4-a*a*b*c-b*b*a*c-c*c*a*b
 put('P_Inequality_15',f15(1,1,1),'Positive equality witness; weighted AM-GM proof establishes global nonnegativity.')
 f26<-function(a,b)abs(a+b)/(1+abs(a+b))-abs(a)/(1+abs(a))-abs(b)/(1+abs(b))
 put('P_Inequality_26',f26(0,0),'Equality witness; analytic numerator certificate proves global maximum.')
 put('P_Number-Theory_24',(modpow(2,32,641)+1)%%641,'Exact modular exponentiation using integers safely below floating-point precision limits.')
 r<-0;for(i in 1:1980)r<-(10*r+2)%%1982
 put('P_Number-Theory_27',r,'1980 exact digit-by-digit modular updates; no huge-integer conversion.')
 put('P_Number-Theory_71',min(abs(outer(12^(1:6),5^(1:14),'-'))),'Bounded sanity check only; written modular/factorization proof excludes every smaller value for all positive exponents.')
 sq<-(32:99)^2;s<-as.character(sq);valid<-substr(s,1,1)==substr(s,2,2)&substr(s,3,3)==substr(s,4,4)
 stopifnot(sum(valid)==1);put('P_Number-Theory_17',sq[valid],'Exhaustive search of all four-digit squares.')
 put('P_Number-Theory_32',(modpow(3,105,11)+modpow(4,105,11))%%11,'Exact modular exponentiation.')
 a<-10:99;v<-a[(a*a)%%100==a&a!=25];stopifnot(length(v)==1)
 put('P_Number-Theory_12',v,'Exhaustive search over all allowed two-digit integers.')
 mat<-matrix(0L,50,50);for(i in 1:50)mat[i,((i-1+0:2)%%50)+1]<-1L
 stopifnot(all(colSums(mat)%%2==1));put('P_Number-Theory_42',gf2rank(mat),'Full-rank 50x50 GF(2) query matrix and all-ones parity representation; written argument gives adaptive lower bound.')
 isprime<-function(v){if(v<2)return(FALSE);if(v<4)return(TRUE);!any(v%%(2:floor(sqrt(v)))==0)}
 stopifnot(isprime(5));for(n in seq(3,9,2)){b<-2^((n-1)/2);l<-n*n-2*n*b+2*b*b;h<-n*n+2*n*b+2*b*b;stopifnot(l>1,h>1,l*h==n^4+4^n)}
 put('P_Number-Theory_67',sum(vapply(1:9,function(n)isprime(n^4+4^n),TRUE)),'Small-n sanity check only; written factorization covers all remaining n through 99.')
 put('P_Number-Theory_13',min(abs(outer(36^(1:6),5^(1:14),'-'))),'Bounded sanity check only; analytic proof rules out all differences below 11.')
 a<-rep(0,21);a[seq(1,21,5)]<-1;r<-poly_rem(a,rep(1,5));stopifnot(length(r)==1)
 put('P_Polynomial_32',r,'Exact coefficient-vector polynomial long division.')
 a<-rep(0,43);a[seq(1,43,7)]<-1;r<-poly_rem(a,rep(1,7));stopifnot(length(r)==1)
 put('P_Polynomial_23',r,'Exact coefficient-vector polynomial long division.')
 derivative_at_minus_one<-function(a)5*(-1)^4-2*a*(-1)-a
 a<- -derivative_at_minus_one(0)/(derivative_at_minus_one(1)-derivative_at_minus_one(0));stopifnot(derivative_at_minus_one(a)==0,(-1)^5-a*(-1)^2-a*(-1)+1==0)
 put('P_Polynomial_50',a,'Solve the affine derivative equation; check both polynomial and derivative at -1.')
 t<-(-3+sqrt(5))/2;v<-t*(t+1)*(t+2)*(t+3);stopifnot(abs(v+1)<1e-12)
 put('P_Polynomial_24',round(v),'Attainment at the algebraic witness, checked numerically; analytic completed square proves the bound.')
 for(n in 1:20){a<-rep(0,n+2);a[1]<-1;a[n+1]<- -(n+1);a[n+2]<-n;stopifnot(identical(poly_rem(a,c(1,-2,1)),0))}
 put('P_Polynomial_1',poly_rem(c(1,0,-3,2),c(1,-2,1)),'Sample exact divisions support, but do not replace, the all-n derivative proof.')
 a<-1;b<-1;put('P_Polynomial_40',a*a+a*b+b*b-3*a-3*b,'Equality witness; positive-definite quadratic identity proves global minimum.')
 coefficient<-sum(vapply(2:9,function(k)(-1)^k*choose(k,2)*(-1)^(k-2),0))
 put('P_Polynomial_47',coefficient,'Direct binomial expansion of every summand under x=y-1.')
 put('P_Polynomial_17',0,'Analytical result from the written continuity proof; not a computational enumeration of polynomials.')
 s<-c(2,1);for(n in 2:120)s[n+1]<-(6*s[n]-s[n-1])%%5
 put('P_Polynomial_11',sum(s[(61:120)+1]==4),'Exact modular recurrence at every requested index.')
 A<-matrix(c(1/2,1/3,1/2,2/3),2,2);stopifnot(max(abs(c(-1,1)%*%A-c(-1,1)/6))<1e-15,max(abs(c(2,3)%*%A-c(2,3)))<1e-15)
 put('P_Sequence_28',0,'Coefficient identities validate contraction and invariant; limit result follows analytically, not from a rounded simulation.')
 people<-1:1324;next_pos<-1L;while(length(people)>1){remove<-(next_pos%%length(people))+1L;people<-people[-remove];next_pos<-if(remove>length(people))1L else remove}
 put('P_Sequence_42',people,'Independent circular elimination simulation.')
 put('P_Sequence_20',permanent_allowed(10),'Exact permitted-position permanent by subset DP.')
 x1<-.5;x2<-x1*x1+x1;x3<-x2*x2+x2;stopifnot(x3==21/16,x3>1)
 put('P_Sequence_11',1,'Strict analytic bounds 1<S_100<2; do not round 2-1/x_101 or treat an infinite-precision limit as a finite value.')
 s<-c(0,1);for(n in 0:48)s[n+3]<-2*s[n+2]-s[n+1]+2;stopifnot(all(s==(0:50)^2))
 put('P_Sequence_21',s[51],'Exact second-difference recurrence; written derivation shows equivalence to the original conditions.')
 s<-c(1,1,-1);for(n in 4:1964)s[n]<-s[n-1]*s[n-3]
 put('P_Sequence_19',s[1964],'Exact sign recurrence through the requested index.')
 put('P_Sequence_40',permanent_allowed(10,TRUE),'Independent permanent DP with circular allowed positions; does not reuse the supplied Fibonacci formula.')
 out
}
