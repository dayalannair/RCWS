%% Parameters
fc = 24.005e9;
c = 3e8;
lambda = c/fc;
tm = 1e-3;
bw = 240e6;
sweep_slope = bw/tm;

%% Import data

I = readtable('I_trolley_test.txt','Delimiter' ,' ');
Q = readtable('Q_trolley_test.txt','Delimiter' ,' ');

I_up = table2array(I(:, 1:(end-1)/2));
I_down = table2array(I(:, (end-1)/2 + 1:end-1));

Q_up = table2array(Q(:, 1:(end-1)/2));
Q_down = table2array(Q(:, (end-1)/2 + 1:end-1));

u = I_up + 1i*Q_up;
d = I_down + 1i*Q_down;

%% Extract beat frequency

Ns = 200;
Fs = 200e3;

% Zero padding
sweeps = size(u, 1)
u = padarray(u,[0 2*4096 - Ns], 'post');
d = padarray(d,[0 2*4096 - Ns], 'post');

% new parameters
Ns = size(u, 2);
df = Fs/Ns;
f = 0:df:(Ns-1)*df;

% Row-wise FFT
U = fft(u,[],2);
D = fft(d,[],2);

% Null transmitter feed-through
% positive and negative null factors
% needed to increase nulling width as padding is increased
pnf = 20*4;
nnf = 20*4;
U(:,1:pnf) = repmat(U(:,pnf+1), 1, pnf);
D(:,1:pnf) = repmat(D(:,pnf+1), 1, pnf);

U(:,end-nnf:end) = repmat(U(:,end-nnf+1), 1, nnf+1);
D(:,end-nnf:end) = repmat(D(:,end-nnf+1), 1, nnf+1);
% Extract FFT peaks in each row
[pk_u, idx_u]= max(U,[],2);

% Easiest method for extracting down chirp peaks is to flip
% each sweep
D = flip(D, 2);
[pk_d, idx_d] = max(D,[],2);

%idx_d = abs(idx_d-Ns+1);

% Extract beat frequencies at indices - verified
fbu = f(idx_u)';

% Negative is needed s.t. fb = |fbd - fbu|/2 doesnt cancel if both
% have the same beat frequency
% i.e. beat frequency of down chirp is negative.
% This would be already negative if ifft f_ax was used.
fbd = -f(idx_d)'; 

% Extract distance
r = beat2range([fbu fbd],sweep_slope,c);
% Extract velocity
fd = (fbu+fbd)/2;
v= fd*lambda/2;
%v = dop2speed(fd,lambda)/2;

%% Filter spikes
rmax = 10; % max distance is 10 m
for i = 1:size(v,1)
    % if v changes by > 100 m/s
    if abs(v(i))>rmax
        v(i) = 0;
    end
    % if r changes by > 50 m
    if r(i)>rmax
        r(i) = 0;
    end 
end
%% Plots
% t_sweep = I.Var401(91)-I.Var401(90); 
% dt = t_sweep/Ns;
% t = 0:dt:t_sweep;

close all
figure
tiledlayout(2,1)
% plot(f, abs(U(90,:)))

nexttile
plot(r)
nexttile
plot(v)






