addpath('../matlab_lib/');
addpath('../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
subset =1000:1100;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
%F = 0.015; % see relevant papers
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);
hmwin = hamming(n_samples);
iq_u = iq_u.*hmwin.';
iq_d = iq_d.*hmwin.';
n_fft = 512;
% factor of signal to be nulled. 4% determined experimentally
% nul_width_factor = 0.04;
% num_nul = round((n_fft/2)*nul_width_factor);
% nul_lower = round(n_fft/2 - num_nul);
% nul_upper = round(n_fft/2 + num_nul);

IQ_UP = fft(iq_u,n_fft,2);
IQ_DN = fft(iq_d,n_fft,2);

% Null feedthrough
% NOTE: USING ZEROS AFFECTS CFAR!
% METHOD 1: hold value
% METHOD 2: filter after CFAR
% IQ_UP(:,nul_lower:nul_upper) = repmat(IQ_UP(:,nul_lower-1),1,nul_upper-nul_lower+1) ;
% IQ_DN(:,nul_lower:nul_upper) = repmat(IQ_DN(:,nul_lower-1),1,nul_upper-nul_lower+1);

% Choose guard cells based on car size vs radar resolution. Or peak width
guard = 4;
% too many training cells results in too many detections
train = 50;
% false alarm rate - sets sensitivity
F = 10e-3; % see relevant papers
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
    'ThresholdOutputPort', true, ...
    'Rank', train);

% modify CFAR code to simultaneously record beat frequencies
% up_detections = CA(abs(IQ_UP)', 1:n_fft);
% dn_detections = CA(abs(IQ_DN)', 1:n_fft);

[up_soca, soca_th] = SOCA(abs(IQ_UP)', 1:n_fft);
% dn_soca = SOCA(abs(IQ_DN)', 1:n_fft);

[up_goca, goca_th] = GOCA(abs(IQ_UP)', 1:n_fft);
% dn_goca = GOCA(abs(IQ_DN)', 1:n_fft);

[up_ca  ,   ca_th] = CA(abs(IQ_UP)', 1:n_fft);
% dn_ca = CA(abs(IQ_DN)', 1:n_fft);

[up_os  ,   os_th] = OS(abs(IQ_UP)', 1:n_fft);
% dn_os = OS(abs(IQ_DN)', 1:n_fft);

soca_pku = abs(IQ_UP).*up_soca';
% soca_pkd = abs(IQ_DN).*dn_soca';

goca_pku = abs(IQ_UP).*up_goca';
% goca_pkd = abs(IQ_DN).*dn_goca';

ca_pku = abs(IQ_UP).*up_soca';
% ca_pkd = abs(IQ_DN).*dn_soca';

os_pku = abs(IQ_UP).*up_soca';
% os_pkd = abs(IQ_DN).*dn_soca';

fs = 200e3; %200 kHz
f = f_ax(n_fft, fs)/1000;
%% Process

v_max = 60/3.6; 
fd_max = 3e3;
fb = zeros(n_sweeps,2);
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);

close all
fg = figure;
movegui(fg,'east');
% tiledlayout(2,1)
% nexttile
p1 = plot(f, sftmagdb(IQ_UP(1,:)));
axis([min(f) max(f) 80 200])
hold on
soca = plot(f, sftmagdb(soca_th(:, 1)), 'DisplayName','SOCA: train = 50, guard = 4');
hold on
goca = plot(f, sftmagdb(goca_th(:, 1)), 'DisplayName','GOCA: train = 50, guard = 4');
hold on
ca = plot(f, sftmagdb(ca_th(:, 1)), 'DisplayName','CA: train = 50, guard = 4');
hold on
os = plot(f, sftmagdb(os_th(:, 1)), 'DisplayName','OS: train = 50, guard = 4, rank = 50');
% os = stem(sftmagdb(os_th(:, 1)), 'DisplayName','OS', 'Marker','v', ...
%     'MarkerSize',17);
title("CFAR Comparison for P_{fa} = 10^{-3}")
xlabel("Frequency (kHz)")
ylabel("Magnitude (dB)")
legend
hold off
% 
% soca = stem(sftmagdb(soca_th(:, 1)), 'DisplayName','SOCA', 'Marker','_', ...
%     'MarkerSize',30);
% hold on
% goca = stem(sftmagdb(goca_th(:, 1)), 'DisplayName','GOCA', 'Marker','.', ...
%     'MarkerSize',13);
% hold on
% ca = stem(sftmagdb(ca_th(:, 1)), 'DisplayName','CA', 'Marker','^', ...
%     'MarkerSize',15);


% nexttile
%     plot(sftmagdb(IQ_DN(i,:)))
% hold on
% stem(sftmagdb(soca_pkd(i,:)), 'DisplayName','SOCA', 'Marker','_', ...
%     'MarkerSize',30)
% hold on
% stem(sftmagdb(goca_pkd(i,:)), 'DisplayName','GOCA', 'Marker','.', ...
%     'MarkerSize',13)
% hold on
% stem(sftmagdb(ca_pkd(i,:)), 'DisplayName','CA', 'Marker','^', ...
%     'MarkerSize',15)
% hold on
% stem(sftmagdb(os_pkd(i,:)), 'DisplayName','OS', 'Marker','v', ...
%     'MarkerSize',17)
% legend
% hold off
%%
for i = 1:n_sweeps
    set(p1  , 'YData', sftmagdb(   IQ_UP(i, :)))
    set(soca, 'YData', sftmagdb(soca_th(:, i)))
    set(goca, 'YData', sftmagdb(goca_th(:, i)))
    set(ca  , 'YData', sftmagdb(  ca_th(:, i)))
    set(os  , 'YData', sftmagdb(  os_th(:, i)))
    pause(1)
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


