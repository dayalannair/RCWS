subset = 200:205;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
%F = 0.015; % see relevant papers
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);
%% Gaussian Window
gwin = gausswin(n_samples);
iq_u = iq_u.*gwin.';
iq_d = iq_d.*gwin.';
% FFT
n_fft = 1024;%512;
% factor of signal to be nulled. 4% determined experimentally
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);
nul_lower = round(n_fft/2 - num_nul);
nul_upper = round(n_fft/2 + num_nul);

IQ_UP = fftshift(fft(iq_u,n_fft,2));
IQ_DOWN = fftshift(fft(iq_d,n_fft,2));

% Null feedthrough
% NOTE: USING ZEROS AFFECTS CFAR!
% METHOD 1: hold value
% METHOD 2: filter after CFAR
IQ_UP(:,nul_lower:nul_upper) = repmat(IQ_UP(:,nul_lower-1),1,nul_upper-nul_lower+1) ;
IQ_DOWN(:,nul_lower:nul_upper) = repmat(IQ_DOWN(:,nul_lower-1),1,nul_upper-nul_lower+1);
% from 20/200 = 0.1
train_factor = 0.1;
% from 4/200 = 0.02;
guard_factor = 0.02;
guard = 6;%round(n_fft*guard_factor);
train = 50;%round(n_fft*train_factor);
% false alarm rate - sets sensitivity
F = 0.011; % see relevant papers
%% CFAR
CA = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'CA', ...
    'ThresholdOutputPort', true);

SOCA = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA', ...
    'ThresholdOutputPort', true);

GOCA = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'GOCA', ...
    'ThresholdOutputPort', true);

OS = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true);

% modify CFAR code to simultaneously record beat frequencies
% up_detections = CA(abs(IQ_UP)', 1:n_fft);
% down_detections = CA(abs(IQ_DOWN)', 1:n_fft);

[up_detections, upth] = SOCA(abs(IQ_UP)', 1:n_fft);
down_detections = SOCA(abs(IQ_DOWN)', 1:n_fft);

% up_detections = GOCA(abs(IQ_UP)', 1:n_fft);
% down_detections = GOCA(abs(IQ_DOWN)', 1:n_fft);

% [up_detections, upth] = OS(abs(IQ_UP)', 1:n_fft);
% down_detections = OS(abs(IQ_DOWN)', 1:n_fft);

fs = 200e3; %200 kHz
f = f_ax(n_fft, fs);
IQ_UP_peaks = abs(IQ_UP).*up_detections';
IQ_DOWN_peaks = abs(IQ_DOWN).*down_detections';

%% Process

v_max = 60/3.6; 
fd_max = 3e3;
fb = zeros(n_sweeps,2);
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);

for i = 1:n_sweeps
    
%     IQ_UP_peaks(i,nul_lower:nul_upper) = 0;
%     IQ_DOWN_peaks(i,nul_lower:nul_upper) = 0;
    
    [highest_SNR_up, pk_idx_up]= max(IQ_UP_peaks(i,:));
    [highest_SNR_down, pk_idx_down] = max(IQ_DOWN_peaks(i,:));

    fb(i, 1) = f(pk_idx_up);
    fb(i, 2) = f(pk_idx_down);

    fd = -fb(i,1)-fb(i,2);

    if and(abs(fd)<=fd_max, fd > 400)
        fd_array(i) = fd/2;
        speed_array(i) = dop2speed(fd/2,lambda)/2;
        range_array(i) = beat2range([fb(i,1) fb(i,2)], k, c);
    end
end


