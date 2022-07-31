% last section of the 20 km/h test 
subset = 1000:2000;
% first portion 60 kmh
subset = 800:2000;

addpath('../../../matlab_lib/');
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);

% Taylor Window
nbar = 4;
sll = -38;
twinu = taylorwin(n_samples, nbar, sll);
twind = taylorwin(n_samples, nbar, sll);
iq_u = iq_u.*twinu.';
iq_d = iq_d.*twind.';

% FFT
n_fft = 512;
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

IQ_UP = fft(iq_u,n_fft,2);
IQ_DN = fft(iq_d,n_fft,2);

% Halve FFTs
IQ_UP = IQ_UP(:, 1:n_fft/2);
IQ_DN = IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
% METHOD 1: slice
IQ_UP(:, 1:num_nul) = 0;
IQ_DN(:, end-num_nul+1:end) = 0;

% METHOD 2: Remove average
IQ_UP2 = IQ_UP - mean(IQ_UP);
IQ_DN2 = IQ_DN - mean(IQ_DN);

% flip
IQ_DN = flip(IQ_DN,2);
IQ_DN2 = flip(IQ_DN2,2);
%%
ax_dims = [0 256 60 160];
close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'west')
for sweep = 1:n_sweeps
    tiledlayout(2,2)
%     nexttile
%     plot(absmagdb(IQ_UP(sweep,:)))
%     title("UP chirp positive half slice nulling")
%     axis(ax_dims)
%     nexttile
%     plot(absmagdb(IQ_DN(sweep,:)))
%     title("DOWN chirp flipped negative half slice nulling")
%     axis(ax_dims)
    nexttile
    plot(absmagdb(IQ_UP2(sweep,:)))
    title("UP chirp positive half average nulling")
    axis(ax_dims)
    yline(125)
    nexttile
    plot(absmagdb(IQ_DN2(sweep,:)))
    title("DOWN chirp flipped negative half average nulling")
    axis(ax_dims)
    yline(125)
    nexttile
    plot(abs(IQ_UP2(sweep,:)))
    title("UP chirp positive half average nulling")
    axis([0 256 0 7e6])
%     yline(125)
    nexttile
    plot(abs(IQ_DN2(sweep,:)))
    title("DOWN chirp flipped negative half average nulling")
    axis([0 256 0 7e6])
%     yline(125)
    drawnow;
%     pause(0.1)
end
