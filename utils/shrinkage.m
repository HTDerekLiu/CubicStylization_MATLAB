function z = shrinkage(x, k)
%{
    SHRINKAGE is the standard shrinkage operator 
    
    Reference:
    Tibshirani, "Regression shrinkage and selection via the lasso", 1996

    S_k(a) = 
    \bagin{cases}
        a-k , when  a  > 0
        0,    when |a| < k
        a+k,  when  a  < 0
    \end{cases}
%}
    z = max( 0, x - k ) - max( 0, -x - k );
end