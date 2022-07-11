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
% Import data
subset = 1:1024;%200:205;
Ns = 200;
%subset = 1:8192;%200:205;
addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/m3_dual_11_07_2022/');
iq_tbl=readtable('IQ_dual_240_200_06-24-54.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ.txt','Delimiter' ,' ');
% time = iq_tbl.Var801;
i_up1 = table2array(iq_tbl(subset,1:Ns));
i_dn1 = table2array(iq_tbl(subset,Ns + 1:2*Ns));
q_up1 = table2array(iq_tbl(subset,2*Ns + 1:3*Ns));
q_dn1 = table2array(iq_tbl(subset,3*Ns + 1:4*Ns));

i_up2 = table2array(iq_tbl(subset,4*Ns + 1:4.75*Ns));
i_dn2 = table2array(iq_tbl(subset,4.75*Ns+1:5.5*Ns));
q_up2 = table2array(iq_tbl(subset,5.5*Ns+1:6.25*Ns));
q_dn2 = table2array(iq_tbl(subset,6.25*Ns+1:7*Ns));

iq_up1 = i_up1 + 1i*q_up1;
iq_dn1 = i_dn1 + 1i*q_dn1;

iq_up2 = i_up2 + 1i*q_up2;
iq_dn2 = i_dn2 + 1i*q_dn2;

%% CA-CFAR + Gaussian Window
% Gaussian Window
% remember to increase fft point size
% n_sweeps = size(i_up,1);
gwinu1 = gausswin(200);
gwinu2 = gausswin(150);
gwind1 = gausswin(200);
gwind2 = gausswin(150);

iq_up1 = gwinu1.'.*iq_up1;
iq_dn1 = gwind1.'.*iq_dn1;
iq_up2 = gwinu2.'.*iq_up2;
iq_dn2 = gwind2.'.*iq_dn2;

% FFT
n_sweeps = length(subset);
n_fft1 = 256;%512;
n_fft2 = 256;
% factor of signal to be nulled. 4% determined experimentally
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);
nul_lower = round(n_fft/2 - num_nul);
nul_upper = round(n_fft/2 + num_nul);

% FFT
IQ_UP1 = fft(iq_up1,n_fft1,2);
IQ_DN1 = fft(iq_dn1,n_fft1,2);

IQ_UP2 = fft(iq_up2,n_fft2,2);
IQ_DN2 = fft(iq_dn2,n_fft2,2);

% Halve FFTs
% IQ_UP1 = IQ_UP1(:, 1:n_fft1/2);
% IQ_UP2 = IQ_UP2(:, 1:n_fft2/2);
% 
% IQ_DN1 = IQ_DN1(:, n_fft1/2+1:end);
% IQ_DN2 = IQ_DN2(:, n_fft2/2+1:end);

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
    'Method', 'SOCA');%, ...
%     'OutputFormat', 'Detection index');%, ...
%     'NumDetectionsSource','Property', ...
%     'NumDetections', n_sweeps*n_fft);

% modify CFAR code to simultaneously record beat frequencies
% up_det1 = CFAR(abs(IQ_UP1)', 1:n_fft);
% dn_det1 = CFAR(abs(IQ_DN1)', 1:n_fft);
% 
% up_det2 = CFAR(abs(IQ_UP2)', 1:n_fft);
% dn_det2 = CFAR(abs(IQ_DN2)', 1:n_fft);
%%
IQ_UP1(:, 1:4) = 0;%IQ_UP1(:, 1:4);
IQ_UP2(:, 1:4) = 0;%IQ_UP1(:, 1:4);

IQ_DN1(:, end-4:end) = 0;%IQ_UP1(:, 1:4);
IQ_DN2(:, end-4:end) = 0;%IQ_UP1(:, 1:4);

% GET APPROP TRAIN LENGTH FOR SHORTER TRIG
% up_det1 = CFAR(abs(IQ_UP1)', 1:n_fft1/2);
% dn_det1 = CFAR(abs(IQ_DN1)', 1:n_fft1/2);
% 
% up_det2 = CFAR(abs(IQ_UP2)', 1:n_fft2/2);
% dn_det2 = CFAR(abs(IQ_DN2)', 1:n_fft2/2);

fs = 200e3; %200 kHz
f = f_ax(n_fft, fs);
f_pos = f(1:n_fft/2);
f_neg = f((n_fft/2 - 1):end);
% since FFT shift is not used on input
f_neg = flip(f_neg);


% IQ_UP_pks1 = abs(IQ_UP1).*up_det1';
% IQ_DN_pks1 = abs(IQ_DN1).*dn_det1';
% 
% IQ_UP_pks2 = abs(IQ_UP2).*up_det2';
% IQ_DN_pks2 = abs(IQ_DN2).*dn_det2';

%%
% v_max = 60km/h , fd max = 2.7kHz approx 3kHz
v_max = 60/3.6; 
%fd_max = speed2dop(v_max, lambda)*2;
fd_max = 3e3;
fb = zeros(n_sweeps,4);
%fbd = zeros(n_sweeps,2);
% Each sample can return a detection - max number of targets is 200?
% beat2range - expects a set of beat freqs up and down
% NB: MATLAB makes square matrix by default
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);
count = 0;
close all
figure
for i = 1:n_sweeps
    % SINGLE TARG:
    % null feed through
%     IQ_UP_peaks(i,nul_lower:nul_upper) = 0;
%     IQ_DOWN_peaks(i,nul_lower:nul_upper) = 0;
    tiledlayout(4,1)
    nexttile
    plot(sftmagdb(IQ_UP1(i,:)))
    nexttile
    plot(sftmagdb(IQ_DN1(i,:)))
    nexttile
    plot(sftmagdb(IQ_UP2(i,:)))
    nexttile
    plot(sftmagdb(IQ_DN2(i,:)))
    pause(0.1)





%     [highest_SNR_up, pk_idx_up]= max(IQ_UP_peaks(i,round(n_fft/2 + 1):end));
%     [highest_SNR_down, pk_idx_down] = max(IQ_DOWN_peaks(i,1:round(n_fft/2 + 1)));
%     plot(IQ_UP_peaks(i,round(n_fft/2 + 1):end))
%     xline(pk_idx_up)
%     drawnow;
%     pause(1)
%     pk_idx_up
%     f(pk_idx_up)
%     fb(i, 1) = f(512+up_idx1(i));
%     fb(i, 2) = f(pk_idx_down);
%     count = 0;
%     while ((fb(i, 1)<0)||(fb(i, 2)>0))
%         IQ_UP_peaks(i,pk_idx_up) = 0;
%         IQ_DOWN_peaks(i,pk_idx_down) = 0;
    [snru1, pk_idx_up1]= max(IQ_UP_pks1(i,:));
    [snrd1, pk_idx_dn1] = max(IQ_DN_pks1(i,:));
    
    [snru2, pk_idx_up2]= max(IQ_UP_pks2(i,:));
    [snrd2, pk_idx_dn2] = max(IQ_DN_pks2(i,:));

    fb(i, 1) = f_pos(pk_idx_up1);
    fb(i, 2) = f_neg(pk_idx_dn1);
    fb(i, 3) = f_pos(pk_idx_up2);
    fb(i, 4) = f_neg(pk_idx_dn2);
%         count = count + 1;
%     end
%     fd = -fb(i,1)-fb(i,2);
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
%         fd_array(i) = fd/2;
%         speed_array(i) = dop2speed(fd/2,lambda)/2;
%         range_array(i) = beat2range([fb(i,1) fb(i,2)], sweep_slope, c);
%     end
end
% Determine range
% range_array = beat2range([ ])


