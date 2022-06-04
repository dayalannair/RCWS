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
iq_tbl=readtable('IQ.txt','Delimiter' ,' ');
time = iq_tbl.Var801;
i_up = table2array(iq_tbl(:,1:200));
i_down = table2array(iq_tbl(:,201:400));
q_up = table2array(iq_tbl(:,401:600));
q_down = table2array(iq_tbl(:,601:800));

iq_up = i_up + 1i*q_up;
iq_down = i_down + 1i*q_down;

%% CA-CFAR
% false alarm rate
F = 1e-3;
n_samples = size(i_up,2);
n_sweeps = size(i_up,1);
%%
% Assumes AWGN
CFAR = phased.CFARDetector('NumTrainingCells',20, ...
    'NumGuardCells',2, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F);

% FFT
IQ_UP = fft(iq_up,[],2);
IQ_DOWN = fft(iq_down,[],2);

% modify CFAR code to simultaneously record beat frequencies
up_detections = CFAR(abs(IQ_UP)', 1:n_samples);
down_detections = CFAR(abs(IQ_DOWN)', 1:n_samples);

fs = 200e3; %200 kHz
f = f_ax(n_samples, fs);

fbu = zeros(n_sweeps,n_samples);
fbd = zeros(n_sweeps,n_samples);
% Each sample can return a detection - max number of targets is 200?
% beat2range - expects a set of beat freqs up and down
range_array = zeros(n_sweeps, n_samples);
fd_array = zeros(n_sweeps, n_samples);
speed_array = zeros(n_sweeps, n_samples);
for i = 1:n_sweeps
    % freq axis 'f' is already fftshifted
    fbu(i,:) = f.*fftshift(up_detections(:,i)');
    fbd(i,:) = f.*fftshift(down_detections(:,i)');

    range_array(i,:) = beat2range([fbu(i,:)' fbd(i,:)'], sweep_slope, c);
    fd_array(i,:) = (-fbd(i,:)'-fbu(i,:)')/2;
    speed_array(i,:) = dop2speed(fd_array(i,:),lambda)/2;
end

% Determine range
% range_array = beat2range([ ])
%% Plots
close all
figure
IQ_UP_normal = normalize(abs(IQ_UP));
for i = 1:52
%     plot(abs(iq_up(i,:)));
    plot(f/1000, 40*fftshift(up_detections(:,i))); % rows and columns opp to data
    hold on
    %plot(fftshift(IQ_UP_normal(i,:)))
    plot(f/1000, 10*log10(fftshift(abs(IQ_UP(i,:)))))
    hold off
    pause(0.5)
end
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

plot(fbu'/1000);
title("up chirp beat frequency");
xlabel("sample number");
ylabel("Frequency (kHz)");
axis([0 200 -100 100]);
hold on
plot(fbd'/1000);
title("down chirp beat frequency");
xlabel("sample number");
ylabel("Frequency (kHz)");
axis([0 200 -100 100]);

