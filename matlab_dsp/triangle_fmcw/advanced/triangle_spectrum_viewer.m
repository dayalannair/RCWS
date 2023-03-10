%{
%% PLOT TRIANGLE FMCW SPECTRA
Script to plot only the spectra after application of a window function and
an N-point FFT
%}

% Import data and parameters
subset = 900:1100;
addpath('../../../matlab_lib/');
addpath(['../../../../../OneDrive - ' ...
    'University of Cape Town/RCWS_DATA/car_driveby/']);
% Import video
addpath(['../../../../../OneDrive - ' ...
    'University of Cape Town/RCWS_DATA/videos/']);
n_samples = 200;
% Taylor Window
nbar = 3;
sll = -100;
win = taylorwin(n_samples, nbar, sll);
% win = hamming(n_samples);
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = ...
    import_data(subset, win.');
n_sweeps = size(iq_u,1);

% ======================== Tunable parameters =============================
% These determine the system detection performance
% nbar = 3;
% sll = -200;
% F = 1e-3;
n_fft = 512;
% n_interp = 2*n_fft;
% =========================================================================

% Taylor Window
% win = taylorwin(n_samples, nbar, sll);
% win = hamming(n_samples);
% 
% iq_u = iq_u.*win.';
% iq_d = iq_d.*win.';

% FFT
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

FFT_U = fft(iq_u,n_fft,2);
FFT_D = fft(iq_d,n_fft,2);

% FFT_U = interpft(FFT_U,n_interp,2);
% FFT_D = interpft(FFT_D,n_interp,2);

% Halve FFTs
FFT_U = FFT_U(:, 1:n_fft/2);
FFT_D = FFT_D(:, n_fft/2+1:end);

% Null feedthrough
% METHOD 1: slice
FFT_U(:, 1:num_nul) = 0;
FFT_D(:, end-num_nul+1:end) = 0;

% METHOD 2: Remove average
% DEPRECATED - remove avg in IQ
% IQ_UP2 = FFT_U - mean(FFT_U,2);
% IQ_DN2 = FFT_D - mean(FFT_D,2);

% flip
FFT_D = flip(FFT_D,2);
% IQ_DN2 = flip(IQ_DN2,2);
%%
FFT_U = absmagdb(FFT_U);
FFT_D = absmagdb(FFT_D);

% ax_dims = [0 round(n_interp/2) 60 160];
% ax_dims = [0 round(n_fft/2) 30 140];
sweep = 1;
close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'east')
tiledlayout(2,1)
nexttile
p1 = plot(FFT_U(sweep,:));
title("UP chirp positive half")
% axis(ax_dims)
nexttile
p2 = plot(FFT_D(sweep,:));
title("DOWN chirp flipped negative half")
% axis(ax_dims)
% nexttile
% plot(absmagdb(IQ_UP2(sweep,:)))
% title("UP chirp positive half average nulling")
% axis(ax_dims)
% nexttile
% plot(absmagdb(IQ_DN2(sweep,:)))
% title("DOWN chirp flipped negative half average nulling")
% axis(ax_dims)
%     nexttile
%     plot(abs(IQ_UP2(sweep,:)))
%     title("UP chirp positive half average nulling")
%     axis([0 256 0 7e6])
% %     yline(125)
%     nexttile
%     plot(abs(IQ_DN2(sweep,:)))
%     title("DOWN chirp flipped negative half average nulling")
%     axis([0 256 0 7e6])
% %     yline(125)

%     pause(0.1)

for i = 1:n_sweeps
    set(p1, 'YData',FFT_U(i,:))
    set(p2, 'YData',FFT_D(i,:))
    drawnow;
end
