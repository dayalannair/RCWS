% Import data and parameters
subset = 1:4096;%200:205;
addpath('../../library/');
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);

% Taylor Window
nbar = 4;
sll = -38;
twinu = taylorwin(n_samples, nbar, sll);
twind = taylorwin(n_samples, nbar, sll);
iq_u = iq_u.*twinu.';
iq_d = iq_d.*twind.';

% FFT
n_fft = 512;%512;
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

% CFAR
guard = 2*n_fft/n_samples;
guard = floor(guard/2)*2; % make even
% too many training cells results in too many detections
train = round(20*n_fft/n_samples);
train = floor(train/2)*2;
% false alarm rate - sets sensitivity
F = 15e-3; 

OS = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',train);

% Filter peaks/ peak detection
[up_os, os_thu] = OS(abs(IQ_UP)', 1:n_fft/2);
[dn_os, os_thd] = OS(abs(IQ_DN)', 1:n_fft/2);

% Find peak magnitude/SNR
os_pku = abs(IQ_UP).*up_os';
os_pkd = abs(IQ_DN).*dn_os';

% Define frequency axis
fs = 200e3;
f = f_ax(n_fft, fs);
f_neg = f(1:n_fft/2);
f_pos = f((n_fft/2 + 1):end);

% Define range axis
rng_ax = beat2range(f_pos',k,c);

% v_max = 60km/h , fd max = 2.7kHz approx 3kHz
v_max = 60/3.6; 
%fd_max = speed2dop(v_max, lambda)*2;
fd_max = 3e3;
Ntgt = 4;

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
% magsu = zeros(n_sweeps,nbins);
% magsd = zeros(n_sweeps,nbins);
% 
% magsu = zeros(n_sweeps,nbins);
% magsd = zeros(n_sweeps,nbins);
osu_pk_clean = zeros(n_sweeps,n_fft/2);
osd_pk_clean = zeros(n_sweeps,n_fft/2);


%%
% close all
% figure
for i = 1:n_sweeps
   for bin = 0:(nbins-1)
        % Only want one target per bin
        bin_slice_u = os_pku(i,bin*bin_width+1:(bin+1)*bin_width);
        bin_slice_d = os_pkd(i,bin*bin_width+1:(bin+1)*bin_width);
        % Note: max will return index of first 0 if array of zeros
        % for now, check if mag is zero then skip
        [magu, idx_u] = max(bin_slice_u);
        [magd, idx_d] = max(bin_slice_d);
        % need to see what happens if a peak not found
        if magu ~= 0
            fbu(i,bin+1) = f_pos(bin*bin_width + idx_u);
        end
        if magd ~= 0
            fbd(i,bin+1) = f_neg(bin*bin_width + idx_d);
        end
   end
   fbd = flip(fbd,2);

   for bin = 0:(nbins-1)
        % if both not DC
        if and(fbu(i,bin+1) ~= 0, fbd(i,bin+1)~= 0)
            fd = -fbu(i,bin+1) - fbd(i,bin+1);
            fd_array(i,bin+1) = fd/2;
            
            % if less than max expected and filter clutter doppler
            if ((abs(fd/2) < fd_max) && (fd/2 > 400))
                sp_array(i,bin+1) = dop2speed(fd/2,lambda)/2;
                % negative factored in for down chirp
                rg_array(i,bin+1) = beat2range([fbu(i,bin+1) fbd(i,bin+1)], k, c);
                beat_arr(i,bin+1) = (fbu(i,bin+1) -fbd(i,bin+1))/2;
            end
        end
        % for plot
        osu_pk_clean(i, bin*bin_width + idx_u) = magu;
        osd_pk_clean(i, bin*bin_width + idx_d) = magd;
    end
%     tiledlayout(2,1)
%     nexttile
%     plot(flip(rng_ax(n_min:end)),absmagdb(IQ_DN(i,1:end-n_min+1))')
%     title("Down chirp flipped FFT")
%     xlabel("Range (m)")
%     hold on
% %     stem(flip(rng_ax(n_min:end)),absmagdb(os_pkd(i,1:end-n_min+1))')
% %     hold on
%     plot(flip(rng_ax(n_min:end)),absmagdb(os_thd(1:end-n_min+1,i))')
%     hold on
%     stem(flip(rng_ax(n_min:end)), ...
%         absmagdb(osd_pk_clean(i,1:end-n_min+1))', ...
%         'Marker','diamond')
% %     lbls = compose('%.2f', osd_pk_clean(i,1:end-n_min+1)');
% %     text(osd_pk_clean(i,1:end-n_min+1)', lbls, 'HorizontalAlignment','center', 'VerticalAlignment','top', 'FontSize',8)
%     hold off
%     nexttile
%     plot(rng_ax(n_min:end), absmagdb(IQ_UP(i,n_min:end))')
%     title("Up chirp FFT")
%     xlabel("Range (m)")
%     hold on
% %     stem(rng_ax(n_min:end), absmagdb(os_pku(i,n_min:end))')
% %     hold on
%     plot(rng_ax(n_min:end), absmagdb(os_thu(n_min:end,i))')
%     hold on
%     stem(rng_ax(n_min:end), ...
%         absmagdb(osu_pk_clean(i,n_min:end))', ...
%         'Marker', 'diamond')
%     hold off
%     pause(1)

    
end

%% Previous Hold zero filter
% Similar to tracking. Find out if valid
% for col = 2:size(sp_array,2)
%     for row = 2:size(sp_array,1)
%         if (sp_array(row,col) == 0)
%             sp_array(row,col) = sp_array(row-1,col);
%         end
%         if (rg_array(row,col) == 0)
%             rg_array(row,col) = rg_array(row-1,col);
%         end
%     end
% end
%% 
% lightBLUE = [0.356862745098039,0.811764705882353,0.956862745098039];
% darkBLUE = [0.0196078431372549,0.0745098039215686,0.670588235294118];
%  
% blueGRADIENTflexible = @(i,n_sweeps) lightBLUE + (darkBLUE-lightBLUE)*((i-1)/(n_sweeps-1));

%%
% close all
% figure
% tiledlayout(2,1)
% nexttile
% % for sweep = 1:1000
% % plot(rg_array(sweep,:))%, 'Color',blueGRADIENTflexible(sweep,1000));
% % hold on
% % end
% 
% 
% plot(rg_array);
% % legend("bin 1", ...
% %     "bin 2", ...
% %     "bin 3", ...
% %     "bin 4", ...
% %     "bin 5", ...
% %     "bin 6", ...
% %     "bin 7", ...
% %     "bin 8", ...
% %     "bin 9", ...
% %     "bin 10", ...
% %     "bin 11", ...
% %     "bin 12", ...
% %     "bin 13", ...
% %     "bin 14", ...
% %     "bin 15", ...
% %     "bin 16");
% nexttile
% plot(sp_array.*3.6)

% %% Rebuild ranges
% ranges = zeros(n_sweeps,n_fft/2);
% speeds = zeros(n_sweeps,n_fft/2);
% for bin = 1:(nbins-1)
%     ranges(:,bin*bin_width+1:(bin+1)*bin_width) = repmat(rg_array(:,bin), 1,bin_width);
%     speeds(:,bin*bin_width+1:(bin+1)*bin_width) = repmat(sp_array(:,bin), 1,bin_width);
% end
% 
% 
% %% Plots
% t = linspace(0,n_sweeps*tm, n_sweeps);
% close all
% figure      
% tiledlayout(2,1)
% nexttile
% plot(ranges)
% nexttile
% plot(speeds.*3.6)

%% Image plot
% Sweeps vs bins
rg_bin_lbl = strings(1,nbins);
rax = linspace(0,62,32);
for bin = 0:(nbins-1)
    first = round(rng_ax(bin*bin_width+1));
    last = round(rng_ax((bin+1)*bin_width));
    rg_bin_lbl(bin+1) = strcat(num2str(first), " to ", num2str(last));
end

%%
close all
figure
% tiledlayout(1,2)
% nexttile
% imagesc(rg_array)
% grid
% xlabel("Range bin")
% ylabel("Sweep number/time")
% nexttile
imagesc(sp_array.*3.6)
set(gca, 'XTick', 1:1:nbins, 'XTickLabel', rg_bin_lbl) % 10 ticks 
% set(gca, 'YTick', [0:0.05:1]*512, 'YTickLabel', [0:0.05:1]) % 20 ticks
grid
title("M4 data near Rustenberg Junior: Set 2")
xlabel("Range bin (meters)")
ylabel("Sweep number/time")
a = colorbar;
a.Label.String = 'Radial velocity (km/h)';
