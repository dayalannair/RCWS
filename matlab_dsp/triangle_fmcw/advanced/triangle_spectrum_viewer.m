%{
%% PLOT TRIANGLE FMCW BEAT SPECTRA
Script to plot only the spectra after application of a window function and
an N-point FFT
%}
% Import data and parameters
% subset = 900:1100;
subset = 1:2700;
addpath('../../../matlab_lib/');
addpath(['../../../../../OneDrive - ' ...
    'University of Cape Town/RCWS_DATA/car_driveby/']);
addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_03_03_2023/iq_data/']);
% Import video
addpath(['../../../../../OneDrive - ' ...
    'University of Cape Town/RCWS_DATA/videos/']);
n_samples = 200;

nbar = 3;
sll = -20;
win = taylorwin(n_samples, nbar, sll);

[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = ...
    import_data(subset, win.');
n_sweeps = size(iq_u,1);

n_fft = 512;

% FFT - note that true value is normalised by dividing by Ns
FFT_U = fft(iq_u,n_fft,2);
FFT_D = fft(iq_d,n_fft,2);

% Halve FFTs
FFT_U = FFT_U(:, 1:n_fft/2);
FFT_D = FFT_D(:, n_fft/2+1:end);

% Flip negative half of down chirp spectrum
FFT_D = flip(FFT_D,2);

FFT_U = absmagdb(FFT_U);
FFT_D = absmagdb(FFT_D);

ax_dims = [0 round(n_fft/2) -74 26];

close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'east')
tiledlayout(2,1)

nexttile
p1 = plot(FFT_U(1,:));
title("UP chirp positive half")
axis(ax_dims)

nexttile
p2 = plot(FFT_D(1,:));
title("DOWN chirp flipped negative half")
axis(ax_dims)

for i = 1:n_sweeps
    set(p1, 'YData',FFT_U(i,:))
    set(p2, 'YData',FFT_D(i,:))
    drawnow;
end
