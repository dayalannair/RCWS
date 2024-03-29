% last section of the 20 km/h test 
subset = 1000:2000;
% first portion 60 kmh
subset = 1:1000;
addpath('../../matlab_lib/');
iq_dual_load_data;
[fc, c, lambda, tm, bw, k, rad1_iq_u, rad1_iq_d, rad2_iq_u, ...
    rad2_iq_d, t_stamps] = import_dual_data_full(f_urad1, f_urad2);
%%
fvid_lhs = strcat('lhs_vid',time,'.avi');
fvid_rhs = strcat('rhs_vid',time,'.avi');
% flip names to flip video order
vid_lhs = VideoReader(fvid_lhs);
vid_rhs = VideoReader(fvid_rhs);
%%
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

LHS_IQ_UP = fft(rad1_iq_u,n_fft,2);
LHS_IQ_DN = fft(rad1_iq_d,n_fft,2);

RHS_IQ_UP = fft(rad2_iq_u,n_fft,2);
RHS_IQ_DN = fft(rad2_iq_d,n_fft,2);

FULL_RHS_IQ_UP = RHS_IQ_UP;
FULL_RHS_IQ_DN = RHS_IQ_DN;
FULL_LHS_IQ_UP = LHS_IQ_UP;
FULL_LHS_IQ_DN = LHS_IQ_DN;

% Halve FFTs
RHS_IQ_UP = RHS_IQ_UP(:, 1:n_fft/2);
RHS_IQ_DN = RHS_IQ_DN(:, n_fft/2+1:end);

LHS_IQ_UP = LHS_IQ_UP(:, 1:n_fft/2);
LHS_IQ_DN = LHS_IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
% METHOD 1: slice
% RHS_IQ_UP(:, 1:num_nul) = 0;
% RHS_IQ_DN(:, end-num_nul+1:end) = 0;
% 
% % METHOD 2: Remove average
% IQ_UP2 = RHS_IQ_UP - mean(RHS_IQ_UP,2);
% IQ_DN2 = RHS_IQ_DN - mean(RHS_IQ_DN,2);

Ns = 200;
nfft = 512;
fs = 200e3;
f = f_ax(nfft, fs);
f_pos = f((n_fft/2 + 1):end);
sweep_slope = 240e6/1e-3;
rng_ax = beat2range((f_pos)', sweep_slope, c);
% flip
RHS_IQ_DN = flip(RHS_IQ_DN,2);
LHS_IQ_DN = flip(LHS_IQ_DN,2);
%%
RHS_IQ_UP = absmagdb(RHS_IQ_UP);
RHS_IQ_DN = absmagdb(RHS_IQ_DN);

LHS_IQ_UP = absmagdb(LHS_IQ_UP);
LHS_IQ_DN = absmagdb(LHS_IQ_DN);

%% PLOT FULL SPECTRA
rng_ax = beat2range((f)', sweep_slope, c);
ax_dims = [-max(rng_ax) max(rng_ax) 80 190];
ax_ticks = -60:5:60;

close all
vid_lhs.CurrentTime = 0;
vid_rhs.CurrentTime = 0;
fig1 = figure('WindowState','maximized');
movegui(fig1,'west')

subplot(2,3,1);
vidFrame = readFrame(vid_lhs);
v1 = imshow(vidFrame);

subplot(2,3,2);
p1 = plot(rng_ax, sftmagdb(FULL_LHS_IQ_UP(1,:)));
title("LHS UP")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,3);
p2 = plot(rng_ax, sftmagdb(FULL_LHS_IQ_DN(1,:)));
title("LHS DOWN")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,4);
p3 = plot(rng_ax, sftmagdb(FULL_RHS_IQ_UP(1,:)));
title("RHS UP")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,5);
p4 = plot(rng_ax, sftmagdb(FULL_RHS_IQ_DN(1,:)));
title("RHS DOWN")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,6);
vidFrame = readFrame(vid_rhs);
v2 = imshow(rot90(vidFrame,2));
frame_count = 0;
vid_frame_number = 1;
tic
for sweep = 1:n_sweeps
    set(p1, 'YData',sftmagdb(FULL_LHS_IQ_UP(sweep,:)))
    set(p2, 'YData',sftmagdb(FULL_LHS_IQ_DN(sweep,:)))
    set(p3, 'YData',sftmagdb(FULL_RHS_IQ_UP(sweep,:)))
    set(p4, 'YData',sftmagdb(FULL_RHS_IQ_DN(sweep,:)))
%     pause(0.01)
    % three frames per radar frame
    
    if frame_count == 2
        vidFrame = readFrame(vid_lhs);
        set(v1,'CData' ,vidFrame);
        vidFrame = readFrame(vid_rhs);
        set(v2, 'CData', vidFrame);
%         set(v2, 'CData', rot90(vidFrame,2));
        frame_count = 0;
        vid_frame_number = vid_frame_number + 1;
    else
        frame_count = frame_count + 1;
    end


%     disp(['Radar sweep : ', num2str(sweep),' Video frame : ', ...
%         num2str(vid_frame_number)])
    pause(0.01);
    
end
toc

return;
%% PLOT HALVED AND FLIPPED DOWN CHIRP
rng_ax = beat2range((f_pos)', sweep_slope, c);
ax_dims = [0 max(rng_ax) 80 190];
ax_ticks = 1:2:60;

close all
vid_lhs.CurrentTime = 0;
vid_rhs.CurrentTime = 0;
fig1 = figure('WindowState','maximized');
movegui(fig1,'west')

subplot(2,3,1);
vidFrame = readFrame(vid_lhs);
v1 = imshow(vidFrame);


subplot(2,3,2);
p1 = plot(rng_ax, LHS_IQ_UP(1,:));
title("LHS UP chirp positive half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,3);
p2 = plot(rng_ax, LHS_IQ_DN(1,:));
title("LHS DOWN chirp flipped negative half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,4);
p3 = plot(rng_ax, RHS_IQ_UP(1,:));
title("RHS UP chirp positive half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,5);
p4 = plot(rng_ax, RHS_IQ_DN(1,:));
title("RHS DOWN chirp flipped negative half")
axis(ax_dims)
xticks(ax_ticks)
grid on
subplot(2,3,6);
vidFrame = readFrame(vid_rhs);
v2 = imshow(rot90(vidFrame,2));
frame_count = 0;
vid_frame_number = 1;
tic
for sweep = 1:n_sweeps
    set(p1, 'YData',LHS_IQ_UP(sweep,:))
    set(p2, 'YData',LHS_IQ_DN(sweep,:))
    set(p3, 'YData',RHS_IQ_UP(sweep,:))
    set(p4, 'YData',RHS_IQ_DN(sweep,:))
%     pause(0.01)
    % three frames per radar frame
    
    if frame_count == 2
        vidFrame = readFrame(vid_lhs);
        set(v1,'CData' ,vidFrame);
        vidFrame = readFrame(vid_rhs);
        set(v2, 'CData', rot90(vidFrame,2));
        frame_count = 0;
        vid_frame_number = vid_frame_number + 1;
    else
        frame_count = frame_count + 1;
    end


    disp(['Radar sweep : ', num2str(sweep),' Video frame : ', ...
        num2str(vid_frame_number)])
    pause(0.01);
    
end
toc