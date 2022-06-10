%% Cell Averaging CFAR (Constant False Alarm Rate) peak detector
% Most basic/common CFAR algorithm
%% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
sweep_slope = bw/tm;

%% Import data
%iq_tbl=readtable('IQ_0_1024_sweeps.txt','Delimiter' ,' ');
iq_tbl=readtable('IQ_0_8192_sweeps.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ.txt','Delimiter' ,' ');
time = iq_tbl.Var801;
i_up = table2array(iq_tbl(:,1:200));
i_down = table2array(iq_tbl(:,201:400));
q_up = table2array(iq_tbl(:,401:600));
q_down = table2array(iq_tbl(:,601:800));

iq_up = i_up + 1i*q_up;
iq_down = i_down + 1i*q_down;

%% CA-CFAR
% false alarm rate - sets sensitivity
F = 0.015;
n_samples = size(i_up,2);
n_sweeps = size(i_up,1);
% Assumes AWGN
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
%%
% close all
% figure
% tiledlayout(2,1)
% nexttile
% stem(f((n_fft/2+1):n_fft-1)/1000, 10*log10(abs(IQ_UP_peaks(:,(n_fft/2+1):n_fft-1))'))
% nexttile
% stem(f(1:n_fft/2)/1000, 10*log10(abs(IQ_DOWN_peaks(:,1:n_fft/2))'))
%% Verify CFAR
% close all
% figure
% for i = 1:n_sweeps
% %     plot(abs(iq_up(i,:)));
%     plot(f(101:200)/1000, 40*up_detections(101:200,i)); % rows and columns opp to data
%     hold on
%     %plot(fftshift(IQ_UP_normal(i,:)))
%     plot(f(101:200)/1000, 10*log10(abs(IQ_UP(i,101:200))))
%     hold off
%     pause(0.1)
% end
% for i = 1:n_sweeps
% %     plot(abs(iq_up(i,:)));
%     plot(f(1:100)/1000, 40*fftshift(down_detections(1:100,i))); % rows and columns opp to data
%     hold on
%     %plot(fftshift(IQ_UP_normal(i,:)))
%     plot(f(1:100)/1000, 10*log10(abs(IQ_DOWN(i,1:100))))
%     hold off
%     pause(0.1)
% end
%%
% flipped -- no need, can do at time of calculations

% dds = flip(down_detections(1:100,:));
% close all
% figure
% tiledlayout(2,1)
% nexttile
% stem(down_detections);
% nexttile
% stem(flip(down_detections));
% 
% %%
% close all
% figure
% tiledlayout(4,1)
% nexttile
% stem(f(101:200)/1000, up_detections(101:200,:));
% nexttile
% stem(f(101:100)/1000, flip(down_detections)(1:100,:));
% nexttile
% stem(f/1000, up_detections);
% nexttile
% stem(f/1000, down_detections);
%%
% close all
% figure
% tiledlayout(4,1)
%%
% v_max = 60km/h , fd max = 2.7kHz approx 3kHz
v_max = 60/3.6; 
%fd_max = speed2dop(v_max, lambda)*2;
fd_max = 3e3;
fb = zeros(n_sweeps,2);
%fbd = zeros(n_sweeps,2);
% Each sample can return a detection - max number of targets is 200?
% beat2range - expects a set of beat freqs up and down
% NB: MATLAB makes square matrix by default
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);

%%
for i = 1:n_sweeps
    
    % SINGLE TARG:
    % null feed through
    IQ_UP_peaks(i,98:104) = 0;
    IQ_DOWN_peaks(i,98:104) = 0;
    [highest_SNR_up, pk_idx_up]= max(IQ_UP_peaks(i,:));
    [highest_SNR_down, pk_idx_down] = max(IQ_DOWN_peaks(i,:));

    fb(i, 1) = f(pk_idx_up);
    fb(i, 2) = f(pk_idx_down);

    fd = -fb(i,1)-fb(i,2);
    % ensuring Doppler shift is within the maximum expected value also
    % serves to eliminate incorrect pairing of beat frequencies, which
    % affects both range and Doppler estimation
    % implement MTI condition: fd ~= 0
    % MTI + negative Doppler filter: fd > 0
    if and(abs(fd)<=fd_max, fd > 0)
        fd_array(i) = fd/2;
        speed_array(i) = dop2speed(fd/2,lambda)/2;
        range_array(i) = beat2range([fb(i,1) fb(i,2)], sweep_slope, c);
    end
end
% Determine range
% range_array = beat2range([ ])
%% Time Axis formulation
% subtract first time from all others to start at 0s
t0 = time(1);
time = time - t0;

%% Plots
close all
figure('WindowState','maximized');
movegui('east')
tiledlayout(2,1)
nexttile
plot(time, range_array)
title('Range estimations of APPROACHING targets')
xlabel('Time (seconds)')
ylabel('Range (m)')
% plot markings
hold on 
rectangle('Position',[0 0 6.6 15.6], 'EdgeColor','r', 'LineWidth',1)
text(0,17,'BMW')
rectangle('Position',[3.7 0 9.4580 15.6], 'EdgeColor','g', 'LineWidth',1)
text(3.7,17,'Renault+Nissan')
rectangle('Position',[13 0 8 30], 'EdgeColor','k', 'LineWidth',1)
text(13.5,25,'Pedestrians only')
rectangle('Position',[21.5 0 3.5 34], 'EdgeColor','r', 'LineWidth',1)
text(22,32,'Pedestrians+Mini')
rectangle('Position',[25.4 0 5.3 25], 'EdgeColor','g', 'LineWidth',1)
text(25.5,26,'Pedestrians+Hyundai')
rectangle('Position',[39 0 10 17], 'EdgeColor','m', 'LineWidth',1)
text(40,18,'VW followed by Toyota')
rectangle('Position',[56 0 24 32], 'EdgeColor','r', 'LineWidth',1)
text(57,33,'2x Toyota - Area of Interest')
nexttile
plot(time, speed_array*3.6)
title('Radial speed estimations of APPROACHING targets')
xlabel('Time (seconds)')
ylabel('Speed (km/h)')


%%
% IQ_UP_normal = normalize(abs(IQ_UP));


%%
% for i = 1:52
%     plot(fbu(i,:)/1000);
%     title("up chirp beat frequency");
%     xlabel("sample number");
%     ylabel("Frequency (kHz)");
%     axis([0 200 -100 100]);
%     hold on
%     plot(fbd(i,:)/1000);
%     title("down chirp beat frequency");
%     xlabel("sample number");
%     ylabel("Frequency (kHz)");
%     axis([0 200 -100 100]);
%     %hold off
%     pause(1)
% end
% plot(fftshift(detections));
% hold on
% plot(10*log10(fftshift(abs(IQ_UP))));

% plot(fbu'/1000);
% title("up chirp beat frequency");
% xlabel("sample number");
% ylabel("Frequency (kHz)");
% axis([0 200 -100 100]);
% hold on
% plot(fbd'/1000);
% title("down chirp beat frequency");
% xlabel("sample number");
% ylabel("Frequency (kHz)");
% axis([0 200 -100 100]);

