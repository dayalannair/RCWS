% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
t_sweep = 1e-3;                    
bw = 240e6;                    
sweep_slope = bw/t_sweep;
addpath('../../library/');
addpath('../../data/urad_usb/');

% Import data
subset = 1:512;
iq_tbl=readtable('IQ_sawtooth.txt', 'Delimiter' ,' ');
i_dat = table2array(iq_tbl(subset,1:200));
q_dat = table2array(iq_tbl(subset,201:400));
iq = i_dat + 1i*q_dat;

n_samples = size(i_dat,2);
n_sweeps = size(i_dat,1);
n_sweeps_per_frame = 50;
n_frames = round(n_sweeps/n_sweeps_per_frame);

% Gaussian window
% gwin = gausswin(n_samples);
% iq = iq.*gwin.';

% Range axis
fs = 200e3;
f = f_ax(200, fs);
rng_bins = beat2range(f.', sweep_slope, c);

n_fft = 512;%n_samples;

tframe = n_sweeps_per_frame*t_sweep;
%fdop = f_ax

% Reshape data set into frames and perform FFT
fft_frames = zeros(n_samples, n_sweeps_per_frame, n_frames);
iq_frames = zeros(n_samples, n_sweeps_per_frame, n_frames);
for i = 1:n_frames
    p1 = (i-1)*n_sweeps_per_frame + 1;
    p2 = i*n_sweeps_per_frame;
    fft_frames(:,:,i) = fft2(iq(p1:p2, :).');
    iq_frames(:,:,i) = iq(p1:p2, :).';
end

% CFAR
% ISSUE: cant make band to big for rows. doesnt make sense
% F reduced does not help tx feedthrough, though it does reduce
% spots and doppler false alarms
F = 1e-9;
cfar2d = phased.CFARDetector2D('TrainingBandSize',[17 10], ...
    'GuardBandSize',[4 2], ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'GOCA', ...
    'ThresholdOutputPort', true);

% Restrict the locations of CUT cells 
% so that their training regions lie completely within the input images.
% bounds = train + guard = 10 + 2 = 12 then add 1 pad
Ngc = cfar2d.GuardBandSize(2);
Ngr = cfar2d.GuardBandSize(1);
Ntc = cfar2d.TrainingBandSize(2);
Ntr = cfar2d.TrainingBandSize(1);
cutidx = [];
colstart = Ntc + Ngc + 1;
% finding CUTs per frame
colend = n_sweeps_per_frame - ( Ntc + Ngc);
rowstart = Ntr + Ngr + 1;
rowend = n_samples - ( Ntr + Ngr);
for m = colstart:colend
    for n = rowstart:rowend
        % add position of each CUT to index matrix
        cutidx = [cutidx,[n;m]];
    end
end
ncutcells = size(cutidx,2);

cutimage = zeros(200,40);
for k = 1:ncutcells
    cutimage(cutidx(1,k),cutidx(2,k)) = 1;
end
close all
figure
imagesc(cutimage)
%axis equal
% figure
% for i = 1:n_frames
%     p1 = (i-1)*n_sweeps_per_frame + 1;
%     p2 = i*n_sweeps_per_frame;
%     fft_frames(:,:,i) = fft2(iq(p1:p2, :).');
%     dets = cfar2d(abs(fft_frames(:,:,i)), cutidx);
%     imagesc([], rng_bins,fftshift(20*log10(abs(fft_frames(:,:,i)))))
%     %surf(fftshift(20*log10(abs(fft_frames(:,:,i)))))
% %     surf(fftshift(20*log10(abs(fft_frames(:,:,i)))))
% %     view(69.5124980863678, 46.4092184844678);
%     pause(1)
% end

%%
% di = [];
% % loop through frames
% for k = 1:n_frames
%     % extract a set of detections from frame k
%     d = dets(:,k);
% 
%     % if there is a detection in frame k
%     if (any(d))
%         % add frame index to di
%         di = [di,k];
%     end
% end
% store first frame index
%idx = di(1);
detimg = zeros(n_samples,n_sweeps_per_frame);
th_img = zeros(n_samples,n_sweeps_per_frame);
% loop through total number of cells under test
% ncuts per frame!
%frame = 1;

% Nulling tx
%fft_frames(94:106,:,:) = repmat(fft_frames(93,:,:), 13, 1);

% NOTE: NEED TO FFT SHIFT HERE!
% NOTE: Must not get dBs here. Linear is better for CFAR
[dets,th] = cfar2d(sftmag((fft_frames)),cutidx);
%% Moving Plot
%close all
figure('WindowState','maximized');
movegui('east')
%%
for frame = 1:n_frames
    for k = 1:ncutcells
        % create image. extract each detection for frame
        detimg(cutidx(1,k),cutidx(2,k)) = dets(k,frame);
        th_img(cutidx(1,k),cutidx(2,k)) = th(k,frame);
    end
    tiledlayout(1,4)
    nexttile
    imagesc([], rng_bins, detimg)
    title("2D CFAR detections")
    ylabel("Range (m)")
    grid
    nexttile
    imagesc([],rng_bins, sftmagdb(fft_frames(:,:,frame)))
    title("2D FFT")
    ylabel("Range (m)")
    grid
    nexttile
    imagesc([], rng_bins, th_img)
    title("2D CFAR threshold")
    ylabel("Range (m)")
    grid
    nexttile
    imagesc([], rng_bins,cutimage)
    title("Cells under test")
    ylabel("Range (m)")
    grid
    drawnow;
    pause(0.05)
end
% return;
%% Last frame
% close all
% figure
% tiledlayout(1,4)
% nexttile
% surf(detimg)
% title("2D CFAR detections")
% ylabel("Range (m)")
% grid
% nexttile
% surf(sftmagdb(fft_frames(:,:,frame)))
% title("2D FFT")
% ylabel("Range (m)")
% grid
% nexttile
% surf(mag2db(th_img))
% title("2D CFAR threshold")
% ylabel("Range (m)")
% grid
% nexttile
% surf(cutimage)
% title("Cells under test")
% ylabel("Range (m)")
% grid
% 



%% Detection
% for k = 1:ncutcells
%     % create image. extract each detection for frame
%     detimg(cutidx(1,k),cutidx(2,k)) = dets(k,frame);
%     th_img(cutidx(1,k),cutidx(2,k)) = th(k,frame);
% end
%%
% frame = 6;
% % Select frame
% d = dets(:,frame);
% 
% % Get coordinate of peaks, if any
% coord = cutidx.*d';
% row = max(coord(1, :));
% col = max(coord(2, :));

% Range

rng_array = zeros(5,n_frames);

% for each frame
for frame = 1:n_frames
    
    % Obtain detections
    d = dets(:,frame);

    % Get coordinate of peaks, if any
    coords = cutidx.*d';
    %any(coords)
    if any(coords(1,:))

        rows = coords(1, find(coords(1, :), 5));
        cols = coords(2, find(coords(2, :), 5));
        rng_array(1:length(rows),frame) = rng_bins(rows);
    end
end
%%
rng_time = reshape(rng_array, 1, []);
rng_time_smooth = rng_time;
for u = 1:length(rng_time)
    if ((rng_time(u) == 0) && (u == 1))
        rng_time_smooth(u) = rng_time_smooth(u+1); 

    elseif (rng_time(u) == 0)
        rng_time_smooth(u) = rng_time_smooth(u-1);
    end
end
t_ax = linspace(0, n_sweeps*t_sweep, length(rng_time));
close all
figure
plot(t_ax, rng_time);
hold on
plot(t_ax, rng_time_smooth)

% Doppler

%%
close all
figure
tiledlayout(2,1)
nexttile
imagesc([], rng_bins, detimg)
title("2D CFAR detections")
grid
nexttile
imagesc([],rng_bins, fftshift(abs(fft_frames(:,:,frame))))
title("2D FFT")
% imagesc([], rng_bins, th_img)
% title("2D CFAR threshold")
grid
%axis equal

%IQ2D = fft2(iq.');
%%
% close all
% figure
% imagesc(det)
% %%
% x = abs(fft_frames(:,:,3));
%% plots
% 
close all
figure
plot(f/1000,fftshift(20*log10(abs(fft_frames(:,:,1)))))


