
subset = 1:512;%200:205;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
n_samples = size(i_up,2);
n_sweeps = size(i_up,1);

% Taylor Window
nbar = 4;
sll = -38;
twinu = taylorwin(n_samples, nbar, sll);
twind = taylorwin(n_samples, nbar, sll);
iq_u = iq_u.*twinu.';
iq_d = iq_d.*twind.';

% FFT
n_fft = 1024;%512;
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

IQ_UP = fft(iq_u,n_fft,2);
IQ_DN = fft(iq_d,n_fft,2);

% Halve FFTs
IQ_UP = IQ_UP(:, 1:n_fft/2);
IQ_DN = IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
IQ_UP(:, 1:num_nul) = 0;
IQ_DN(:, end-num_nul+1:end) = 0;

% CFAR
guard = 2*n_fft/n_samples;
guard = floor(guard/2)*2; % make even
% too many training cells results in too many detections
train = round(20*n_fft/n_samples);
train = floor(train/2)*2;
% false alarm rate - sets sensitivity
F = 10e-3; 

OS = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',train);

% Filter peaks/ peak detection
[up_os, os_thu] = OS(abs(IQ_UP)', 1:n_fft/2);
[dn_os, os_thd] = OS(abs(IQ_DN)', 1:n_fft/2);

% Find peak magnitude/SNR
os_pku = abs(IQ_UP).*up_os';
os_pkd = abs(IQ_DN).*dn_os';

% Define frequency axis
fs = 200e3;
f = f_ax(n_fft, fs);


%%
% v_max = 60km/h , fd max = 2.7kHz approx 3kHz
v_max = 60/3.6; 
%fd_max = speed2dop(v_max, lambda)*2;
fd_max = 3e3;
fb = zeros(n_sweeps,2);
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);
count = 0;
% close all
% figure
for i = 1:n_sweeps
    
    [magu, idx_u]= max(os_pku(i,:));
    [magd, idx_d] = max(os_pkd(i,:));
%     plot(IQ_UP_peaks(i,round(n_fft/2 + 1):end))
%     xline(pk_idx_up)
%     drawnow;
%     pause(1)
%     pk_idx_up
%     f(pk_idx_up)
    fb(i, 1) = f(512+pk_idx_up);
    fb(i, 2) = f(pk_idx_down);
%     count = 0;
%     while ((fb(i, 1)<0)||(fb(i, 2)>0))
%         IQ_UP_peaks(i,pk_idx_up) = 0;
%         IQ_DOWN_peaks(i,pk_idx_down) = 0;
%         [highest_SNR_up, pk_idx_up]= max(IQ_UP_peaks(i,:));
%         [highest_SNR_down, pk_idx_down] = max(IQ_DOWN_peaks(i,:));
%         fb(i, 1) = f(pk_idx_up);
%         fb(i, 2) = f(pk_idx_down);
%         count = count + 1;
%     end
    fd = -fb(i,1)-fb(i,2);
    % ensuring Doppler shift is within the maximum expected value also
    % serves to eliminate incorrect pairing of beat frequencies, which
    % affects both range and Doppler estimation
    % implement MTI condition: fd ~= 0
    % MTI + negative Doppler filter: fd > 0
    % 100 is the new min after Gaussian windowing
    % 200 is before the division by 2. carrying out division in
    % conditional statement is more comp efficient
    % 400 used for 195 fd
%     if and(abs(fd)<=fd_max, fd > 400)
        fd_array(i) = fd/2;
        speed_array(i) = dop2speed(fd/2,lambda)/2;
        range_array(i) = beat2range([fb(i,1) fb(i,2)], sweep_slope, c);
%     end
end
% Determine range
% range_array = beat2range([ ])


