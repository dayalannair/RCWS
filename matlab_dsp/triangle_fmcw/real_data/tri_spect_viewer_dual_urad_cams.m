% last section of the 20 km/h test 
subset = 1000:2000;
% first portion 60 kmh
subset = 1:1000;

addpath('../../../matlab_lib/');
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/dual_uRAD/');
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/road_data_03_11_2022/');
[fc, c, lambda, tm, bw, k, rpi_iq_u, rpi_iq_d, usb_iq_u, ...
    usb_iq_d, t_stamps] = import_dual_data_full();


% Get dimensions of data from slower device
n_samples = size(rpi_iq_u,2);
n_sweeps = size(rpi_iq_u,1);

% Decimate faster device data
% usb_iq_u = usb_iq_u(1:3:end, :);
% usb_iq_d = usb_iq_d(1:3:end, :);
% Taylor Window
nbar = 3;
sll = -100;
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

Ns = 200;
nfft = 512;
fs = 200e3;
f = f_ax(nfft, fs);
f_pos = f((n_fft/2 + 1):end);
sweep_slope = 240e6/1e-3;
rng_ax = beat2range((f_pos)', sweep_slope, c);
% flip
USB_IQ_DN = flip(USB_IQ_DN,2);
RPI_IQ_DN = flip(RPI_IQ_DN,2);

vid2 = VideoReader('out1.avi');
vid1 = VideoReader('out2.avi');
%%
USB_IQ_UP = absmagdb(USB_IQ_UP);
USB_IQ_DN = absmagdb(USB_IQ_DN);

RPI_IQ_UP = absmagdb(RPI_IQ_UP);
RPI_IQ_DN = absmagdb(RPI_IQ_DN);

ax_dims = [0 max(rng_ax) 80 190];
ax_ticks = 1:2:60;

close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'west')

subplot(2,3,1);
p1 = plot(rng_ax, RPI_IQ_UP(1,:));
title("RPI UP chirp positive half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,2);
p2 = plot(rng_ax, RPI_IQ_DN(1,:));
title("RPI DOWN chirp flipped negative half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,3);
vidFrame = readFrame(vid1);
v1 = imshow(vidFrame);

subplot(2,3,4);
p3 = plot(rng_ax, USB_IQ_UP(1,:));
title("USB UP chirp positive half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,3,5);
p4 = plot(rng_ax, USB_IQ_DN(1,:));
title("USB DOWN chirp flipped negative half")
axis(ax_dims)
xticks(ax_ticks)
grid on
subplot(2,3,6);
vidFrame = readFrame(vid2);
v2 = imshow(vidFrame);

tic
for sweep = 1:n_sweeps
%     for w = 1:6
%         vidFrame = readFrame(vidObj);
%     end
    set(p1, 'YData',RPI_IQ_UP(sweep,:))
    set(p2, 'YData',RPI_IQ_DN(sweep,:))
    set(p3, 'YData',USB_IQ_UP(sweep,:))
    set(p4, 'YData',USB_IQ_DN(sweep,:))
    
    
    vidFrame = readFrame(vid1);
%     v1.set(vidFrame)

    set(v1,'CData' ,vidFrame)

    vidFrame = readFrame(vid2);
%     v2.set(vidFrame)

    set(v2, 'CData', vidFrame)
%     disp(vidObj.CurrentTime)
%     disp(sweep)
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
    pause(0.05)
    drawnow;
    % pause for elapsed time (see python output) / 2*num_sweeps
    % figure out why half is needed
    % UPDATE: plot does not update at this rate
%     pause(0.025)
end
toc