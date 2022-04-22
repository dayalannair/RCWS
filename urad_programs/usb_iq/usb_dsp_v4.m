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

% samples before padding
% Ns = 200;
Fs = 200e3;

% Zero padding

% u = padarray(u,[0 2*4096 - Ns], 'post');
% d = padarray(d,[0 2*4096 - Ns], 'post');

% Samples after padding
Ns = size(u, 2);
df = Fs/Ns; %frequency resolution = sampling rate/FFT size
f = 0:df:(Ns-1)*df;

% Guassian window
% gwin = gausswin(Ns);
% u = u.*gwin';
% d = d.*gwin';

% Row-wise FFT
U = fft(u,[],2);
D = fft(d,[],2);

% Null transmitter feed-through
% positive and negative null factors
% needed to increase nulling width as padding is increased
pnf = 1;%20*2;
nnf = 1;%20*2;
U(:,1:pnf) = repmat(U(:,pnf+1), 1, pnf);
D(:,1:pnf) = repmat(D(:,pnf+1), 1, pnf);

% U(:,end-nnf:end) = repmat(U(:,end-nnf+1), 1, nnf+1);
% D(:,end-nnf:end) = repmat(D(:,end-nnf+1), 1, nnf+1);

% Easiest method for extracting down chirp peaks is to flip
% each sweep
D = flip(D, 2);
% "Low pass filter" values above maximum beat frequency
% fb_max = 100 kHz, which is midpt frequency
U = U(:, 1:end/2);
D = D(:, 1:end/2);

% Extract FFT peaks in each row
[pk_u, idx_u]= max(U,[],2);


[pk_d, idx_d] = max(D,[],2);

% inter_bin = pk_u(1) + log(U(1,idx_u(1)+1)/U(1,idx_u(1)-1))*0.5/log(U(1,idx_u(1)*U(1,idx_u(1)))/(U(1,idx_u(1)+1)*U(1,idx_u(1)-1)));
% freq = df*inter_bin;
%idx_d = abs(idx_d-Ns+1);

% Extract beat frequencies at indices - verified
fbu = f(idx_u)';

% Negative is needed s.t. fb = |fbd - fbu|/2 doesnt cancel if both
% have the same beat frequency
% i.e. beat frequency of down chirp is negative.
% This would be already negative if ifft f_ax was used.
fbd = f(idx_d)'; 

%% Estimate results

% Extract distance
r = beat2range([fbu -fbd],sweep_slope,c);
% Extract velocity
fd = -(fbu-fbd)/2;
%v = fd*lambda/2;
v = dop2speed(fd,lambda)/2;

%% Filter spikes
% Need to find cause
% After "LPF" some spikes get through
% plotting these waves, it seems the target was not detected at all
% the resulting peak is from noise/clutter
%
% average rate of acceleration of all the ordinary cars I found was between
% 3 and 4 m/s^2

i = 1;
total_time = I.Var401(end) - I.Var401(1);
sweeps = size(u, 1);

% NEED TO VERIFY THE EXPECTED MAX DIFFERENCES
t_avg = total_time/sweeps;
a_avg = 3.5; % avg car acceleration in m/s
%v_diff_max = 2*a_avg*t_avg;
v_diff_max = 3;
v_max = 80/3.6; % assume max speed 80 km/h
r_diff_max = v_max*t_avg;
while i+1<(sweeps)
%     if abs(abs(v(i+1))-abs(v(i)))> v_diff_max
%         v(i+1) = v(i);
%     end
    if r(i+1)-r(i)> r_diff_max
        r(i+1) = r(i);
    end
    i = i+1;

end

% rmax = 10; % max distance is 10 m
% for i = 1:size(v,1)
%     % if v changes by > 100 m/s
%     if abs(v(i))>rmax
%         v(i) = 0;
%     end
%     % if r changes by > 50 m
%     if r(i)>rmax
%         r(i) = 0;
%     end 
% end
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

%% Debugging
% close all 
% figure
% plot(abs(D(338,:)))
% hold on
% plot(abs(D(339,:)))
% 





