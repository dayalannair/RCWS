subset = 200:205;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
%F = 0.015; % see relevant papers
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);
addpath('../library/');
n_fft = 1024;
% factor of signal to be nulled. 4% determined experimentally
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);
% Taylor Window
nbar = 4;
sll = -38;
% gwinu = gausswin(n_samples);
% gwind = gausswin(n_samples);
twinu = taylorwin(n_samples, nbar, sll);
twind = taylorwin(n_samples, nbar, sll);
iq_u = iq_u.*twinu.';
iq_d = iq_d.*twind.';
% iq_u = iq_u.*gwinu.';
% iq_d = iq_d.*gwind.';
% FFT
IQ_UP = fft(iq_u,n_fft,2);
IQ_DN = fft(iq_d,n_fft,2);

% Halve FFTs
IQ_UP = IQ_UP(:, 1:n_fft/2);
IQ_DN = IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
IQ_UP(:, 1:num_nul) = 0;
IQ_DN(:, end-num_nul+1:end) = 0;

% IQ_UP(:, 1:num_nul) = repmat(IQ_UP(:,num_nul+1),1,num_nul);
% IQ_DN(:, end-num_nul+1:end) = repmat(IQ_DN(:,end-num_nul),1,num_nul);

%% CFAR
% Choose guard cells based on car size vs radar resolution. Or peak width
guard = 2*n_fft/n_samples;
guard = floor(guard/2)*2; % make even
% too many training cells results in too many detections
train = round(20*n_fft/n_samples);
train = floor(train/2)*2;
% false alarm rate - sets sensitivity
F = 10e-3; % see relevant papers

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
    'ThresholdOutputPort', true, ...
    'Rank',train);

% modify CFAR code to simultaneously record beat frequencies
% up_detections = CA(abs(IQ_UP)', 1:n_fft);
% dn_detections = CA(abs(IQ_DN)', 1:n_fft);

[up_soca, soc_thu] = SOCA(abs(IQ_UP)', 1:n_fft/2);
dn_soca = SOCA(abs(IQ_DN)', 1:n_fft/2);

[up_goca, goc_thu] = GOCA(abs(IQ_UP)', 1:n_fft/2);
dn_goca = GOCA(abs(IQ_DN)', 1:n_fft/2);

[up_ca, ca_thu] = CA(abs(IQ_UP)', 1:n_fft/2);
dn_ca = CA(abs(IQ_DN)', 1:n_fft/2);

[up_os, os_thu] = OS(abs(IQ_UP)', 1:n_fft/2);
[dn_os, os_thd] = OS(abs(IQ_DN)', 1:n_fft/2);

soca_pku = abs(IQ_UP).*up_soca';
soca_pkd = abs(IQ_DN).*dn_soca';

goca_pku = abs(IQ_UP).*up_goca';
goca_pkd = abs(IQ_DN).*dn_goca';

ca_pku = abs(IQ_UP).*up_ca';
ca_pkd = abs(IQ_DN).*dn_ca';

os_pku = abs(IQ_UP).*up_os';
os_pkd = abs(IQ_DN).*dn_os';

fs = 200e3; %200 kHz
f = f_ax(n_fft, fs);
%% Process

v_max = 60/3.6; 
fd_max = 3e3;
fb = zeros(n_sweeps,2);
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);

% close all
% fg = figure;
% movegui(fg,'east');
%%
for i = 1:n_sweeps
    tiledlayout(1,2)
    nexttile
    plot(absmagdb(IQ_DN(i,:)))
%     hold on
%     stem(absmagdb(soca_pkd(i,:)), 'DisplayName','SOCA', 'Marker','_', ...
%         'MarkerSize',30)
%     hold on
%     stem(absmagdb(goca_pkd(i,:)), 'DisplayName','GOCA', 'Marker','.', ...
%         'MarkerSize',13)
%     hold on
%     stem(absmagdb(ca_pkd(i,:)), 'DisplayName','CA', 'Marker','^', ...
%         'MarkerSize',15)
    hold on
    stem(absmagdb(os_pkd(i,:)), 'DisplayName','OS', 'Marker','v', ...
        'MarkerSize',10)
    hold on
    plot(absmagdb(os_thd(:,i)),'DisplayName','OS')
    legend
    hold off
    nexttile
    plot(absmagdb(IQ_UP(i,:)))
    hold on
%     stem(absmagdb(soca_pku(i,:)), 'DisplayName','SOCA', 'Marker','_', ...
%         'MarkerSize',30)
%     hold on
%     stem(absmagdb(goca_pku(i,:)), 'DisplayName','GOCA', 'Marker','.', ...
%         'MarkerSize',13)
%     hold on
%     stem(absmagdb(ca_pku(i,:)), 'DisplayName','CA', 'Marker','^', ...
%         'MarkerSize',15)
    hold on
    stem(absmagdb(os_pku(i,:)), 'DisplayName','OS', 'Marker','v', ...
        'MarkerSize',10)
    hold on
%     plot(absmagdb(soc_thu(:,i)),'DisplayName','SOCA')
%     hold on
%     plot(absmagdb(goc_thu(:,i)),'DisplayName','GOCA')
%     hold on
%     plot(absmagdb(ca_thu(:,i)),'DisplayName','CA')
%     hold on
    plot(absmagdb(os_thu(:,i)),'DisplayName','OS')
    legend
    hold off
    drawnow;
%     pause(2)
    
%     IQ_UP_peaks(i,nul_lower:nul_upper) = 0;
%     IQ_DN_peaks(i,nul_lower:nul_upper) = 0;
    
%     [highest_SNR_up, pk_idx_up]= max(IQ_UP_peaks(i,:));
%     [highest_SNR_dn, pk_idx_dn] = max(IQ_DN_peaks(i,:));
% 
%     fb(i, 1) = f(pk_idx_up);
%     fb(i, 2) = f(pk_idx_dn);
% 
%     fd = -fb(i,1)-fb(i,2);
% 
%     if and(abs(fd)<=fd_max, fd > 400)
%         fd_array(i) = fd/2;
%         speed_array(i) = dop2speed(fd/2,lambda)/2;
%         range_array(i) = beat2range([fb(i,1) fb(i,2)], k, c);
%     end
end


