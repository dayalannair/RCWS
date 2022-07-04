% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
sweep_slope = bw/tm;
addpath('../../library/');
% Import data
subset = 1:512;%200:205;

iq_tbl=readtable('../../data/urad_usb/IQ_sawtooth.txt','Delimiter' ,' ');
%time = iq_tbl.Var401;
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

fft_frames = zeros(n_samples, n_sweeps_per_frame, n_frames);
lpf = txfeed_v1();

% Axes
fs = 200e3;
f = f_ax(200, fs);
rng_bins = beat2range(f.', sweep_slope, c);
tsweep = 1e-3;
tframe = n_sweeps_per_frame*tsweep;


figure
for i = 1:n_frames
    p1 = (i-1)*n_sweeps_per_frame + 1;
    p2 = i*n_sweeps_per_frame;
    fft_frames(:,:,i) = fft2(iq(p1:p2, :).');
    %imagesc([], rng_bins,fftshift(20*log10(abs(fft_frames(:,:,i)))))
    %surf(fftshift(20*log10(abs(fft_frames(:,:,i)))))
    surf(fftshift(abs(fft_frames(:,:,i))))
    view(-75.9999998136893, 62.6634858340247);
    pause(1)
end

%IQ2D = fft2(iq.');


%% plots
% 
close all
figure
plot(f/1000,fftshift(20*log10(abs(fft_frames(:,:,1)))))


