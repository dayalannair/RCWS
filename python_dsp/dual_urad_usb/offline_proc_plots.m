% last section of the 20 km/h test 
subset = 1000:2000;
% first portion 60 kmh
subset = 1:1000;

addpath('../../matlab_lib/');
addpath(['../../../../OneDrive - University of ' ...
    'Cape Town/RCWS_DATA/road_data_03_11_2022/']);
f_urad1 = 'uRAD1_iq_12_18_12.txt';
f_urad2 = 'uRAD2_iq_12_18_12.txt';
[fc, c, lambda, tm, bw, k, rad1_iq_u, rad1_iq_d, rad2_iq_u, ...
    rad2_iq_d, t_stamps] = import_dual_data_full(f_urad1, f_urad2);

vid_urad1 = 'lhs_vid_12_18_12.avi';
vid_urad2 = 'rhs_vid_12_18_12.avi';
% flip names to flip video order
vid2 = VideoReader(vid_urad1);
vid1 = VideoReader(vid_urad2);

% FOR ROTATING RHS VID
% vd = read(vid2);
% v2flip = rot90(vd, 2);
% V_flip = VideoWriter('rhs_vid_12_18_12_flipped.avi','Uncompressed AVI'); 
% open(V_flip)
% writeVideo(V_flip,v2flip)
% close(V_flip)
% return;
% Get dimensions of data from slower device
n_samples = size(rad1_iq_u,2);
n_sweeps = size(rad1_iq_u,1);

% ************************ Tunable parameters *****************************
% These determine the system detection performance
n_fft = 512;
train = n_fft/8;%64;
guard = n_fft/64;%8;
guard = 4;
nbar = 3;
sll = -100;
F = 10e-3;

% Decimate faster device data
% rad2_iq_u = rad2_iq_u(1:3:end, :);
% rad2_iq_d = rad2_iq_d(1:3:end, :);
% Taylor Window
twin = taylorwin(n_samples, nbar, sll);
rad1_iq_u = rad1_iq_u.*twin.';
rad1_iq_d = rad1_iq_d.*twin.';
rad2_iq_u = rad2_iq_u.*twin.';
rad2_iq_d = rad2_iq_d.*twin.';

% FFT
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

RAD1_IQ_UP = fft(rad1_iq_u,n_fft,2);
RAD1_IQ_DN = fft(rad1_iq_d,n_fft,2);

RAD2_IQ_UP = fft(rad2_iq_u,n_fft,2);
RAD2_IQ_DN = fft(rad2_iq_d,n_fft,2);

% Halve FFTs

RAD1_IQ_UP = RAD1_IQ_UP(:, 1:n_fft/2);
RAD1_IQ_DN = RAD1_IQ_DN(:, n_fft/2+1:end);

RAD2_IQ_UP = RAD2_IQ_UP(:, 1:n_fft/2);
RAD2_IQ_DN = RAD2_IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
% METHOD 1: slice
% RAD2_IQ_UP(:, 1:num_nul) = 0;
% RAD2_IQ_DN(:, end-num_nul+1:end) = 0;
% 
% % METHOD 2: Remove average
% IQ_UP2 = RAD2_IQ_UP - mean(RAD2_IQ_UP,2);
% IQ_DN2 = RAD2_IQ_DN - mean(RAD2_IQ_DN,2);

Ns = 200;
fs = 200e3;
f = f_ax(n_fft, fs);
f_pos = f((n_fft/2 + 1):end);
sweep_slope = 240e6/1e-3;
rng_ax = beat2range((f_pos)', sweep_slope, c);
% flip

RAD1_IQ_DN = flip(RAD1_IQ_DN,2);
RAD2_IQ_DN = flip(RAD2_IQ_DN,2);

% -------------------------------------------------------------------------
% CFAR
% -------------------------------------------------------------------------
OS1 = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',train);

OS2 = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',train);


% Filter peaks/ peak detection
[up_os1, upTh1] = OS1(abs(RAD1_IQ_UP)', 1:n_fft/2);
[dn_os1, dnTh1] = OS1(abs(RAD1_IQ_DN)', 1:n_fft/2);

[up_os2, upTh2] = OS2(abs(RAD2_IQ_UP)', 1:n_fft/2);
[dn_os2, dnTh2] = OS2(abs(RAD2_IQ_DN)', 1:n_fft/2);

% Find peak magnitude
upDets1 = abs(RAD1_IQ_UP).*up_os1';
dnDets1 = abs(RAD1_IQ_DN).*dn_os1';

upDets2 = abs(RAD2_IQ_UP).*up_os2';
dnDets2 = abs(RAD2_IQ_DN).*dn_os2';

% Define frequency axis
fs = 200e3;
f = f_ax(n_fft, fs);
f_neg = f(1:n_fft/2);
f_pos = f((n_fft/2 + 1):end);

v_max = 60/3.6; 
fd_max = speed2dop(v_max, lambda)*2;
% Minimum sample number for 1024 point FFT corresponding to min range = 10m
% n_min = 83;
% for 512 point FFT:
n_min = 42;
% Divide into range bins of width 64
nbins = 16;
bin_width = (n_fft/2)/nbins;

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
ax_dims = [0 max(rng_ax) 80 190];
ax_ticks = 1:2:60;

close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'west')

subplot(2,3,1);
p1 = plot(rng_ax, absmagdb(RAD1_IQ_UP(1,:)));
hold on
p1th = plot(rng_ax, absmagdb(upTh1(:,1)));
hold off
title("RAD1 UP chirp positive half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,2);
p2 = plot(rng_ax, absmagdb(RAD1_IQ_DN(1,:)));
hold on
p2th = plot(rng_ax, absmagdb(dnTh1(:,1)));
hold off
title("RAD1 DOWN chirp flipped negative half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,3);
vidFrame = readFrame(vid1);
v1 = imshow(vidFrame);

subplot(2,3,4);
p3 = plot(rng_ax, absmagdb(RAD2_IQ_UP(1,:)));
hold on
p3th = plot(rng_ax, absmagdb(upTh2(:,1)));
hold off
title("RAD2 UP chirp positive half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,5);
p4 = plot(rng_ax, absmagdb(RAD2_IQ_DN(1,:)));
hold on
p4th = plot(rng_ax, absmagdb(dnTh2(:,1)));
hold off
title("RAD2 DOWN chirp flipped negative half")
axis(ax_dims)
xticks(ax_ticks)
grid on
subplot(2,3,6);
vidFrame = readFrame(vid2);
v2 = imshow(vidFrame);
% -------------------------------------------------------------------------
% Process sweeps
% -------------------------------------------------------------------------
tic
for i = 1:n_sweeps
        set(p1, 'YData', absmagdb(RAD1_IQ_UP(i,:)))
        set(p2, 'YData', absmagdb(RAD1_IQ_DN(i,:)))
        set(p3, 'YData', absmagdb(RAD2_IQ_UP(i,:)))
        set(p4, 'YData', absmagdb(RAD2_IQ_DN(i,:)))
%         [rgMtx1, spMtx1, spMtxCorr1, pkuClean1, ...
%         pkdClean1, fbu1, fbd1, fdMtx] = proc_sweep(bin_width, fd_max, ...
%         lambda, k, c, dnDets(i,:), upDets(i,:));
        set(p1th, 'YData', absmagdb(upTh1(:,i)))
        set(p2th, 'YData', absmagdb(dnTh1(:,i)))
        set(p3th, 'YData', absmagdb(upTh2(:,i)))
        set(p4th, 'YData', absmagdb(dnTh2(:,i)))
        
            % two frames per radar frame
        vidFrame = readFrame(vid1);
        vidFrame = readFrame(vid1);
        set(v1,'CData' ,vidFrame);
    
        vidFrame = readFrame(vid2);
        vidFrame = readFrame(vid2);
        set(v2, 'CData', vidFrame);

        pause(0.01);
end
toc
% RAD2_IQ_UP = absmagdb(RAD2_IQ_UP);
% RAD2_IQ_DN = absmagdb(RAD2_IQ_DN);
% 
% RAD1_IQ_UP = absmagdb(RAD1_IQ_UP);
% RAD1_IQ_DN = absmagdb(RAD1_IQ_DN);







% tic
% for i = 1:n_sweeps
%    
%     
%     % two frames per radar frame
% %     vidFrame = readFrame(vid1);
% %     vidFrame = readFrame(vid1);
% %     set(v1,'CData' ,vidFrame);
% % 
% %     vidFrame = readFrame(vid2);
% %     vidFrame = readFrame(vid2);
% %     set(v2, 'CData', vidFrame);
%     pause(0.01);
% end
% toc