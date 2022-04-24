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
f = f_ax(Ns, Fs);

t_sweep = Itbl.Var401(91)-Itbl.Var401(90); % Should average this 
dt = t_sweep/Ns;
t = 0:t_sweep:344*t_sweep;

IQ = fftshift(fft(iq,[],2),2);

noise_level = 75; % dB
signal_level = 85;
SNR = signal_level/noise_level;
disp(SNR)

%% Extract peaks
sweeps = size(i,1);
IQ_mag = abs(IQ);
pks = zeros(sweeps, 2);
fbs = zeros(sweeps, 2);
freq_res = Fs/Ns; % Minimum separation between two targets

% Note: MinPeakDistance uses sort(descend) anyway
for row = 1:sweeps
    % Extract the three tallest peaks
    [peak, freq] = findpeaks(IQ_mag(row,:), f, "SortStr","descend", "NPeaks", 3);
    % Ignore first peak due to feed through
    pks(row,:) = peak(2:3);
    fbs(row,:) = freq(2:3);
end

%% Plot peaks
close all
figure
plot(fbs,pks);

%% Real-time view
% close all
% figure
% plot(f, 10*log(abs(IQ(50,:))))
% for row = 1:344
%     plot(f, 10*log(abs(IQ(row,:))))
%     yline(signal_level)
%     yline(noise_level)
%     pause(0.1)
% end














