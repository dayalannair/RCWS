% Parameters
close all
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


figure('WindowState','maximized');
movegui('east')

F = 1e-9; % for GOCA
% NOTE STRANGE: ALL values below are the maximum they can be, 
% unknown reason
ntr = 17;   % row train
ntc = 10;   % column train. Somehow 10 is max
ngr = 4;  % row guard
ngc = 2; % column guard. 2 is max

% METHOD 2: Separate CFAR

rng_cfar = phased.CFARDetector('NumTrainingCells',ntc, ...
    'NumGuardCells',ngc, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA');

vel_cfar = phased.CFARDetector('NumTrainingCells',ntr, ...
    'NumGuardCells',ngr, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA');

n_samples = nfft;



[rng_dets,rng_th] = rng_cfar(sftmag((fft_frames)),1:n_samples);
[vel_dets,vel_th] = vel_cfar(sftmag((fft_frames)),1:n_sweeps_per_frame);


detimgs = zeros(n_samples,n_sweeps_per_frame, n_frames);
th_imgs = zeros(n_samples,n_sweeps_per_frame, n_frames);

for y = 1:length(dets)
    detimgs(dets(1,y),dets(2,y),dets(3,y)) = 1;
    th_imgs(dets(1,y),dets(2,y),dets(3,y)) = th(y);
end
for frame = 1:n_frames
    tiledlayout(1,3)
    nexttile
    imagesc(vel_bins, rng_bins, detimgs(:,:,frame))
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
    nexttile
    imagesc(vel_bins, rng_bins, th_imgs(:,:,frame))
    title("2D CFAR threshold")
    ylabel("Range (m)")
    xlabel("Radial Velocity (m/s)")
    grid
    drawnow;
    pause(0.2)
end
return;
%%


% Moving Plot
%close all
% for frame = 1:n_frames
%     for k = 1:ncutcells
%         % create image. extract each detection for frame
%         detimg(cutidx(1,k),cutidx(2,k)) = dets(k,frame);
%         th_img(cutidx(1,k),cutidx(2,k)) = th(k,frame);
%     end
%     tiledlayout(1,3)
%     nexttile
%     imagesc(vel_bins, rng_bins, detimg)
%     title("2D CFAR detections")
%     ylabel("Range (m)")
%     grid
%     nexttile
%     imagesc([],rng_bins, sftmagdb(fft_frames(:,:,frame)))
%     title("2D FFT")
%     ylabel("Range (m)")
%     grid
%     nexttile
%     imagesc([], rng_bins, th_img)
%     title("2D CFAR threshold")
%     ylabel("Range (m)")
%     grid
%     drawnow;
%     pause(0.1)
% end
% return;









