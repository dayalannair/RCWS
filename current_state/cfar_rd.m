%% Cell Averaging CFAR (Constant False Alarm Rate) peak detector
% Most basic/common CFAR algorithm
%% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
sweep_slope = bw/tm;

%% Import data
%subset = 1:1024;%200:205;
subset = 1:8192;%200:205;
%iq_tbl=readtable('trig_fmcw_data\IQ_0_1024_sweeps.txt','Delimiter' ,' ');
iq_tbl=readtable('trig_fmcw_data\IQ_0_8192_sweeps.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ.txt','Delimiter' ,' ');
time = iq_tbl.Var801;
i_up = table2array(iq_tbl(subset,1:200));
i_down = table2array(iq_tbl(subset,201:400));
q_up = table2array(iq_tbl(subset,401:600));
q_down = table2array(iq_tbl(subset,601:800));

iq_up = i_up + 1i*q_up;
iq_down = i_down + 1i*q_down;

%% CA-CFAR + Gaussian Window
% Gaussian Window
% remember to increase fft point size
n_samples = size(i_up,2);
n_sweeps = size(i_up,1);
gwin = gausswin(n_samples);
iq_up = iq_up.*gwin.';
iq_down = iq_down.*gwin.';
% FFT
n_fft = 1024;%512;
% factor of signal to be nulled. 4% determined experimentally
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);
nul_lower = round(n_fft/2 - num_nul);
nul_upper = round(n_fft/2 + num_nul);

IQ_UP = fftshift(fft(iq_up,n_fft,2));
IQ_DOWN = fftshift(fft(iq_down,n_fft,2));

% from 20/200 = 0.1
train_factor = 0.1;
% from 4/200 = 0.02;
guard_factor = 0.02;
guard = round(n_fft*guard_factor);
train = round(n_fft*train_factor);
% false alarm rate - sets sensitivity
F = 0.011; % see relevant papers

% Assumes AWGN
% research options
% 4 bins -> car is 2m, bin is 0.6
% try with simulated data and noise & clutter
CFAR = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA');

% modify CFAR code to simultaneously record beat frequencies
up_detections = CFAR(abs(IQ_UP)', 1:n_fft);
down_detections = CFAR(abs(IQ_DOWN)', 1:n_fft);

fs = 200e3; %200 kHz
f = f_ax(n_fft, fs);
IQ_UP_peaks = abs(IQ_UP).*up_detections';
IQ_DOWN_peaks = abs(IQ_DOWN).*down_detections';


%%
% v_max = 60km/h , fd max = 2.7kHz approx 3kHz
v_max = 60/3.6; 
%fd_max = speed2dop(v_max, lambda)*2;
fd_max = 3e3;
fb = zeros(n_sweeps,2);
%fbd = zeros(n_sweeps,2);
% Each sample can return a detection - max number of targets is 200?
% beat2range - expects a set of beat freqs up and down
% NB: MATLAB makes square matrix by default
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);

for i = 1:n_sweeps
    
    % SINGLE TARG:
    % null feed through
    IQ_UP_peaks(i,nul_lower:nul_upper) = 0;
    IQ_DOWN_peaks(i,nul_lower:nul_upper) = 0;
    
    [highest_SNR_up, pk_idx_up]= max(IQ_UP_peaks(i,:));
    [highest_SNR_down, pk_idx_down] = max(IQ_DOWN_peaks(i,:));

    fb(i, 1) = f(pk_idx_up);
    fb(i, 2) = f(pk_idx_down);

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
    if and(abs(fd)<=fd_max, fd > 400)
        fd_array(i) = fd/2;
        speed_array(i) = dop2speed(fd/2,lambda)/2;
        range_array(i) = beat2range([fb(i,1) fb(i,2)], sweep_slope, c);
    end
end
% Determine range
% range_array = beat2range([ ])


