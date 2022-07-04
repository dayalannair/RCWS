% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                    
bw = 240e6;                    
sweep_slope = bw/tm;
addpath('../../library/');

% Import data
subset = 1:512;
iq_tbl=readtable('../../data/urad_usb/IQ_sawtooth.txt', ...
    'Delimiter' ,' ');
i_dat = table2array(iq_tbl(subset,1:200));
q_dat = table2array(iq_tbl(subset,201:400));
iq = i_dat + 1i*q_dat;

n_samples = size(i_dat,2);
n_sweeps = size(i_dat,1);
n_sweeps_per_frame = 32;
n_frames = round(n_sweeps/n_sweeps_per_frame);

% Gaussian window
% gwin = gausswin(n_samples);
% iq = iq.*gwin.';

%fft_frames = zeros(n_samples, n_sweeps_per_frame, n_frames);
%lpf = txfeed_v1();

% Axes
n_fft = 512%n_samples;
fs = 200e3;
f = f_ax(n_fft, fs);
rng_bins = beat2range(f.', sweep_slope, c);
tsweep = 1e-3;
tframe = n_sweeps_per_frame*tsweep;
fft_frames = zeros(n_samples, n_sweeps_per_frame, n_frames);
%fdop = f_ax

% CFAR
F = 0.0011;
cfar2d = phased.CFARDetector2D('TrainingBandSize',[10 10], ...
    'GuardBandSize',[2 2], ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA', ...
    'ThresholdOutputPort', true);

%%
% You must restrict the locations of CUT cells 
% so that their training regions lie completely within the input images.
% bounds = train + guard = 10 + 2 = 12 then add 1 pad
Ngc = cfar2d.GuardBandSize(2);
Ngr = cfar2d.GuardBandSize(1);
Ntc = cfar2d.TrainingBandSize(2);
Ntr = cfar2d.TrainingBandSize(1);
cutidx = [];
colstart = Ntc + Ngc + 1;
colend = n_sweeps_per_frame - ( Ntc + Ngc);
rowstart = Ntr + Ngr + 1;
rowend = n_samples - ( Ntr + Ngr);
for m = colstart:colend
    for n = rowstart:rowend
        cutidx = [cutidx,[n;m]];
    end
end
ncutcells = size(cutidx,2)

cutimage = zeros(200,40);
for k = 1:ncutcells
    cutimage(cutidx(1,k),cutidx(2,k)) = 1;
end
close all
figure
imagesc(cutimage)
%axis equal
%%
figure
for i = 1:n_frames
    p1 = (i-1)*n_sweeps_per_frame + 1;
    p2 = i*n_sweeps_per_frame;
    fft_frames(:,:,i) = fft2(iq(p1:p2, :).');
    dets = cfar2d(abs(fft_frames(:,:,i)), cutidx);
    imagesc([], rng_bins,fftshift(20*log10(abs(fft_frames(:,:,i)))))
    %surf(fftshift(20*log10(abs(fft_frames(:,:,i)))))
%     surf(fftshift(20*log10(abs(fft_frames(:,:,i)))))
%     view(69.5124980863678, 46.4092184844678);
    pause(1)
end

%%
di = [];
for k = 1:ntrials
    d = dets(:,k);
    if (any(d) > 0)
        di = [di,k];
    end
end
idx = di(1);
detimg = zeros(N,N);
for k = 1:ncutcells
    detimg(cutidx(1,k),cutidx(2,k)) = dets(k,idx);
end
imagesc(detimg)
axis equal

%IQ2D = fft2(iq.');
%%
close all
figure
imagesc(det)
%%
x = abs(fft_frames(:,:,3));
%% plots
% 
% close all
% figure
% plot(f/1000,fftshift(20*log10(abs(fft_frames(:,:,1)))))


