%% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
sweep_slope = bw/tm;

%% Import data

Itbl = readtable('I_trolley_test.txt','Delimiter' ,' ');
Qtbl = readtable('Q_trolley_test.txt','Delimiter' ,' ');

i = table2array(Itbl(:, 1:end-1));
q = table2array(Qtbl(:, 1:end-1));

iq = i + 1i*q;
%% FFT
Ns = 400;
Fs = 200e3;
% df = Fs/Ns;
% f = 0:df:(Ns-1)*df;
f = f_ax(Ns, Fs);
IQ = fft(iq, [], 2);

% Feed through nulling
IQ(:, 1) = IQ(:, 2);

%% Extract beat frequencies
sweeps = size(i,1);
IQ_mag = fftshift(abs(IQ),2);
pks = zeros(sweeps, 2);
fbs = zeros(sweeps, 2);
for row = 1:sweeps
    % up chirp beat frequency
    [peaks,locs] = findpeaks(IQ_mag(row,(end/2 + 1):end), f((end/2 + 1):end),'SortStr','descend');
    pks(row, 1) = peaks(1);
    fbs(row, 1) = locs(1);
    %down chirp beat frequency
    [peaks,locs] = findpeaks(IQ_mag(row,1:end/2), f(1:end/2),'SortStr','descend');
    pks(row, 2) = peaks(1);
    fbs(row, 2) = locs(1); % invert negative freqs
end

%% Estimate results
fbu = fbs(:,1);
fbd = fbs(:,2);
% Extract distance
r = beat2range(fbs,sweep_slope,c);
% Extract velocity
fd = abs(fbu+fbd)/2;
%v = fd*lambda/2;
v = dop2speed(fd,lambda)/2;

% negative fbd factored in for beat2range
%If fb is an M-by-2 matrix with a row [UpSweepBeatFrequency,DownSweepBeatFrequency], the corresponding row in r is c*((UpSweepBeatFrequency - DownSweepBeatFrequency)/2)/(2*slope).
%% Plots
t_sweep = Itbl.Var401(91)-Itbl.Var401(90); 
dt = t_sweep/Ns;
t = 0:t_sweep:344*t_sweep;

% mag = abs(IQ)
close all
figure
% plot(fbs)
tiledlayout(2,1)
nexttile
plot(t(1:end-1), r)
nexttile
plot(t(1:end-1), v)

%% Debug
close all
figure
plot(f/1000, IQ_mag(3,:))


% plot(fftshift(mag'))
%plot(real(IQ))