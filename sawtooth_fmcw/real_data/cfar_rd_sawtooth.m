%% Cell Averaging CFAR (Constant False Alarm Rate) peak detector
% Most basic/common CFAR algorithm
%% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
sweep_slope = bw/tm;
addpath('../../library/');
%% Import data
subset = 1:512;%200:205;

iq_tbl=readtable('../../data/urad_usb/IQ_sawtooth.txt','Delimiter' ,' ');
%time = iq_tbl.Var401;
i_dat = table2array(iq_tbl(subset,1:200));
q_dat = table2array(iq_tbl(subset,201:400));
iq = i_dat + 1i*q_dat;
%% CA-CFAR + Gaussian Window
% Gaussian Window
% remember to increase fft point size
n_samples = size(i_dat,2);
n_sweeps = size(i_dat,1);
gwin = gausswin(n_samples);
%iq = iq.*gwin.';

% FFT
n_fft = 1024;%512;
% factor of signal to be nulled. 4% determined experimentally
%IQ_UP = fftshift(fft(iq,n_fft,2));
IQ2D = fft2(iq.');

%%
% CFAR
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);
nul_lower = round(n_fft/2 - num_nul);
nul_upper = round(n_fft/2 + num_nul);
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
CFAR = phased.CFARDetector2D('TrainingBandSize',[20 20], ...
    'GuardBandSize',[4 2], ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA', ...
    'ThresholdOutputPort', true);

% modify CFAR code to simultaneously record beat frequencies
%[1:n_sweeps; 1:n_samples]
% rowidx = 1:n_sweeps;
% colidx = 1:n_samples;
% cutidx = [rowidx; colidx];
%cutidx = zeros(2, )
cutidx = [];
for m = 1:n_sweeps
    for n = 1:n_samples
        cutidx = [cutidx,[n;m]];
    end
end
ncutcells = size(cutidx,2)

%%
[up_detections, upth] = CFAR(abs(IQ2D)', cutidx);
% fs = 200e3; %200 kHz
% f = f_ax(n_fft, fs);
% IQ_UP_peaks = abs(IQ_UP).*up_detections';

%%
% v_max = 60km/h , fd max = 2.7kHz approx 3kHz
v_max = 60/3.6; 
%fd_max = speed2dop(v_max, lambda)*2;
fd_max = 3e3;
fb = zeros(n_sweeps,1);
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);

% for i = 1:n_sweeps
%     
%     % SINGLE TARG:
%     % null feed through
%     IQ_UP_peaks(i,nul_lower:nul_upper) = 0;
%     
%     [highest_SNR_up, pk_idx_up]= max(IQ_UP_peaks(i,:));
% 
%     fb(i) = f(pk_idx_up);
%     
%     % hack for bad CFAR
%     if fb(i)>0
%         range_array(i) = beat2range(fb(i), sweep_slope, c);
%     else
%         range_array(i) = range_array(i-1);
%     end
% end
% Determine range
% range_array = beat2range([ ])


