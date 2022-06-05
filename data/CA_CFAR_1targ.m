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
iq_tbl=readtable('IQ_0_1024_sweeps.txt','Delimiter' ,' ');
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
IQ_UP = fftshift(fft(iq_up,[],2));
IQ_DOWN = fftshift(fft(iq_down,[],2));

% modify CFAR code to simultaneously record beat frequencies
up_detections = CFAR(abs(IQ_UP)', 1:n_samples);
down_detections = CFAR(abs(IQ_DOWN)', 1:n_samples);
fs = 200e3; %200 kHz
f = f_ax(n_samples, fs);
IQ_UP_peaks = abs(IQ_UP).*up_detections';
IQ_DOWN_peaks = abs(IQ_DOWN).*down_detections';
%%
close all
figure
tiledlayout(2,1)
nexttile
stem(f(101:200)/1000, 10*log10(abs(IQ_UP_peaks(:,101:200))'))
nexttile
stem(f(1:100)/1000, 10*log10(abs(IQ_DOWN_peaks(:,1:100))'))
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
fbu = zeros(n_sweeps);
fbd = zeros(n_sweeps);
% Each sample can return a detection - max number of targets is 200?
% beat2range - expects a set of beat freqs up and down
range_array = zeros(n_sweeps);
fd_array = zeros(n_sweeps);
speed_array = zeros(n_sweeps);
for i = 1:n_sweeps
    
    % SINGLE TARG:
    % null feed through
    IQ_UP_peaks(i,98:104) = 0;
    IQ_DOWN_peaks(i,98:104) = 0;
    [highest_SNR_up, pk_idx_up]= max(IQ_UP_peaks(i,:))
    [highest_SNR_down, pk_idx_down] = max(IQ_DOWN_peaks(i,:))

    fbu(i) = f(pk_idx_up);
    fbd(i) = f(pk_idx_down);

    range_array(i) = beat2range([fbu(i) fbd(i)], sweep_slope, c);
    fd_array(i) = (-fbd(i)-fbu(i))/2;
    speed_array(i) = dop2speed(fd_array(i),lambda)/2;
end

% Determine range
% range_array = beat2range([ ])
%% Plots
close all
figure
tiledlayout(2,1)
nexttile
plot(range_array)
nexttile
plot(speed_array)


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

