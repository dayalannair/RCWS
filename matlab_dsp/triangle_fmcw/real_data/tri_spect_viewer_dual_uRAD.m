% last section of the 20 km/h test 
subset = 1000:2000;
% first portion 60 kmh
subset = 1:50;

addpath('../../../matlab_lib/');
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/dual_uRAD/');
[fc, c, lambda, tm, bw, k, rpi_iq_u, rpi_iq_d, usb_iq_u, ...
    usb_iq_d, t_stamps] = import_dual_data(subset);
n_samples = size(rpi_iq_u,2);
n_sweeps = size(rpi_iq_u,1);

% Taylor Window
nbar = 4;
sll = -38;
twin = taylorwin(n_samples, nbar, sll);
rpi_iq_u = rpi_iq_u.*twin.';
rpi_iq_d = rpi_iq_d.*twin.';
usb_iq_u = usb_iq_u.*twin.';
usb_iq_d = usb_iq_d.*twin.';

% FFT
n_fft = 512;
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

RPI_IQ_UP = fft(rpi_iq_u,n_fft,2);
RPI_IQ_DN = fft(rpi_iq_d,n_fft,2);

USB_IQ_UP = fft(usb_iq_u,n_fft,2);
USB_IQ_DN = fft(usb_iq_d,n_fft,2);

% Halve FFTs
USB_IQ_UP = USB_IQ_UP(:, 1:n_fft/2);
USB_IQ_DN = USB_IQ_DN(:, n_fft/2+1:end);

RPI_IQ_UP = RPI_IQ_UP(:, 1:n_fft/2);
RPI_IQ_DN = RPI_IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
% METHOD 1: slice
% USB_IQ_UP(:, 1:num_nul) = 0;
% USB_IQ_DN(:, end-num_nul+1:end) = 0;
% 
% % METHOD 2: Remove average
% IQ_UP2 = USB_IQ_UP - mean(USB_IQ_UP,2);
% IQ_DN2 = USB_IQ_DN - mean(USB_IQ_DN,2);

% flip
USB_IQ_DN = flip(USB_IQ_DN,2);
RPI_IQ_DN = flip(RPI_IQ_DN,2);
% IQ_DN2 = flip(IQ_DN2,2);
%%
ax_dims = [0 256 60 200];
close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'west')
tic
for sweep = 1:n_sweeps
    tiledlayout(2,2)
    nexttile
    plot(absmagdb(USB_IQ_UP(sweep,:)))
    title("RPI UP chirp positive half")
    axis(ax_dims)
    nexttile
    plot(absmagdb(USB_IQ_DN(sweep,:)))
    title("RPI DOWN chirp flipped negative half")
    axis(ax_dims)
    nexttile
    plot(absmagdb(RPI_IQ_UP(sweep,:)))
    title("USB UP chirp positive half")
    axis(ax_dims)
    nexttile
    plot(absmagdb(RPI_IQ_DN(sweep,:)))
    title("USB DOWN chirp flipped negative half")
    axis(ax_dims)
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
    drawnow;
    % pause for elapsed time (see python output) / 2*num_sweeps
    % figure out why half is needed
    % UPDATE: plot does not update at this rate
%     pause(0.025)
end
toc