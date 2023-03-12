import mpmath as mt

N = 256
train = 32
k = train
SOS = 100

Pfa_numer = k*mt.gamma(N)* mt.gamma(k-1)*mt.gamma(SOS+N-k)
Pfa_denom = (mt.gamma(k)*mt.gamma(N-k))*mt.gamma(SOS+N)
Pfa = Pfa_numer/Pfa_denom
# Pfa = k*mt.gamma(N)/(mt.gamma(k)*mt.gamma(N-k))* mt.gamma(k-1)*mt.gamma(SOS+N-k)/mt.gamma(SOS+N)

print(Pfa)