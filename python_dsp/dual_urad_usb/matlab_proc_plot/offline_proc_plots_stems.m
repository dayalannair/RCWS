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
%% RT PLOTS

vid_lhs = VideoReader(fvid_lhs);
vid_rhs = VideoReader(fvid_rhs);
close all
vid_lhs.CurrentTime = 0;
vid_rhs.CurrentTime = 0;
fig1 = figure('WindowState','maximized');
movegui(fig1,'west')
% -------------------------------------------------------------------------
% Process sweeps
% -------------------------------------------------------------------------
tic
vidObj.CurrentTime = 0;
hold_frame = 0;
frame_count = 1;

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
% colors = linspace(1,5,5);
% x = linspace(0,3*pi,200);
% colors = linspace(1,10,length(x));
xyax = [0,16,0,60];
subplot(2,3,1);
vidFrame = readFrame(vid_lhs);
v1 = imshow(vidFrame);

lhs_exp_speed = 40;
rhs_exp_speed = 60;
subplot(2,3,2);
p1 = stem(rgMtx1(1,:));
hold on
axis(xyax)
title("LHS Range Results")


subplot(2,3,3);
p2 = stem(spMtxCorr1(1,:));
hold on
yline(lhs_exp_speed)
% hold off
axis(xyax)
title("LHS Speed Results. Expected speed = ", lhs_exp_speed)

subplot(2,3,4);
p3 = stem(rgMtx2(1,:));
hold on
axis(xyax)
title("RHS Range Results")

subplot(2,3,5);
p4 = stem(spMtxCorr2(1,:));
hold on
yline(rhs_exp_speed)
% hold off
axis(xyax)
title("RHS Speed Results. Expected speed = ", rhs_exp_speed)

subplot(2,3,6);
vidFrame = readFrame(vid_rhs);
v2 = imshow(vidFrame);

% subplot(2,3,1);
% vidFrame = readFrame(vid_lhs);
% v1 = imshow(vidFrame);
% 
% subplot(2,3,2);
% p1 = plot(reshape(rgMtx1, 1, []));
% axis([0, 3669*16, 0, 60])
% hold on
% cursor = scatter(0, 130 ,2000, 'Marker', '|', 'LineWidth',1.5);
% hold off
% title("LHS Range Results")
% 
% 
% subplot(2,3,3);
% p2 = plot(reshape(spMtxCorr1, 1, []));
% title("LHS Speed Results")
% 
% subplot(2,3,4);
% p3 = plot(reshape(rgMtx2, 1, []));
% title("RHS Range Results")
% 
% subplot(2,3,5);
% p4 = plot(reshape(spMtxCorr2, 1, []));
% title("RHS Speed Results")
% 
% subplot(2,3,6);
% vidFrame = readFrame(vid_rhs);
% v2 = imshow(vidFrame);

for i = 1:loop_count
        

    [rgMtx1(i,:), spMtx1(i,:), spMtxCorr1(i,:), pkuClean1, ...
    pkdClean1, fbu1, fbd1, fdMtx1, fb_idx1, fb_idx_end1, ...
    beat_count_out1] = proc_sweep_multi_scan(bin_width, ...
    lambda, k, c, dnDets1(i,:), upDets1(i,:), nbins, n_fft, ...
    f_pos, scan_width, calib, lhs_road_width, beat_count_in1);
    
    beat_count_in1 = beat_count_out1;

    [rgMtx2(i,:), spMtx2(i,:), spMtxCorr2(i,:), pkuClean2, ...
    pkdClean2, fbu2, fbd2, fdMtx2, fb_idx2, fb_idx_end2, ...
    beat_count_out2] = proc_sweep_multi_scan(bin_width, ...
    lambda, k, c, dnDets2(i,:), upDets2(i,:), nbins, n_fft, ...
    f_pos, scan_width, calib, rhs_road_width, beat_count_in2);

    % Reset clutter filter every 40 sweeps
    if mod(i, 40) == 0 
        beat_count_out1 = zeros(1,256);
        beat_count_out2 = zeros(1,256);
        beat_count_in1 = zeros(1,256);
        beat_count_in2 = zeros(1,256);
    else
        beat_count_in2 = beat_count_out2;
    end
%         % When run on 4 threads, there are 3 times fewer 
%         % video frames
    if hold_frame == 2
        vidFrame = readFrame(vid_lhs);
        set(v1,'CData' ,vidFrame);

        vidFrame = readFrame(vid_rhs);
        set(v2, 'CData', rot90(vidFrame, 2));
        hold_frame = 0;
        frame_count = frame_count + 1;
    else
        hold_frame = hold_frame + 1;
    end
    % PLOT DATA
    % -----------------------------------------------------------------
    set(p1, 'YData', rgMtx1(i,:))
    set(p2, 'YData', spMtxCorr1(i,:)*3.6)
    set(p3, 'YData', rgMtx2(i,:))
    set(p4, 'YData', spMtxCorr2(i,:)*3.6)

%     set(cursor,'XData',i)
    % -----------------------------------------------------------------

%     disp(['Radar sweep : ', num2str(i),' Video frame : ', ...
%         num2str(frame_count)])
    pause(0.001);
end
toc
%% Map of sweep v range v speed
% close all
% figure
% tiledlayout(1,2)
% nexttile
% imagesc(spMtxCorr1)
% nexttile
% imagesc(spMtxCorr2)

%% FAST PLOTTING - does not handle xlines
% for i = 1:loop_count
%         
%         [rgMtx1(i,:), spMtx1(i,:), spMtxCorr1(i,:), pkuClean1, ...
%         pkdClean1, fbu1, fbd1, fdMtx1, fb_idx1] = proc_sweep(bin_width, ...
%         lambda, k, c, dnDets1(i,:), upDets1(i,:), nbins, n_fft, ...
%         f_pos, scan_width, calib, road_width);
%         
%         fb_idx_end1 = fb_idx1 - 15;
% 
%         [rgMtx2(i,:), spMtx2(i,:), spMtxCorr2(i,:), pkuClean2, ...
%         pkdClean2, fbu2, fbd2, fdMtx2, fb_idx2] = proc_sweep(bin_width, ...
%         lambda, k, c, dnDets2(i,:), upDets2(i,:), nbins, n_fft, ...
%         f_pos, scan_width, calib, road_width);
%     
%         fb_idx_end2 = fb_idx2 - 15;
%         win1.Value
% %         set(win1,'Data',[fb_idx1, fb_idx_end1])
% %         set(win1, 'YData', [fb_idx1, fb_idx_end1])
% %         set(win2, 'YData', [fb_idx1, fb_idx_end1])
% %         
% %         set(win3, 'YData', [fb_idx2, fb_idx_end2])
% %         set(win4, 'YData', [fb_idx2, fb_idx_end2])
% %         win3 = xline([fb_idx2, fb_idx_end2]);
%         set(p1, 'YData', absmagdb(LHS_IQ_UP(i,:)))
%         set(p2, 'YData', absmagdb(LHS_IQ_DN(i,:)))
%         set(p3, 'YData', absmagdb(RHS_IQ_UP(i,:)))
%         set(p4, 'YData', absmagdb(RHS_IQ_DN(i,:)))
% 
%         set(p1th, 'YData', absmagdb(upTh1(:,i)))
%         set(p2th, 'YData', absmagdb(dnTh1(:,i)))
%         set(p3th, 'YData', absmagdb(upTh2(:,i)))
%         set(p4th, 'YData', absmagdb(dnTh2(:,i)))
% %         
% %         % When run on 4 threads, there are 3 times fewer 
% %         % video frames
%         if hold_frame == 2
%             vidFrame = readFrame(vid_lhs);
%             set(v1,'CData' ,vidFrame);
% 
%             vidFrame = readFrame(vid_rhs);
%             set(v2, 'CData', vidFrame);
%             hold_frame = 0;
%             frame_count = frame_count + 1;
%         else
%             hold_frame = hold_frame + 1;
%         end
% %     disp(['Radar sweep : ', num2str(sweep),' Video frame : ', ...
% %         num2str(frame_count)])
% %     pause(0.01);
% end
% toc
% RHS_IQ_UP = absmagdb(RHS_IQ_UP);
% RHS_IQ_DN = absmagdb(RHS_IQ_DN);
% 
% LHS_IQ_UP = absmagdb(LHS_IQ_UP);
% LHS_IQ_DN = absmagdb(LHS_IQ_DN);

%% 
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