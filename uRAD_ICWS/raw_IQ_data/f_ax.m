function f = f_ax(p, delta_t)
    n = length(p);
    delta_f = 1/(n*delta_t);
    if mod(n,2)==0    % case N even
        f = (-n/2:n/2-1)*delta_f;    
    else   % case N odd
        f = (-(n-1)/2 : (n-1)/2)*delta_f; 
    end
end