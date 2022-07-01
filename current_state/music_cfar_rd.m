% Parameters
% Import data
subset = 200:205;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);

n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);

trn = 20;
grd = 4;
Pfa = 0.015;
n_fft = n_samples;

[fft_up, fft_dw, up_det, dw_det] = myCFAR(trn, grd, ...
    Pfa, iq_u, iq_d, n_fft);

fs = 200e3; %200 kHz
f = f_ax(n_fft, fs);
IQ_UP_peaks = abs(fft_up).*up_det';
IQ_DOWN_peaks = abs(fft_dw).*dw_det';

% v_max = 60km/h , fd_rm max = 2.7kHz approx 3kHz
v_max = 60/3.6; 
%fd_max = speed2dop(v_max, lambda)*2;
fd_max = 3e3;
fb_rm = zeros(n_sweeps,2);
fb_cf = zeros(n_sweeps,2);
rng_rm = zeros(n_sweeps,1);
rng_cf = zeros(n_sweeps,1);
dop_rm = zeros(n_sweeps,1);
dop_cf = zeros(n_sweeps,1);
spd_rm = zeros(n_sweeps,1);
spd_cf = zeros(n_sweeps,1);
fs = 200e3;
% Inverse FFT of the nulled feedthrough signal
fft_up(:,98:104) = 0;
fft_dw(:,98:104) = 0;
iqu_nul = ifft(fft_up, [], 2);
iqd_nul = ifft(fft_dw, [], 2);


for i = 1:n_sweeps

    % -------------------CA-CFAR--------------------------
    % null feed through
    IQ_UP_peaks(i,98:104) = 0;
    IQ_DOWN_peaks(i,98:104) = 0;
    
    [highest_SNR_up, pk_idx_up]= max(IQ_UP_peaks(i,:));
    [highest_SNR_down, pk_idx_down] = max(IQ_DOWN_peaks(i,:));

    fb_cf(i, 1) = f(pk_idx_up);
    fb_cf(i, 2) = f(pk_idx_down);

    fd_cf = -fb_cf(i,1)-fb_cf(i,2);

    if and(abs(fd_cf)<=fd_max,fd_cf~=0) %
        dop_cf(i) = fd_cf/2;
        spd_cf(i) = dop2speed(fd_cf/2,lambda)/2;
        rng_cf(i) = beat2range([fb_cf(i,1) fb_cf(i,2)], k, c);
    end
    % -------------------root MUSIC--------------------------
    % METHOD 1
%     fb_rm(i, 1) = rootmusic(iq_u(i, :).',1,fs);
%     fb_rm(i, 2) = rootmusic(iq_d(i, :).',1,fs);
% 
    % METHOD 2
    % using the signal in the second subspace dimension
%     fbu = rootmusic(iq_u(i, :),2,fs);
%     fbd = rootmusic(iq_d(i, :),2,fs);

    % METHOD 3
    % Inverse FFT of the nulled feedthrough signal
%     fbu = rootmusic(iqu_nul(i, :),1,fs);
%     fbd = rootmusic(iqd_nul(i, :),1,fs);

    % METHOD 4
    % Inverse nulled second ss dim
    fbu = rootmusic(iqu_nul(i, :),1,fs);
    fbd = rootmusic(iqd_nul(i, :),1,fs);
    
    % METHOD 5 ???
%     fbu = rootmusic(iqu_nul(i, :),1,fs);
%     fbd = rootmusic(iqd_nul(i, :),1,fs);


    fb_rm(i, 1) = fbu(1);
    fb_rm(i, 2) = fbd(1);
    fd_rm = -fb_rm(i,1)-fb_rm(i,2);
    %if and(abs(fd_rm)<=fd_max, fd_rm > 0)
    dop_rm(i) = fd_rm/2;
    spd_rm(i) = dop2speed(fd_rm/2,lambda)/2;
    rng_rm(i) = beat2range([fb_rm(i,1) fb_rm(i,2)], k, c);
    %end
end

%% Compare CFAR to root MUSIC

% subtract first t_stamps from all others to start at 0s
t0 = t_stamps(1);
t = t_stamps - t0;

close all
figure('WindowState','maximized');
movegui('east')
tiledlayout(2,1)
nexttile
plot(rng_rm)
title('Range estimations of APPROACHING targets')
xlabel('Time (seconds)')
ylabel('Range (m)')
hold on
plot(rng_cf)
nexttile
plot(spd_rm*3.6)
title('Radial speed estimations of APPROACHING targets')
xlabel('Time (seconds)')
ylabel('Speed (km/h)')
hold on
plot(spd_cf*3.6)
%%
A = rescale(real(iqu_nul(100, :)));
B = rescale(real(iqd_nul(100, :)));
figure          
close all
tiledlayout(2,1)
nexttile
plot(A)
%hold on
%plot(real(iq_u(100, :)))
nexttile
plot(B)
%hold on
%plot(real(iq_d(100, :)))
%%
figure          
close all
tiledlayout(2,1)
nexttile
% plot(real(iqu_nul(100, :)))
% hold on
plot(abs(fft_up(100, :)))
nexttile
% plot(real(iqd_nul(100, :)))
% hold on
plot(abs(fft_dw(100, :)))
