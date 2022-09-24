% last section of the 20 km/h test 
subset = 1000:2000;
% first portion 60 kmh
subset = 900:1100;

addpath('../../../matlab_lib/');
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);

% ======================== Tunable parameters =============================
% These determine the system detection performance
nbar = 3;
sll = -200;
F = 1e-3;
n_fft = 4096;
n_interp = 2*n_fft;
% =========================================================================

% Taylor Window
% win = taylorwin(n_samples, nbar, sll);
win = hamming(n_samples);

iq_u = iq_u.*win.';
iq_d = iq_d.*win.';

% FFT
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

IQ_UP = fft(iq_u,n_fft,2);
IQ_DN = fft(iq_d,n_fft,2);

% IQ_UP = interpft(IQ_UP,n_interp,2);
% IQ_DN = interpft(IQ_DN,n_interp,2);

% Halve FFTs
IQ_UP = IQ_UP(:, 1:n_fft/2);
IQ_DN = IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
% METHOD 1: slice
% IQ_UP(:, 1:num_nul) = 0;
% IQ_DN(:, end-num_nul+1:end) = 0;

% METHOD 2: Remove average
IQ_UP2 = IQ_UP - mean(IQ_UP,2);
IQ_DN2 = IQ_DN - mean(IQ_DN,2);

% flip
IQ_DN = flip(IQ_DN,2);
IQ_DN2 = flip(IQ_DN2,2);
%%
dat1 = absmagdb(IQ_DN);
dat2 = absmagdb(IQ_UP);

% ax_dims = [0 round(n_interp/2) 60 160];
ax_dims = [0 round(n_fft/2) 60 160];
sweep = 1;
close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'east')
tiledlayout(2,1)
nexttile
p1 = plot(dat1(sweep,:));
title("UP chirp positive half")
axis(ax_dims)
nexttile
p2 = plot(dat2(sweep,:));
title("DOWN chirp flipped negative half")
axis(ax_dims)
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
    set(p1, 'YData',dat1(i,:))
    set(p2, 'YData',dat2(i,:))
    drawnow;
end
