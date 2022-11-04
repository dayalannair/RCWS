% last section of the 20 km/h test 
subset = 1000:2000;
% first portion 60 kmh
subset = 1:1000;

addpath('../../../matlab_lib/');
addpath(['../../../../../OneDrive - University of ' ...
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

% Decimate faster device data
% rad2_iq_u = rad2_iq_u(1:3:end, :);
% rad2_iq_d = rad2_iq_d(1:3:end, :);
% Taylor Window
nbar = 3;
sll = -100;
twin = taylorwin(n_samples, nbar, sll);
rad1_iq_u = rad1_iq_u.*twin.';
rad1_iq_d = rad1_iq_d.*twin.';
rad2_iq_u = rad2_iq_u.*twin.';
rad2_iq_d = rad2_iq_d.*twin.';

% FFT
n_fft = 512;
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

RAD1_IQ_UP = fft(rad1_iq_u,n_fft,2);
RAD1_IQ_DN = fft(rad1_iq_d,n_fft,2);

RAD2_IQ_UP = fft(rad2_iq_u,n_fft,2);
RAD2_IQ_DN = fft(rad2_iq_d,n_fft,2);

% Halve FFTs
RAD2_IQ_UP = RAD2_IQ_UP(:, 1:n_fft/2);
RAD2_IQ_DN = RAD2_IQ_DN(:, n_fft/2+1:end);

RAD1_IQ_UP = RAD1_IQ_UP(:, 1:n_fft/2);
RAD1_IQ_DN = RAD1_IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
% METHOD 1: slice
% RAD2_IQ_UP(:, 1:num_nul) = 0;
% RAD2_IQ_DN(:, end-num_nul+1:end) = 0;
% 
% % METHOD 2: Remove average
% IQ_UP2 = RAD2_IQ_UP - mean(RAD2_IQ_UP,2);
% IQ_DN2 = RAD2_IQ_DN - mean(RAD2_IQ_DN,2);

Ns = 200;
nfft = 512;
fs = 200e3;
f = f_ax(nfft, fs);
f_pos = f((n_fft/2 + 1):end);
sweep_slope = 240e6/1e-3;
rng_ax = beat2range((f_pos)', sweep_slope, c);
% flip
RAD2_IQ_DN = flip(RAD2_IQ_DN,2);
RAD1_IQ_DN = flip(RAD1_IQ_DN,2);
%%
RAD2_IQ_UP = absmagdb(RAD2_IQ_UP);
RAD2_IQ_DN = absmagdb(RAD2_IQ_DN);

RAD1_IQ_UP = absmagdb(RAD1_IQ_UP);
RAD1_IQ_DN = absmagdb(RAD1_IQ_DN);

ax_dims = [0 max(rng_ax) 80 190];
ax_ticks = 1:2:60;

close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'west')

subplot(2,3,1);
p1 = plot(rng_ax, RAD1_IQ_UP(1,:));
title("RAD1 UP chirp positive half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,2);
p2 = plot(rng_ax, RAD1_IQ_DN(1,:));
title("RAD1 DOWN chirp flipped negative half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,3);
vidFrame = readFrame(vid1);
v1 = imshow(vidFrame);

subplot(2,3,4);
p3 = plot(rng_ax, RAD2_IQ_UP(1,:));
title("RAD2 UP chirp positive half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,5);
p4 = plot(rng_ax, RAD2_IQ_DN(1,:));
title("RAD2 DOWN chirp flipped negative half")
axis(ax_dims)
xticks(ax_ticks)
grid on
subplot(2,3,6);
vidFrame = readFrame(vid2);
v2 = imshow(vidFrame);

tic
for sweep = 1:n_sweeps
    set(p1, 'YData',RAD1_IQ_UP(sweep,:))
    set(p2, 'YData',RAD1_IQ_DN(sweep,:))
    set(p3, 'YData',RAD2_IQ_UP(sweep,:))
    set(p4, 'YData',RAD2_IQ_DN(sweep,:))
    
    % two frames per radar frame
%     vidFrame = readFrame(vid1);
%     vidFrame = readFrame(vid1);
%     set(v1,'CData' ,vidFrame);
% 
%     vidFrame = readFrame(vid2);
%     vidFrame = readFrame(vid2);
%     set(v2, 'CData', vidFrame);
    pause(0.01);
end
toc