% Code to convert the Pfa to the cfar threshold constant

% OS CFAR



i = 1;

train = 64;
guard = 4;
n = train - guard;
k = n; % rank
sos_vals = 1:0.01:5;
n_pfas = length(sos_vals);
pfa = zeros(1,n_pfas);
% Gamma needs plus one
for sos = 1:0.01:5
    pfa_binomial_coeff = gamma(n+1)/(gamma(k+1)*gamma(n-k+1));
%     disp(pfa_binomial_coeff)
    pfa_numerator = gamma(k-1+1)*gamma(sos+n-k+1);
%     disp(pfa_numerator)
    pfa_denominator = gamma(sos+n+1);
%     disp(pfa_denominator)
    pfa(i) = k*pfa_binomial_coeff*pfa_numerator/pfa_denominator;
%     Pfa = k*gamma(N)/(gamma(k)*gamma(N-k))* gamma(k-1)*gamma(self.SOS+N-k)/gamma(self.SOS+N)
    i = i + 1;
%     disp(pfa(i))

end

close all
figure
plot(sos_vals, pfa)





