% Experiment to test computing the difference between
% subsequent/adjacent FFTs

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
IQ = fft(iq, [], 2);
IQ_diffs = diff(IQ);
fs = 200e3;
f = f_ax(200, fs);
rng_bins = beat2range(f.', sweep_slope, c);

close all
figure
plot(rng_bins,20*log10(fftshift(abs(IQ))))

%%

% Axes
fs = 200e3;
f = f_ax(200, fs);
rng_bins = beat2range(f.', sweep_slope, c);
tsweep = 1e-3;
tframe = n_sweeps_per_frame*tsweep;
%IQ2D = fft2(iq.');


%% plots
% 
close all
figure
plot(f/1000,fftshift(20*log10(abs(fft_frames(:,:,1)))))
%% Square law detector
iq = i_dat + 1i*q_dat;
IQ = fft(iq, [], 2);
iq2 = i_dat.^2 + q_dat.^2;
IQ2 = fft(iq2, [], 2);
fs = 200e3;
f = f_ax(200, fs);
close all 
figure
tiledlayout(2,1)
nexttile
plot(f/1000,fftshift(20*log10(abs(IQ(200:205,:)))))

nexttile
plot(f/1000,fftshift(20*log10(abs(IQ2(200:205,:)))))