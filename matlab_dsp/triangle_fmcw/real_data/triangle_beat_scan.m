% Import data and parameters
% 60kmh subset
% subset = 900:1200;
% 50 kmh subset - same
% 40 kmh subset

subset = 1:4000;
addpath('../../../matlab_lib/');
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);
% Import video
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/videos/');
%%
% Taylor Window
nbar = 4;
sll = -50;
twinu = taylorwin(n_samples, nbar, sll);
twind = taylorwin(n_samples, nbar, sll);
iq_u = iq_u.*twinu.';
iq_d = iq_d.*twind.';

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
for i = 1:n_sweeps
   for bin = 0:(nbins-1)
        % find beat in bin
        bin_slice_d = os_pkd(i,bin*bin_width+1:(bin+1)*bin_width);
        [magd, idx_d] = max(bin_slice_d);
        
        beat_index = bin*bin_width + idx_d;
        if (magd ~= 0 && beat_index>15)
            fbd(i,bin+1) = f_pos(beat_index);
            % set up bin slice to range of expected beats
            % See freqs from 0 to index 8
            bin_slice_u = os_pku(i,beat_index - 15:beat_index);
            % index is index in the subset
            [magu, idx_u] = max(bin_slice_u);
            if magu ~= 0
                fbu(i,bin+1) = f_pos(beat_index - 15 + idx_u);
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
sp_array_kmh = sp_array.*3.6;
return;
%%
% Define range axis
rng_ax = beat2range(f_pos',k,c);

% labels for range bins
rg_bin_lbl = strings(1,nbins);
rax = linspace(0,62,32);
for bin = 0:(nbins-1)
    first = round(rng_ax(bin*bin_width+1));
    last = round(rng_ax((bin+1)*bin_width));
    rg_bin_lbl(bin+1) = strcat(num2str(first), " to ", num2str(last));
end
%% *** Turn safety algorithm ***
% takes 3 seconds to turn. target must be 3 sec away.
t_safe = 3;
safe_sweeps = zeros(n_sweeps,1);
safety = zeros(n_sweeps,1);
for sweep = 1:n_sweeps
    ratio = rg_array(sweep,:)./sp_array(sweep,:);
    if (any(ratio<t_safe))
        % 1 indicates sweep contained target at unsafe distance
        % UPDATE: put the ratio/time into array to scale how
        % safe the turn is
        safety(sweep) = min(ratio);
        % for colour map:
        safe_sweeps(sweep) = t_safe-min(ratio);
    end
end
% close all
% figure
% plot(safety)
% 
% return;

%%
close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'west')
sweep_window = 200;
loop_cnt = 0;
% Need here to restart video
% vidObj = VideoReader('20kmhx.mp4');
% vidObj = VideoReader('30kmhx.mp4');
% vidObj = VideoReader('40kmhxq.mp4');
% vidObj = VideoReader('50kmhx.mp4');
vidObj = VideoReader('60kmhx.mp4');
% Loop for fast sampled data
tic;
for sweep = 1:15:(n_sweeps-sweep_window)
    loop_cnt = loop_cnt +1;
    tiledlayout(1,3)
    nexttile
    imagesc(sp_array(sweep:sweep+sweep_window,:).*3.6)
    set(gca, 'XTick', 1:1:nbins, 'XTickLabel', rg_bin_lbl, 'CLim', [0 60])
    grid
    title("Speed v. Time v. Range")
    xlabel("Range bin (meters)")
    ylabel("Sweep number in window (represents time)")
    a = colorbar;
    a.Label.String = 'Radial velocity (km/h)';
    nexttile
    imagesc(safe_sweeps(sweep:sweep+sweep_window))
    title("Safety Meter")
    ylabel("Sweep number in window  (represents time)")
    b = colorbar;
    b.Label.String = 'Degree of safety (4 - t_{arrival})';
    set(gca,'CLim', [0 1])
    nexttile
%   take every 6th frame based on num vid frames and num radar frames
    for w = 1:6
        vidFrame = readFrame(vidObj);
    end
    imshow(vidFrame)
    drawnow;
% pause(0.5)
end
toc
% times 2 for triangle modulation

% Loop for slow sampling - just get new data smh
expected_time = length(subset)*tm*2
%%
% close all
% figure
% imagesc(sp_array.*3.6)
% set(gca, 'XTick', 1:1:nbins, 'XTickLabel', rg_bin_lbl)
% grid
% title("M4 data near Rustenberg Junior: Set 2")
% xlabel("Range bin (meters)")
% ylabel("Sweep number/time")
% a = colorbar;
% a.Label.String = 'Radial velocity (km/h)';
