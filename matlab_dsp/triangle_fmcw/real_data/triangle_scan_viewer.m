% Import data and parameters
subset = 700:1100;
addpath('../../../matlab_lib/');
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);
% Import video
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/videos/');
%%
% Taylor Window
nbar = 3;
sll = -100;
twin = taylorwin(n_samples, nbar, sll);
iq_u = iq_u.*twin.';
iq_d = iq_d.*twin.';

% FFT
n_fft = 512;
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

IQ_UP = fft(iq_u,n_fft,2);
IQ_DN = fft(iq_d,n_fft,2);

% Halve FFTs
IQ_UP = IQ_UP(:, 1:n_fft/2);
IQ_DN = IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
IQ_UP(:, 1:num_nul) = 0;
IQ_DN(:, end-num_nul+1:end) = 0;

% IQ_UP = IQ_UP - mean(IQ_UP);
% IQ_DN = IQ_DN - mean(IQ_DN);
% CFAR
guard = 2*n_fft/n_samples;
guard = floor(guard/2)*2; % make even
% too many training cells results in too many detections
train = round(20*n_fft/n_samples);
train = floor(train/2)*2;
train = 64;
guard = 6;
% false alarm rate - sets sensitivity
F = 18e-4; 
OS = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',train);

% flip
IQ_DN = flip(IQ_DN,2);

% Filter peaks/ peak detection
[up_os, os_thu] = OS(abs(IQ_UP)', 1:n_fft/2);
[dn_os, os_thd] = OS(abs(IQ_DN)', 1:n_fft/2);

% Find peak magnitude
os_pku = abs(IQ_UP).*up_os';
os_pkd = abs(IQ_DN).*dn_os';

% Define frequency axis
fs = 200e3;
f = f_ax(n_fft, fs);
f_neg = f(1:n_fft/2);
f_pos = f((n_fft/2 + 1):end);

v_max = 60/3.6; 
fd_max = speed2dop(v_max, lambda)*2;
% Minimum sample number for 1024 point FFT corresponding to min range = 10m
% n_min = 83;
% for 512 point FFT:
n_min = 42;
% Divide into range bins of width 64
nbins = 16;
bin_width = (n_fft/2)/nbins;
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

f_bin_edges_idx = size(f_pos(),2)/nbins;
%%
index_end = 0;
beat_index = 0;
close all
fig1 = figure('WindowState','maximized');
for i = 1:n_sweeps
   for bin = 0:(nbins-1)
        % find beat in bin
        bin_slice_d = os_pkd(i,bin*bin_width+1:(bin+1)*bin_width);
        [magd, idx_d] = max(bin_slice_d);

        if magd ~= 0
            beat_index = bin*bin_width + idx_d;
            fbd(i,bin+1) = f_pos(beat_index);
            % set up bin slice to range of expected beats
            % See freqs from 0 to index 8
            
            index_end = beat_index - 15;
            bin_slice_u = os_pku(i,beat_index:beat_index - 15);
            [magu, idx_u] = max(bin_slice_u);
            if magu ~= 0
                fbu(i,bin+1) = f_pos(bin*bin_width + idx_u);
            end
            
            % if both not DC
            if and(fbu(i,bin+1) ~= 0, fbd(i,bin+1)~= 0)
                fd = -fbu(i,bin+1) + fbd(i,bin+1);
                fd_array(i,bin+1) = fd/2;
                
                % if less than max expected and filter clutter doppler
                if ((abs(fd/2) < fd_max) && (fd/2 > 400))
                    sp_array(i,bin+1) = dop2speed(fd/2,lambda)/2;
                    rg_array(i,bin+1) = beat2range( ...
                        [fbu(i,bin+1) -fbd(i,bin+1)], k, c);
                end
           
            end
            % for plot
            osu_pk_clean(i, bin*bin_width + idx_u) = magu;
            osd_pk_clean(i, bin*bin_width + idx_d) = magd;
        end
   end
    tiledlayout(2,1)
    nexttile
    plot(absmagdb(IQ_DN(i,:)))
    title("DOWN chirp flipped negative half average nulling")
%     axis(ax_dims)
    hold on
    plot(absmagdb(os_thd(:,i)))
    hold on
    stem(absmagdb(os_pkd(i,:)))
    hold on
    xline([beat_index index_end])
%     xline(lines)
    hold off

    nexttile
    plot(absmagdb(IQ_UP(i,:)))
    title("UP chirp positive half average nulling")
%     axis(ax_dims)
    hold on
    plot(absmagdb(os_thu(:,i)))
    hold on
    stem(absmagdb(os_pku(i,:)))
    hold on
%     xline(lines)
    xline([beat_index index_end])
    hold off
    drawnow;
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
plot(f_pos, absmagdb(IQ_DN(i,:)))
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
plot(f_pos, absmagdb(IQ_UP(i,:)))
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
