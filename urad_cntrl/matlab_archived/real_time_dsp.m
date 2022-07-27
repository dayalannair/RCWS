%% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
sweep_slope = bw/tm;

%% Import data
iq_tbl=readtable('IQ.txt','Delimiter' ,' ');
time = iq_tbl.Var801;
i_up = table2array(iq_tbl(:,1:200));
i_down = table2array(iq_tbl(:,201:400));
q_up = table2array(iq_tbl(:,401:600));
q_down = table2array(iq_tbl(:,601:800));

iq_up = i_up + 1i*q_up;
iq_down = i_down + 1i*q_down;


%% FFT

% Ns = 400;
% iq = padarray(iq,[0 4096 - Ns], 'post');
Ns = size(iq_up, 2);
Fs = 200e3;
f = f_ax(Ns, Fs);
gwin = gausswin(Ns);

IQ_UP = fftshift(fft(iq_up,[],2),2);
IQ_DOWN = fftshift(fft(iq_down,[],2),2);
% close all
% figure
% plot(f, abs(IQ))
%%
noise_level = 75; % dB
signal_level = 85;
SNR = signal_level/noise_level;
disp(SNR)

%% Extract peaks
sweeps = size(i_up,1);
IQ_UP_mag = abs(IQ_UP);
IQ_DOWN_mag = abs(IQ_DOWN);
pks = zeros(sweeps, 2);
fbs = zeros(sweeps, 2);
freq_res = Fs/Ns; % Minimum separation between two targets
%% View peak detection
% close all
% figure
% %'MinPeakWidth',5*freq_res,
% % Specifying a minimum peak height can reduce processing time.
% % Prominence is roughly SNR
%findpeaks(IQ_mag(162,:), f,'MinPeakProminence',20, 'NPeaks', 3,'Annotate','extents');
%findpeaks(IQ_mag(162,:), f,'Annotate','extents')
%%
% Note: MinPeakDistance uses sort(descend) anyway
% "SortStr","descend"
close all
% figure
% tiledlayout(2,1);
% fbu = zeros(sweeps,1);
% fbd = zeros(sweeps,1);
rng_array = zeros(sweeps,2);
spd_array = zeros(sweeps,2);
% nexttile
% plot(rng_array)
% nexttile
% plot(spd_array)
fbu = zeros(2, 1);
fbd = zeros(2, 1);

% 2xcols for up and down beat frequencies
fb_array_targ1 = zeros(sweeps, 2);
fb_array_targ2 = zeros(sweeps, 2);

IQ_UP_mag(:, 1) = IQ_UP_mag(:, 2);
for row = 1:sweeps
    % Plot peak detection
    % ------------------------------------------------------
    pause(1)

    % tx feed through filter
    IQ_UP_mag(row,96:106) = 0;
    IQ_DOWN_mag(row,96:106) = 0;

    figure(1)
    findpeaks(IQ_UP_mag(row,:), f/1000, 'MinPeakDistance', 1.500, ...
     'MinPeakProminence',1e3, ...
     'MinPeakHeight',3e3, ...
     'MinPeakWidth', .500, ...
     'NPeaks', 2, ...
     'Annotate','extents');
    axis([-100.000 100.000 0 40e3])
    
    %      figure(2)
    hold on
    findpeaks(IQ_DOWN_mag(row,:), f/1000, 'MinPeakDistance', 1.500, ...
     'MinPeakProminence',1e3, ...
     'MinPeakHeight',3e3, ...
     'MinPeakWidth', .500, ...
     'NPeaks', 2, ...
     'Annotate','extents');
    axis([-100.000 100.000 0 40e3])
    
    hold off
    % ------------------------------------------------------------------------
    [peaku, frequ] = findpeaks(IQ_UP_mag(row,:), f, ...
     'MinPeakDistance', 1500, ...
     'MinPeakProminence',1e3, ...
     'MinPeakHeight',3e3, ...
     'MinPeakWidth', 500, ...
     'NPeaks', 2);
    
    [peakd, freqd] = findpeaks(IQ_DOWN_mag(row,:), f, ...
     'MinPeakDistance', 1500, ...
     'MinPeakProminence',1e3, ...
     'MinPeakHeight',3e3, ...
     'MinPeakWidth', 500, ...
     'NPeaks', 2);
    
   % if and(numel(peaku)>1,numel(peakd)>1) % need peaks in both for now
    % padding arrays
%      fbu = zeros(2, 1);
%      fbd = zeros(2, 1);
     % pad in the event only one target detected
     fbu = padarray(frequ,2-numel(frequ),0,'post');
     fbd = padarray(freqd,2-numel(freqd),0,'post');
     % sort peaks from highest SNR to lowest
     % speed determined by num peaks
     fbu = sort(fbu, 1, 'ascend')'; % CHECK THIS
     fbd = sort(fbd, 1, 'descend')'; % negative frequencies
     
     

     fb_array_targ1(row, :) = [fbu(1) fbd(1)];
     fb_array_targ2(row, :) = [fbu(2) fbd(2)];
     % find index of first peak - highest value is tx feed through
%      idxu = find(peaku==pku_sorted(2));
%      idxd = find(peakd==pkd_sorted(2));
    
     % use peak index to find beat frequencies   
%      fbu(1) = frequ(idxu);
%      fbd = freqd(idxd);
     r = beat2range([fbu fbd],sweep_slope,c)
     rng_array(row, :) = r';%beat2range([fbu fbd],sweep_slope,c)
     fd = (-fbd-fbu)/2;
     v = dop2speed(fd,lambda)/2
     if (v<25)
         spd_array(row, :) = v;
     end
     %figure(3)
    %          plot(rng_array)
    %          figure(4)
    %          plot(spd_array)
     % NOTE: multi targets will be problematic. Cannot assign beat
     % frequencies to correct targets, therefore ghosts possible
     % try dual rate for multi target, or sawtooth
    %end
     
end
%% Plot estimates
t_total = time(end)-time(1);
t = linspace(0,t_total, size(r, 1));
close all
figure
tiledlayout(2,1)
nexttile
plot(t, rng_array);
ylabel("Radial distance (m)")
xlabel("Time (s)")
nexttile
plot(t, spd_array);
ylabel("Radial velocity (m/s)")
xlabel("Time (s)")
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














