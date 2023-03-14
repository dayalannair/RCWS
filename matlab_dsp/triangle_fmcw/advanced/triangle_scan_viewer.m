%{
%% PLOT TRIANGLE FMCW TRACKING
Script to plot the CFAR threshold and tracking gate overlayed on the FFT of
each sweep
%}

% Import data and parameters
subset = 900:1100;
addpath('../../../matlab_lib/');
addpath(['../../../../../OneDrive - ' ...
    'University of Cape Town/RCWS_DATA/car_driveby/']);
% Import video
addpath(['../../../../../OneDrive - ' ...
    'University of Cape Town/RCWS_DATA/videos/']);
Ns = 200;
% Taylor Window
nbar = 3;
sll = -100;
win = taylorwin(Ns, nbar, sll);
win = rectwin(Ns);
% win = hamming(Ns);
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = ...
    import_data(subset, win.');
n_sweeps = size(iq_u,1);
%%

% iq_u = iq_u.*win.';
% iq_d = iq_d.*win.';

% FFT
n_fft = 512;
FFT_U = fft(iq_u*Ns,n_fft,2);
FFT_D = fft(iq_d*Ns,n_fft,2);

% FFT_U = fft(iq_u,n_fft,2);
% FFT_D = fft(iq_d,n_fft,2);

% Halve FFTs
FFT_U = FFT_U(:, 1:n_fft/2);
FFT_D = FFT_D(:, n_fft/2+1:end);

% Null feedthrough
% nul_width_factor = 0.04;
% num_nul = round((n_fft/2)*nul_width_factor);
% FFT_U(:, 1:num_nul) = 0;
% FFT_D(:, end-num_nul+1:end) = 0;

% FFT_U = FFT_U - mean(FFT_U);
% FFT_D = FFT_D - mean(FFT_D);
% CFAR
guard = 2*n_fft/Ns;
guard = floor(guard/2)*2; % make even
% too many training cells results in too many detections
train = round(20*n_fft/Ns);
train = floor(train/2)*2;
train = 16;
guard = 14;
% false alarm rate - sets sensitivity
F = 1e-5; 
CFAR_OBJ = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',train-5);

% flip
FFT_D = flip(FFT_D,2);

% Filter peaks/ peak detection
% [up_os, os_thu] = CFAR_OBJ(abs(FFT_U)', 1:n_fft/2);
% [dn_os, os_thd] = CFAR_OBJ(abs(FFT_D)', 1:n_fft/2);

% Square Law Detector
[up_os, os_thu] = CFAR_OBJ(((abs(FFT_U)').^2), 1:n_fft/2);
[dn_os, os_thd] = CFAR_OBJ(((abs(FFT_D)').^2), 1:n_fft/2);

% Find peak magnitude
os_pku = abs(FFT_U).*up_os';
os_pkd = abs(FFT_D).*dn_os';

% Define frequency axis
fs = 200e3;
f = f_ax(n_fft, fs);
f_neg = f(1:n_fft/2);
f_pos = f((n_fft/2 + 1):end);
rngAx = c*f_pos/(2*k);

v_max = 60/3.6; 
fd_max = speed2dop(v_max, lambda)*2;
% Minimum sample number for 1024 point FFT corresponding to min range = 10m
% n_min = 83;
% for 512 point FFT:
n_min = 42;
% Divide into range bins of width 64
nbins = 16;
% bin_width = (n_fft/2)/nbins;
bin_width = 16;
fbu = zeros(n_sweeps,nbins);
fbd = zeros(n_sweeps,nbins);

rg_array = zeros(n_sweeps,nbins);
fd_array = zeros(n_sweeps,nbins);
sp_array = zeros(n_sweeps,nbins);
beat_arr = zeros(n_sweeps,nbins);

osu_pk_clean = zeros(n_sweeps,n_fft/2);
osd_pk_clean = zeros(n_sweeps,n_fft/2);

% Make slightly larger to allow for holding previous
% >16 will always be 0 and not influence results
% previous_det = zeros(nbins+2, 1);
scan_width = 16;
f_bin_edges_idx = size(f_pos(),2)/nbins;
%
index_end = 0;
beat_index = 0;
close all
fig1 = figure('WindowState','maximized');
ax_dims = [0 round(max(f_pos)) -60 20];
ax_dims = [0 round(max(f_pos)) -85 10];
ax_dims = [0 round(max(f_pos)) 0 100];

ax_dims = [0 round(max(rngAx)) 0 100];

% ax_dims = [0 round(max(f_pos)) -45 50];
for i = 1:n_sweeps
   for bin = 0:(nbins-1)
        bin_slice_d = os_pkd(i,bin*bin_width+1:(bin+1)*bin_width);
        [magd, idx_d] = max(bin_slice_d);

        if magd ~= 0
            beat_index = bin*bin_width + idx_d;
            fbd(i,bin+1) = f_pos(beat_index);
           if (beat_index > bin_width)
               index_end = beat_index - scan_width;
               bin_slice_u = os_pku(i, index_end:beat_index);
           else
              index_end = 1;
              bin_slice_u = os_pku(i, 1:beat_index);
           end
            [magu, idx_u] = max(bin_slice_u);
        end
   end
    tiledlayout(2,1)
    nexttile
    plot(rngAx, absmagdb(FFT_D(i,:)))
    title("DOWN chirp flipped negative half average nulling")
    axis(ax_dims)
    hold on
    plot(rngAx, mag2db(sqrt(os_thd(:,i))))
    hold on
    stem(rngAx, mag2db(os_pkd(i,:)))
    hold on
    xline([beat_index index_end])
%     xline(lines)
    hold off

    nexttile
    plot(rngAx, absmagdb(FFT_U(i,:)))
    title("UP chirp positive half average nulling")
    axis(ax_dims)
    hold on
    plot(rngAx, mag2db(sqrt(os_thu(:,i))))
    hold on
    stem(rngAx, mag2db(os_pku(i,:)))
    hold on
%     xline(lines)
    xline([beat_index index_end])
    hold off
    drawnow;

    % Linear scale

%     tiledlayout(2,1)
%     nexttile
%     plot(f_pos, (FFT_D(i,:)))
%     title("DOWN chirp flipped negative half average nulling")
% %     axis(ax_dims)
%     hold on
%     plot(f_pos, (os_thd(:,i)))
%     hold on
%     stem(f_pos, (os_pkd(i,:)))
%     hold on
%     xline([beat_index index_end])
% %     xline(lines)
%     hold off
% 
%     nexttile
%     plot(f_pos, (FFT_U(i,:)))
%     title("UP chirp positive half average nulling")
% %     axis(ax_dims)
%     hold on
%     plot(f_pos, (os_thu(:,i)))
%     hold on
%     stem(f_pos, (os_pku(i,:)))
%     hold on
% %     xline(lines)
%     xline([beat_index index_end])
%     hold off
%     drawnow;



%   pause(0.5)
   % If nothing detected
   % Issue - if another target detected, will not trigger
   % Issue - if no new target, will hold closest last target
   % Maintaining that turn is unsafe
%     if (~any(rg_array(i,:)) && i>1)
%        fd_array(i,:) = fd_array(i-1,:);
%        sp_array(i,:) = sp_array(i-1,:);
%        rg_array(i,:) = rg_array(i-1,:);
% %        for bin = 1:(nbins-1)
% %              % if nothing detected but target was present in previous sweep
% %         % will propagate/hold until new detection
% %         % Compares outer bin to inner bin!
% %         % Start from second sweep
% %         if (rg_array(i-1,bin))
% % 
% %             fd_array(i,bin) = fd_array(i-1,bin);
% %             sp_array(i,bin) = sp_array(i-1,bin);
% %             rg_array(i,bin) = rg_array(i-1,bin);
% %         end
% % %        elseif (hold_pos)
% % %             fd_array(i,bin) = fd_array(i-1,bin);
% % %             sp_array(i,bin) = sp_array(i-1,bin);
% % %             rg_array(i,bin) = rg_array(i-1,bin);
% % %             hold_pos = false;
% % %        end
% %        end
%    end
end
%%
i = 64;
f_pos = f_pos/1000;
close all
figure
tiledlayout(2,1)
nexttile
plot(f_pos, absmagdb(FFT_D(i,:)))
title("DOWN chirp flipped negative half average nulling")
%     axis(ax_dims)
hold on
plot(f_pos, absmagdb(os_thd(:,i)))
hold on
stem(f_pos, absmagdb(os_pkd(i,:)))
hold on
xline([beat_index index_end])
%     xline(lines)
hold off

nexttile
plot(f_pos, absmagdb(FFT_U(i,:)))
title("UP chirp positive half average nulling")
%     axis(ax_dims)
hold on
plot(f_pos, absmagdb(os_thu(:,i)))
hold on
stem(f_pos, absmagdb(os_pku(i,:)))
hold on
%     xline(lines)
xline([beat_index index_end])
hold off
drawnow;
