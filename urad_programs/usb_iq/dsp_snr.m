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
%iq = padarray(iq,[0 4096 - Ns], 'post');
Ns = size(iq, 2);
Fs = 200e3;
f = f_ax(Ns, Fs);

t_sweep = Itbl.Var401(91)-Itbl.Var401(90); % Should average this 
dt = t_sweep/Ns;
t = 0:t_sweep:344*t_sweep;

gwin = gausswin(Ns);



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
%% View peak detection
close all
figure
% %'MinPeakWidth',5*freq_res,
% % Specifying a minimum peak height can reduce processing time.
% % Prominence is roughly SNR
%findpeaks(IQ_mag(162,:), f,'MinPeakProminence',20, 'NPeaks', 3,'Annotate','extents');
%findpeaks(IQ_mag(162,:), f,'Annotate','extents')
%%
% Note: MinPeakDistance uses sort(descend) anyway
% "SortStr","descend"
% close all
% figure
fbu = zeros(344,1);
fbd = zeros(344,1);
for row = 1:sweeps
    %Extract the three tallest peaks
%     pause(0.08)
%     findpeaks(IQ_mag(row,:), f/1000, 'MinPeakDistance', 1,'MinPeakProminence',3e4,'MinPeakHeight',0.5e4,'MinPeakWidth', 1, 'NPeaks', 4,'Annotate','extents');
%     axis([-100 100 0 40e4])
    [peak, freq] = findpeaks(IQ_mag(row,:), f, 'MinPeakDistance', 1500,'MinPeakProminence',1e4,'MinPeakHeight',0.5e4,'MinPeakWidth', 1000, 'NPeaks', 4);
    % Ignore first peak due to feed through
        % Extract beat frequencies. Middle peak is from feed through
     if (numel(peak)>1)
         pk_sorted = sort(peak, 2, 'descend');
         idx = find(peak==pk_sorted(1));
         fq = freq(idx);
         if fq>1
            fbu(row) = fq;
            idx = find(peak==pk_sorted(2));
            fbd(row) = freq(idx);
         else
             fbd(row) = fq;
            idx = find(peak==pk_sorted(2));
            fbu(row) = freq(idx);
         end
     end
end

%% Estimates
% Extract distance
r = beat2range([fbu fbd],sweep_slope,c);
% Extract velocity
fd = (-fbd-fbu)/2;
%v = fd*lambda/2;
v = dop2speed(fd,lambda)/2;
%% Plot estimates
close all
figure
tiledlayout(2,1)
nexttile
plot(r);
nexttile
plot(v);
%% Plot peaks
% close all
% figure
% plot(fbs,pks);

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














