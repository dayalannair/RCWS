%{
%% PLOT TRIANGLE FMCW BEAT SPECTRA
Script to plot only the spectra after application of a window function and
an N-point FFT
%}
% Import data and parameters
% subset = 900:1100;
subset = 1:2700;
subset = 750:1100;
addpath('../../../matlab_lib/');
addpath(['../../../../../OneDrive - ' ...
    'University of Cape Town/RCWS_DATA/car_driveby/']);
addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_03_03_2023/iq_data/']);

addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/calibration']);
% Import video
% addpath(['../../../../../OneDrive - ' ...
%     'University of Cape Town/RCWS_DATA/videos/']);
Ns = 200;

nbar = 3;
sll = -20;
% win = taylorwin(Ns, nbar, sll);

win =   rectwin(Ns);
win = kaiser(Ns, 2.5);

[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = ...
    import_data(subset, win.');

n_sweeps = size(iq_u,1);
n_fft = 512;

%%
% FFT - note that true value is normalised by dividing by Ns
FFT_U = fft(iq_u,n_fft,2);%/Ns
FFT_D = fft(iq_d,n_fft,2);

% Halve FFTs
FFT_U = FFT_U(:, 1:n_fft/2);
FFT_D = FFT_D(:, n_fft/2+1:end);

% Flip negative half of down chirp spectrum
FFT_D = flip(FFT_D,2);

FFT_U = absmagdb(FFT_U);
FFT_D = absmagdb(FFT_D);

fs = 200e3;
f = f_ax(n_fft, fs);
f_neg = flip(-f(1:n_fft/2),2);
f_pos = f((n_fft/2 + 1):end);
rngAxPos = c*f_pos/(2*k);
rngAxNeg = c*f_neg/(2*k);

% ax_dims = [0 round(n_fft/2) -74 26];
% % f = fs/2*linspace(0,1,n_fft/2+1);
% ax_dims = [0 round(n_fft/2) -74 40];
% % ax_dims = [0 round(n_fft/2) -85 10];
% ax_dims = [0 max(f_pos) -110 20];
% ax_dims = [0 round(n_fft/2) -110 20];

ax_dims = [0 max(rngAxNeg) -60 20];
close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'east')
tiledlayout(2,1)

nexttile
p1 = plot(rngAxPos, FFT_U(1,:));
title("UP chirp positive half")
axis(ax_dims)

nexttile
p2 = plot(rngAxNeg, FFT_D(1,:));
title("DOWN chirp flipped negative half")
axis(ax_dims)

fbuIdx = zeros(n_sweeps, 1);
fbdIdx = zeros(n_sweeps, 1);
%%f
while(1)
    for i = 1:n_sweeps
        set(p1, 'YData',FFT_U(i,:))
        set(p2, 'YData',FFT_D(i,:))
    %     [ ~ , fbuIdx(i)] = max(FFT_U(i,:));
    %     [ ~ , fbdIdx(i)] = max(FFT_D(i,:));
        drawnow;
    end
end
return
%%
rng_u = rngAxPos(fbuIdx);
rng_d = rngAxNeg(fbdIdx);
% (f_pos(fbuIdx) + f_pos(fbdIdx))/2;
fbu = f_pos(fbuIdx).';
fbd = f_neg(fbdIdx).';

rng = beat2range([fbu; fbd], k, c);

fbAvg = (fbu + fbd)/2;
rngManual = c*fbAvg/(2*k);
%%
close all
scatter(t_stamps, rngManual)