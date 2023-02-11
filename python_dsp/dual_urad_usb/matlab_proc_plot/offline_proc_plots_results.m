% last section of the 20 km/h test 
subset = 1000:2000;
% first portion 60 kmh
subset = 1:1000;
subset = 1:2700;
addpath('../../matlab_lib/');

% iq_dual_load_data;

[fc, c, lambda, tm, bw, k, rad1_iq_u, rad1_iq_d, rad2_iq_u, ...
    rad2_iq_d, t_stamps] = import_dual_data_full(f_urad1, f_urad2, subset);
%%
fvid_lhs = strcat('lhs_vid',time,'.avi');
fvid_rhs = strcat('rhs_vid',time,'.avi');
% flip names to flip video order
vid_lhs = VideoReader(fvid_lhs);
vid_rhs = VideoReader(fvid_rhs);

%% FOR ROTATING RHS VID
% vd = read(vid_rhs);
% v2flip = rot90(vd, 2);
% V_flip = VideoWriter('flipped.avi','Uncompressed AVI'); 
% open(V_flip)
% writeVideo(V_flip,v2flip)
% close(V_flip)
%%
% Get dimensions of data from slower device
n_samples = size(rad1_iq_u,2);
% n_sweeps = size(rad1_iq_u,1);

% ************************ Tunable parameters *****************************
% These determine the system detection performance
n_fft = 512;
train = 16;%n_fft/8;%64;
guard = 14;%n_fft/64;%8;
rank = round(3*train/4);
nbar = 3;
sll = -100;
F = 1*10e-2;
v_max = 60/3.6; 
fd_max = speed2dop(v_max, lambda)*2;
% Minimum sample number for 1024 point FFT corresponding to min range = 10m
% n_min = 83;
% for 512 point FFT:
n_min = 42;
% Divide into range bins of width 64
% bin_width = (n_fft/2)/nbins;
% nbins = 8;
% bin_width = 32; % account for scan width = 21
% scan_width = 21; % see calcs: Delta f * 21 ~ 8 kHz

nbins = 16;
bin_width = 16; % account for scan width = 21
scan_width = 8;

calib = 1.2463;
lhs_road_width = 4;
rhs_road_width = 2;

% Decimate faster device data
% rad2_iq_u = rad2_iq_u(1:3:end, :);
% rad2_iq_d = rad2_iq_d(1:3:end, :);
% Taylor Window
win = taylorwin(n_samples, nbar, sll);
win2 = chebwin(n_samples, 100);
% win = hann(n_samples);
rad1_iq_u = rad1_iq_u.*win2.';
rad1_iq_d = rad1_iq_d.*win2.';
rad2_iq_u = rad2_iq_u.*win.';
rad2_iq_d = rad2_iq_d.*win.';

% FFT
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

LHS_IQ_UP = fft(rad1_iq_u,n_fft,2);
LHS_IQ_DN = fft(rad1_iq_d,n_fft,2);

RHS_IQ_UP = fft(rad2_iq_u,n_fft,2);
RHS_IQ_DN = fft(rad2_iq_d,n_fft,2);

% Halve FFTs

LHS_IQ_UP = LHS_IQ_UP(:, 1:n_fft/2);
LHS_IQ_DN = LHS_IQ_DN(:, n_fft/2+1:end);

RHS_IQ_UP = RHS_IQ_UP(:, 1:n_fft/2);
RHS_IQ_DN = RHS_IQ_DN(:, n_fft/2+1:end);

% Ensemble mean canceller
% -------------------------------------------------------------------------
% l_up_bar = mean(LHS_IQ_UP);
% l_dn_bar = mean(LHS_IQ_DN);
% 
% r_up_bar = mean(RHS_IQ_UP);
% r_dn_bar = mean(RHS_IQ_DN);
% 
% LHS_IQ_UP = LHS_IQ_UP - l_up_bar;
% LHS_IQ_DN = LHS_IQ_DN - l_dn_bar;
% RHS_IQ_UP = RHS_IQ_UP - r_up_bar;
% RHS_IQ_DN = RHS_IQ_DN - r_dn_bar;
% -------------------------------------------------------------------------
% Null feedthrough
% METHOD 1: slice
% RHS_IQ_UP(:, 1:num_nul) = 0;
% RHS_IQ_DN(:, end-num_nul+1:end) = 0;
% 
% % METHOD 2: Remove average
% IQ_UP2 = RHS_IQ_UP - mean(RHS_IQ_UP,2);
% IQ_DN2 = RHS_IQ_DN - mean(RHS_IQ_DN,2);

Ns = 200;
fs = 200e3;
f = f_ax(n_fft, fs);
f_pos = f((n_fft/2 + 1):end);
sweep_slope = 240e6/1e-3;
rng_ax = beat2range((f_pos)', sweep_slope, c);
% flip

LHS_IQ_DN = flip(LHS_IQ_DN,2);
RHS_IQ_DN = flip(RHS_IQ_DN,2);

% -------------------------------------------------------------------------
% CFAR
% -------------------------------------------------------------------------
CFAR1 = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA', ...
    'ThresholdOutputPort', true, ...
    'Rank',rank);

CFAR2 = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA', ...
    'ThresholdOutputPort', true, ...
    'Rank',rank);


% Filter peaks/ peak detection
[up_os1, upTh1] = CFAR1(abs(LHS_IQ_UP)', 1:n_fft/2);
[dn_os1, dnTh1] = CFAR1(abs(LHS_IQ_DN)', 1:n_fft/2);

[up_os2, upTh2] = CFAR2(abs(RHS_IQ_UP)', 1:n_fft/2);
[dn_os2, dnTh2] = CFAR2(abs(RHS_IQ_DN)', 1:n_fft/2);

% Find peak magnitude
upDets1 = abs(LHS_IQ_UP).*up_os1';
dnDets1 = abs(LHS_IQ_DN).*dn_os1';

upDets2 = abs(RHS_IQ_UP).*up_os2';
dnDets2 = abs(RHS_IQ_DN).*dn_os2';

% Define frequency axis
fs = 200e3;
f = f_ax(n_fft, fs);
f_neg = f(1:n_fft/2);
f_pos = f((n_fft/2 + 1):end);

v_max = 60/3.6; 
fd_max = speed2dop(v_max, lambda)*2;

% -------------------------------------------------------------------------
% Initialise arrays
% -------------------------------------------------------------------------

% Make slightly larger to allow for holding previous
% >16 will always be 0 and not influence results
% previous_det = zeros(nbins+2, 1);

f_bin_edges_idx = size(f_pos(),2)/nbins;
road_width = 2;
correction_factor = 1;
prev_det = 0;
speed_correction = 1.2;
% -------------------------------------------------------------------------
% Initialise plots
% -------------------------------------------------------------------------
fb_idx1 = zeros(nbins,1);
fb_idx2 = zeros(nbins,1);
fb_idx_end1 = zeros(nbins,1);
fb_idx_end2 = zeros(nbins,1);
% max speed = 90 km/h. f = 2v/lambda = 4 kHz. each bin is 1 kHz apart
ax_dims = [0 max(rng_ax) 80 190];
ax_ticks = 1:2:60;

nswp1 = size(LHS_IQ_UP,1);
nswp2 = size(RHS_IQ_UP,1);

rgMtx1 = zeros(nswp1, nbins);
spMtx1 = zeros(nswp1, nbins);
spMtxCorr1 = zeros(nswp1, nbins);

rgMtx2 = zeros(nswp2, nbins);
spMtx2 = zeros(nswp2, nbins);
spMtxCorr2 = zeros(nswp2, nbins);

loop_count = min(nswp1, nswp2);
beat_count_out1 = zeros(1,256);
beat_count_out2 = zeros(1,256);
beat_count_in1 = zeros(1,256);
beat_count_in2 = zeros(1,256);

snr_ceil = 0.2e+06;

for i = 1:loop_count
        

    [rgMtx1(i,:), spMtx1(i,:), spMtxCorr1(i,:), pkuClean1, ...
    pkdClean1, fbu1, fbd1, fdMtx1, fb_idx1, fb_idx_end1, ...
    beat_count_out1] = proc_sweep_multi_scan_left(bin_width, ...
    lambda, k, c, dnDets1(i,:), upDets1(i,:), nbins, n_fft, ...
    f_pos, scan_width, calib, lhs_road_width, beat_count_in1, snr_ceil);

    [rgMtx2(i,:), spMtx2(i,:), spMtxCorr2(i,:), pkuClean2, ...
    pkdClean2, fbu2, fbd2, fdMtx2, fb_idx2, fb_idx_end2, ...
    beat_count_out2] = proc_sweep_multi_scan(bin_width, ...
    lambda, k, c, dnDets2(i,:), upDets2(i,:), nbins, n_fft, ...
    f_pos, scan_width, calib, rhs_road_width, beat_count_in2);

end
%
close all
figure
tiledlayout(2, 2)
nexttile
imagesc(rgMtx1)
nexttile
imagesc(rgMtx2)
nexttile
imagesc(spMtx1)
nexttile
imagesc(spMtx2)

