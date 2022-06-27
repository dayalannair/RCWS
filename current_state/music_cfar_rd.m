% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
sweep_slope = bw/tm;

% Import data
%iq_tbl=readtable('IQ_0_1024_sweeps.txt','Delimiter' ,' ');
iq_tbl=readtable('trig_fmcw_data\IQ_0_1024_sweeps.txt','Delimiter' ,' ');
time = iq_tbl.Var801;
i_up = table2array(iq_tbl(:,1:200));
i_down = table2array(iq_tbl(:,201:400));
q_up = table2array(iq_tbl(:,401:600));
q_down = table2array(iq_tbl(:,601:800));

iq_up = i_up + 1i*q_up;
iq_down = i_down + 1i*q_down;

n_samples = size(i_up,2);
n_sweeps = size(i_up,1);

F = 0.015; % see relevant papers

CFAR = phased.CFARDetector('NumTrainingCells',20, ...
    'NumGuardCells',4, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA');

% FFT
n_fft = 200;%512;
IQ_UP = fftshift(fft(iq_up,n_fft,2));
IQ_DOWN = fftshift(fft(iq_down,n_fft,2));

% modify CFAR code to simultaneously record beat frequencies
up_detections = CFAR(abs(IQ_UP)', 1:n_fft);
down_detections = CFAR(abs(IQ_DOWN)', 1:n_fft);

fs = 200e3; %200 kHz
f = f_ax(n_fft, fs);
IQ_UP_peaks = abs(IQ_UP).*up_detections';
IQ_DOWN_peaks = abs(IQ_DOWN).*down_detections';

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

    if and(abs(fd_cf)<=fd_max, fd_cf > 0)
        dop_cf(i) = fd_rm/2;
        spd_cf(i) = dop2speed(fd_cf/2,lambda)/2;
        rng_cf(i) = beat2range([fb_cf(i,1) fb_cf(i,2)], sweep_slope, c);
    end
    % -------------------root MUSIC--------------------------
    fb_rm(i, 1) = rootmusic(iq_up(i, :).',1,fs);
    fb_rm(i, 2) = rootmusic(iq_down(i, :).',1,fs);

    fd_rm = -fb_rm(i,1)-fb_rm(i,2);

    if and(abs(fd_rm)<=fd_max, fd_rm > 0)
        dop_rm(i) = fd_rm/2;
        spd_rm(i) = dop2speed(fd_rm/2,lambda)/2;
        rng_rm(i) = beat2range([fb_rm(i,1) fb_rm(i,2)], sweep_slope, c);
    end
end

% Compare CFAR to root MUSIC

% subtract first time from all others to start at 0s
t0 = time(1);
time = time - t0;

close all
figure('WindowState','maximized');
movegui('east')
tiledlayout(2,1)
nexttile
plot(time, rng_rm.*1e4)
title('Range estimations of APPROACHING targets')
xlabel('Time (seconds)')
ylabel('Range (m)')
hold on
plot(time, rng_cf)
nexttile
plot(time, spd_rm*3.6)
title('Radial speed estimations of APPROACHING targets')
xlabel('Time (seconds)')
ylabel('Speed (km/h)')
hold on
plot(time, spd_cf)
