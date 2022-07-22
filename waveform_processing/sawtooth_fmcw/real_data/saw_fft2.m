addpath('../../library/');
addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/');

% Import data
%iq_tbl=readtable('IQ_sawtooth4096_backyrd.txt', 'Delimiter' ,' ');
iq_tbl=readtable('IQ_sawtooth2048_bkyrd_fast.txt', 'Delimiter' ,' ');
i_dat = table2array(iq_tbl(:,1:200));
q_dat = table2array(iq_tbl(:,201:400));
iq = i_dat + 1i*q_dat;
%%
% Dimensions
n_samples = size(i_dat,2);
n_sweeps = size(i_dat,1);

n_fft = n_samples;
n_sweeps_per_frame = 128;
n_frames = round(n_sweeps/n_sweeps_per_frame);
%tframe = n_sweeps_per_frame*t_sweep;

% Gaussian window
rng_gwin = gausswin(n_samples);
vel_gwin = gausswin(n_sweeps_per_frame);
%iq = iq.*rng_gwin.';

% Range axis
fs = 200e3;
f = f_ax(200, fs);
%rng_bins = beat2range(f.', sweep_slope, c);

% Radial velocity axis
angular_freq = -n_sweeps_per_frame/2:(n_sweeps_per_frame/2 -1);
%angular_freq = linspace(-n_sweeps_per_frame/2,n_sweeps_per_frame/2, ...
  %  n_sweeps_per_frame)
%vel_bins = lambda/(4*pi).*angular_freq;

%fdop = f_ax

% Reshape data set into frames and perform FFT
% Range on y-axis/as rows
fft_frames = zeros(n_samples, n_sweeps_per_frame, n_frames);
iq_frames = zeros(n_samples, n_sweeps_per_frame, n_frames);

t_sweep = 1e-3;
t_frame = n_sweeps_per_frame*t_sweep
close all
figure
for fr = 1:n_frames
    p1 = (fr-1)*n_sweeps_per_frame + 1;
    p2 = fr*n_sweeps_per_frame;
    %Doppler Window
    iq_frame = iq(p1:p2, :);
    %iq_conjwin = iq_frame.*vel_gwin; % will multiply rows
    iq_conjwin = iq_frame;
    fft_frames(:,:,fr) = fft2(iq_conjwin.');
    iq_frames(:,:,fr) = iq_conjwin.';
    % Plots
for i = 1:n_sweeps
    tiledlayout(2,1)
    nexttile
    plot(f/1000, sftmagdb(fft_frames(:,i, fr).'))
    title("Range FFT")
    nexttile
    plot(angular_freq,sftmag(fft_frames(i,:,fr).'))
    title("Doppler FFT")
    hold off
    pause(t_frame)
end
%     imagesc(sftmagdb(fft_frames(:,:,fr)))
%     pause(t_frame)
end
%%
% Plots
% close all
% figure
% for i = 1:n_sweeps
%     tiledlayout(2,1)
%     nexttile
%     plot(f/1000, 10*log10(fftshift(abs(fft_frames(:,i, 8).'))))
%     title("Range FFT")
%     nexttile
%     plot(10*log10(abs(fftshift(fft_frames(i,:,8).'))))
%     title("Doppler FFT")
%     hold off
%     pause(1)
% end





