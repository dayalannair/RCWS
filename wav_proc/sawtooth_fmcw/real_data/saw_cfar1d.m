% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
t_sweep = 1e-3;                    
bw = 240e6;                    
sweep_slope = bw/t_sweep;
addpath('../../library/');

nfft = 200;
n_sweeps_per_frame = 128;
[iq, fft_frames, iq_frames, n_frames] = import_frames(n_sweeps_per_frame);

% Range axis
fs = 200e3;
f = f_ax(nfft, fs);
rng_bins = beat2range(f.', sweep_slope, c);

% Radial velocity axis
% Needs work!!!!!!!!

% angular_freq = -n_sweeps_per_frame/2:(n_sweeps_per_frame/2-1);
% vel_bins = lambda/(4*pi).*angular_freq;

% I back this one:
angular_freq = f_ax(n_sweeps_per_frame, 1/t_sweep);
vel_bins = lambda/(4*pi).*angular_freq;

%%
close all
figure('WindowState','maximized');
movegui('east')

%F = 1e-9; % for GOCA
F = 0.000005;
nt = 50;   
ng = 6; 

% METHOD 2: Separate CFAR
cfar = phased.CFARDetector('NumTrainingCells',ntc, ...
    'NumGuardCells',ngc, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'Rank', 18);

% cfar = phased.CFARDetector('NumTrainingCells',ntc, ...
%     'NumGuardCells',ngc, ...
%     'ThresholdFactor', 'Auto', ...
%     'ProbabilityFalseAlarm', F, ...
%     'Method', 'SOCA');

n_samples = nfft;
rng_dets = zeros(n_samples,n_sweeps_per_frame,n_frames);

for frame = 1:n_frames
    rng_dets(:,:,frame) = cfar(sftmag((fft_frames(:,:,frame))),1:n_samples);
    tiledlayout(1,2)
    nexttile
    imagesc(vel_bins, rng_bins, rng_dets(:,:,frame))
    title("2D CFAR detections")
    ylabel("Range (m)")
    xlabel("Radial Velocity (m/s)")
    grid
    nexttile
    imagesc(vel_bins,rng_bins, sftmagdb(fft_frames(:,:,frame)))
    title("2D FFT")
    ylabel("Range (m)")
    xlabel("Radial Velocity (m/s)")
    grid
%     nexttile
%     imagesc(vel_bins, rng_bins, th_imgs(:,:,frame))
%     title("2D CFAR threshold")
%     ylabel("Range (m)")
%     xlabel("Radial Velocity (m/s)")
%     grid
    drawnow;
    pause(0.3)
end