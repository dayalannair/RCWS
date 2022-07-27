fc = 24.005e9;
c = physconst('LightSpeed');
% CW
lambda_cw = c/fc;

% For sawtooth FMCW
tm = 1e-3;                      % Ramp duration
bw = 230e6;                     % Bandwidth
sweep_slope = bw/tm;




addpath('../library/');
addpath('../../../OneDrive - University of Cape Town/RCWS_DATA/home_passage/');
% Import data
%iq_tbl=readtable('IQ_sawtooth4096_backyrd.txt', 'Delimiter' ,' ');
cw_tbl=readtable('iq_CW_dual_10-20-03.txt', 'Delimiter' ,' ');
subset = 1:256;
i_cw = table2array(cw_tbl(subset,1:200));
q_cw = table2array(cw_tbl(subset,201:400));
iq_cw = i_cw + 1i*q_cw;

saw_tbl=readtable('iq_FMCW_dual_10-20-03.txt', 'Delimiter' ,' ');
i_saw = table2array(saw_tbl(subset,1:200));
q_saw = table2array(saw_tbl(subset,201:400));
iq_saw = i_saw + 1i*q_saw;
%%
% Dimensions
n_samples = size(i_cw,2);
n_sweeps = size(i_cw,1);

IQ_CW = fft(iq_cw,[],2);
IQ_FMCW = fft(iq_saw,[],2);

% close all
% figure
% for sweep = 1:n_sweeps
%     tiledlayout(2,1)
%     nexttile
%     plot(sftmagdb(IQ_CW(sweep,:)).')
%     title("CW FFT")
%     nexttile
%     plot(sftmagdb(IQ_SAW(sweep,:)).')
%     title("FMCW Sawtooth FFT")
%     pause(0.05)
% end
% train_factor = 0.1;
% % from 4/200 = 0.02;
% guard_factor = 0.02;
% guard = round(n_fft*guard_factor);
% train = round(n_fft*train_factor);
% % false alarm rate - sets sensitivity
% F = 0.011; % see relevant papers

train = 40;
guard = 6;
F = 0.00001;
n_fft = n_samples;
CFAR = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA');

cw_detections = CFAR(abs(IQ_CW)', 1:n_fft);
fmcw_detections = CFAR(abs(IQ_FMCW)', 1:n_fft);

fs = 200e3;
delta_f = fs/n_samples;
% half axis
f = 0:delta_f:(fs/2 -1);
IQ_CW_peaks = abs(IQ_CW).*cw_detections';
IQ_FMCW_peaks = abs(IQ_FMCW).*fmcw_detections';
%%
IQ_CW_peaks = IQ_CW_peaks(:,1:round(n_fft/2));
IQ_FMCW_peaks = IQ_FMCW_peaks(:,1:round(n_fft/2));
%%
v_max = 80/3.6;
fd_max = speed2dop(2*v_max,lambda_cw);
fb = zeros(n_sweeps,2);
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);
for i = 1:n_sweeps
    
    % null feed through
    IQ_CW_peaks(i,1:4) = 0;
    IQ_FMCW_peaks(i,1:4) = 0;
    
    % Only positive Doppler
    [highest_SNR_up, pk_idx_cw]= max(IQ_CW_peaks(i,:));
    % Only positive range
    [highest_SNR_down, pk_idx_fmcw] = max(IQ_FMCW_peaks(i,:));

    % Doppler shift
    fb(i, 1) = f(pk_idx_cw);
    % Range 
    fb(i, 2) = f(pk_idx_fmcw);

       % MTI and high dopp filter
    if and(and(fb(i, 1),fb(i, 2) ~= 0), fb(i, 1)<fd_max)
        fd_array(i) = fb(i, 1)/2;
        speed_array(i) = dop2speed(fb(i, 1)/2,lambda_cw)/2;
        range_array(i) = beat2range(fb(i,2), sweep_slope, c);
    end
end
close all
figure
tiledlayout(2,1)
nexttile
stem(range_array)
nexttile
stem(speed_array)
return;
%%
close all
figure
for sweep = 1:n_sweeps
    tiledlayout(2,1)
    nexttile
    plot(10*log10(abs(IQ_CW(sweep,1:100))).')
    hold on
    stem(10*log10(abs(IQ_CW_peaks(sweep,:))).')
    hold off
    title("CW FFT")
    nexttile
    plot(10*log10(abs(IQ_FMCW(sweep,1:100))).')
    hold on
    stem(10*log10(abs(IQ_FMCW_peaks(sweep,:))).')
    title("FMCW Sawtooth FFT")
    pause(0.05)
end

% plot(sftmagdb(IQ).')
% plot(fftshift(angle(IQ.')))