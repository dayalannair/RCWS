% Import data and parameters
subset = 1000:1200;
addpath('../../../matlab_lib/');
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);

%%
% ======================== Tunable parameters =============================
% These determine the system detection performance
% train = 64 and guard = 6 for 512 point fft
% this is 64/512 = 1/8 and 1/64 of the fft len respectively
% Can use
n_fft = 1024;
train = n_fft/8;%64;
guard = n_fft/64;%8;
nbar = 3;
sll = -100;
F = 1e-4;

% =========================================================================


% Taylor Window
twinu = taylorwin(n_samples, nbar, sll);
twind = taylorwin(n_samples, nbar, sll);
iq_u = iq_u.*twinu.';
iq_d = iq_d.*twind.';

% hmwin = hamming(n_samples);
% 
% iq_u = iq_u.*hmwin.';
% iq_d = iq_d.*hmwin.';

% bwin = blackman(n_samples);
% iq_u = iq_u.*bwin.';
% iq_d = iq_d.*bwin.';

% FFT
IQ_UP = fft(iq_u,n_fft,2);
IQ_DN = fft(iq_d,n_fft,2);

% Interpolate FFT
% IQ_UP = interpft(IQ_UP,n_fft,2);
% IQ_DN = interpft(IQ_DN,n_fft,2);

% Halve FFTs
IQ_UP = IQ_UP(:, 1:n_fft/2);
IQ_DN = IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);
IQ_UP(:, 1:num_nul) = 0;
IQ_DN(:, end-num_nul+1:end) = 0;
% Mean nulling
% IQ_UP = IQ_UP - mean(IQ_UP, 2);
% IQ_DN = IQ_DN - mean(IQ_DN, 2);
% CFAR
% guard = 2*n_fft/n_samples;
% guard = floor(guard/2)*2; % make even
% % too many training cells results in too many detections- NOT always!
% train = round(20*n_fft/n_samples);
% train = floor(train/2)*2;
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
lines = linspace(1,256,bin_width);
fbu = zeros(n_sweeps,nbins);
fbd = zeros(n_sweeps,nbins);

rg_array = zeros(n_sweeps,nbins);
fd_array = zeros(n_sweeps,nbins);
sp_array = zeros(n_sweeps,nbins);
beat_arr = zeros(n_sweeps,nbins);

osu_pk_clean = zeros(n_sweeps,n_fft/2);
osd_pk_clean = zeros(n_sweeps,n_fft/2);

%%
for i = 1:n_sweeps
   for bin = 0:(nbins-1)
        bin_slice_u = os_pku(i,bin*bin_width+1:(bin+1)*bin_width);
        bin_slice_d = os_pkd(i,bin*bin_width+1:(bin+1)*bin_width);

        [magu, idx_u] = max(bin_slice_u);
        [magd, idx_d] = max(bin_slice_d);

        if magu ~= 0
            fbu(i,bin+1) = f_pos(bin*bin_width + idx_u);
        end
        if magd ~= 0
            fbd(i,bin+1) = f_pos(bin*bin_width + idx_d);
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

%% Plots

ax_dims = [0 max(f_pos) 60 160];
dat1 = absmagdb(IQ_DN);
dat2 = absmagdb(os_thd);
dat3 = absmagdb(os_pkd);
dat4 = absmagdb(IQ_UP);
dat5 = absmagdb(os_thu);
dat6 = absmagdb(os_pku);

close all
fig1 = figure('WindowState','maximized');
% movegui(fig1, 'east');
tiledlayout(2,1)
%     nexttile
%     plot(absmagdb(IQ_UP(sweep,:)))
%     title("UP chirp positive half slice nulling")
%     axis(ax_dims)
%     nexttile
%     plot(absmagdb(IQ_DN(sweep,:)))
%     title("DOWN chirp flipped negative half slice nulling")
%     axis(ax_dims)

nexttile
p1 = plot(dat1(1,:));
title("Down chirp flipped negative half of spectrum")
xlabel("Frequency (kHz)")
ylabel("Magnitude (dB)")
axis(ax_dims)
hold on
p2 = plot(dat2(:,1));
hold on
p3 = stem(dat3(1,:));
hold on
%     xline(lines)
hold off

nexttile
p4 = plot(dat4(1,:));
title("UP chirp positive half of spectrum")
xlabel("Frequency (kHz)")
ylabel("Magnitude (dB)")
axis(ax_dims)
hold on
p5 = plot(dat5(:,1));
hold on
p6 = stem(dat6(1,:));
hold on
%     xline(lines)
hold off

for i = 1:n_sweeps
    set(p1, 'YData',dat1(i,:))
    set(p2, 'YData',dat2(:,i))
    set(p3, 'YData',dat3(i,:))
    set(p4, 'YData',dat4(i,:))
    set(p5, 'YData',dat5(:,i))
    set(p6, 'YData',dat6(i,:))
    drawnow;
end
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
close all
figure
plot(safety)

return;

%%
close all
fig1 = figure('WindowState','maximized');
movegui(fig1,'west')
sweep_window = 200;
loop_cnt = 0;
% Need here to restart video
vidObj = VideoReader('20kmhx.mp4');
% vidObj = VideoReader('30kmhx.mp4');
% vidObj = VideoReader('40kmhxq.mp4');
% vidObj = VideoReader('50kmhx.mp4');
% vidObj = VideoReader('60kmhx.mp4');
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
