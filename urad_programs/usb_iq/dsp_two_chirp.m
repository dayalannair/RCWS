%% Extract IQ data from text files
% I and Q is interleaved in raw data
I = readtable('I_trolley_test.txt','Delimiter' ,' ');
Q = readtable('Q_trolley_test.txt','Delimiter' ,' ');

I_up = table2array(I(:, 1:(end-1)/2));
I_down = table2array(I(:, (end-1)/2 + 1:end-1));

Q_up = table2array(Q(:, 1:(end-1)/2));
Q_down = table2array(Q(:, (end-1)/2 + 1:end-1));

% Extract 2 chirps
u = I_up(90:91,:) + 1i*Q_up(90:91,:);
d = I_down(90:91,:) + 1i*Q_down(90:91,:);

%% 

c = physconst('LightSpeed');
fc = 24.005e9;
lambda = c/fc;
tm = 1e-3;
bw = 240e6;
sweep_slope = bw/tm;

Ns = size(u, 2);
Fs = 200e3;
f_ftshf = f_ax(Ns,1/Fs)/1000; % kHz
df = Fs/Ns;
f = 0:df:(Ns-1)*df;

t_sweep = I.Var401(91)-I.Var401(90); 
dt = t_sweep/Ns;
t = 0:dt:t_sweep;

U = fft(u,[],2);
D = fft(d,[],2);

U(:,1) = U(:,2);
D(:,1) = D(:,2);


peak1u = max(U(1,:));
index1u = find(fftshift(U(1,:))== peak1u);
fbu1 = f(index1u)*1000;

peak1d = max(D(1,:));
index1d = find(fftshift(D(1,:))== peak1d);
fbd1 = f(index1d)*1000;

rng_ests = beat2range([fbu1 fbd1],sweep_slope,c)
fds = -(fbu1+fbd1)/2;
v_ests = dop2speed(fds,lambda)/2

%% Plots
figure
tiledlayout(2,2)
nexttile
plot(t(1:end-1), real(u))
title("Two consecutively received up chirps");
xlabel("Time (s)")
ylabel("Amplitude (bits)")
nexttile
plot(f/1000, 10*log(abs(U)))
title("Spectrum of two consecutively received up chirps");
xlabel("Frequency (kHz)")
ylabel("Magnitude (dB)")
nexttile
plot(t(1:end-1), real(d))
title("Two consecutively received down chirps");
xlabel("Time (s)")
ylabel("Amplitude (bits)")
nexttile
plot(f_ftshf, 10*log(fftshift(abs(D))))
title("Spectrum of two consecutively received down chirps");
xlabel("Frequency (kHz)")
ylabel("Magnitude (dB)")