% Increase SNR for moving targets by subtracting the ensemble mean of two
% pulses
addpath('../../../matlab_lib/');
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
subset = 850:1100;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);


win = hamming(n_samples);
% win = blackman(n_samples);
% win = nuttallwin(n_samples);

iq_u = iq_u.*win.';
iq_d = iq_d.*win.';

% FFT
n_fft = 512;
IQ_UP = fft(iq_u,n_fft,2);
IQ_DN = fft(iq_d,n_fft,2);

% Halve FFTs
IQ_UP = IQ_UP(:, 1:n_fft/2);
IQ_DN = IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);
IQ_UP(:, 1:num_nul) = 0;
IQ_DN(:, end-num_nul+1:end) = 0;


% Best method is to keep previous sweep in memory then get the mean of the
% that one and the next
n_mean = 1;
for row = 1:(n_sweeps-n_mean)
    mean_up = mean(IQ_UP(row:row+n_mean, :), 1);
    mean_dn = mean(IQ_DN(row:row+n_mean, :), 1);

    IQ_UP(row,:) = IQ_UP(row,:) - mean_up;
    IQ_DN(row,:) = IQ_DN(row,:) - mean_dn;

%     IQ_UP(row+1,:) = IQ_UP(row+1,:) - two_sweep_mean;
end


% n_mean = 2;
% for row = 1:n_mean:(n_sweeps-n_mean)
%     mean_up = mean(IQ_UP(row:row+n_mean, :), 1);
%     mean_dn = mean(IQ_DN(row:row+n_mean, :), 1);
% 
%     IQ_UP(row,:) = IQ_UP(row,:) - mean_up;
%     IQ_DN(row,:) = IQ_DN(row,:) - mean_dn;
%     
%     IQ_UP(row+1,:) = IQ_UP(row+1,:) - mean_up;
%     IQ_DN(row+1,:) = IQ_DN(row+1,:) - mean_dn;
% end



guard = 2*n_fft/n_samples;
guard = floor(guard/2)*2; % make even
% too many training cells results in too many detections
train = round(20*n_fft/n_samples);
train = floor(train/2)*2;
train = 2*64;
guard = 6;
% false alarm rate - sets sensitivity
F = 0.1e-3; 
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
sp_array_corr = zeros(n_sweeps,nbins);
beat_arr = zeros(n_sweeps,nbins);

osu_pk_clean = zeros(n_sweeps,n_fft/2);
osd_pk_clean = zeros(n_sweeps,n_fft/2);

% Make slightly larger to allow for holding previous
% >16 will always be 0 and not influence results
% previous_det = zeros(nbins+2, 1);
scan_width = 15;
% f_bin_edges_idx = size(f_pos(),2)/nbins;

index_end = 0;
beat_index = 0;
% close all
% fig1 = figure('WindowState','maximized');
calib = 1.2463;
calib = 1;
road_width = 2;
correction_factor = 2;
for i = 1:n_sweeps

   for bin = 0:(nbins-1)
        
        % find beat frequency in bin of down chirp
        bin_slice_d = os_pkd(i,bin*bin_width+1:(bin+1)*bin_width);
        
        % extract peak of beat frequency
        [magd, idx_d] = max(bin_slice_d);
        
        % if there is a non-zero maximum
        if magd ~= 0
            
            % index of beat frequency is the index in the bin plus
            % the index of the start of the bin
            beat_index = bin*bin_width + idx_d;

            % store beat frequency
            fbd(i,bin+1) = f_pos(beat_index);
           
            % if the beat index is further than one bin from the start
           if (beat_index>bin_width)
               
               % set beat scan window width
               index_end = beat_index - scan_width;

               % get up chirp spectrum window
               bin_slice_u = os_pku(i,index_end:beat_index);
            
           % if not, start from DC
           else
                index_end = 1;
                bin_slice_u = os_pku(i,1:beat_index);
            end
            
            [magu, idx_u] = max(bin_slice_u);
            
            if magu ~= 0
                
                % store up chirp beat frequency
                % NB - the bin index is not necessarily where the beat was
                % found!
                % ISSUE FIXED: index starts from index_end not bin*
                % bin_width
                fbu(i,bin+1) = f_pos(index_end + idx_u);
            end
            
            % if both not DC
            if and(fbu(i,bin+1) ~= 0, fbd(i,bin+1)~= 0)
                % Doppler shift is twice the difference in beat frequency
%               calibrate beats for doppler shift
                fd = (-fbu(i,bin+1) + fbd(i,bin+1))*calib;
                fd_array(i,bin+1) = fd/2;
                
                
                % if less than max expected and filter clutter doppler
                % removed the max condition as this is controlled by bin
                % width (abs(fd/2) < fd_max) &&
                if ( fd/2 > 400)
                    sp_array(i,bin+1) = dop2speed(fd/2,lambda)/2;
                    
                    rg_array(i,bin+1) = calib*beat2range( ...
                        [fbu(i,bin+1) -fbd(i,bin+1)], k, c);

                    % Theta in radians
                    theta = asin(road_width/rg_array(i,bin+1))*...
                        correction_factor;

%                     real_v = dop2speed(fd/2,lambda)/(2*cos(theta));
                    real_v = fd*lambda/(4*cos(theta));
                    sp_array_corr(i,bin+1) = round(real_v,2);
                end
           
            end
            % for plot
            osu_pk_clean(i, bin*bin_width + idx_u) = magu;
            osd_pk_clean(i, bin*bin_width + idx_d) = magd;
        end
   end
   % ===================================================
   % LIVE PLOT OF TARGET, THRESHOLD, AND DETECTIONS
   % ===================================================
%     tiledlayout(2,1)
%     nexttile
%     plot(absmagdb(IQ_DN(i,:)))
%     title("DOWN chirp flipped negative half average nulling")
% %     axis(ax_dims)
%     hold on
%     plot(absmagdb(os_thd(:,i)))
%     hold on
%     stem(absmagdb(os_pkd(i,:)))
%     hold on
%     xline([beat_index index_end])
% %     xline(lines)
%     hold off
% 
%     nexttile
%     plot(absmagdb(IQ_UP(i,:)))
%     title("UP chirp positive half average nulling")
% %     axis(ax_dims)
%     hold on
%     plot(absmagdb(os_thu(:,i)))
%     hold on
%     stem(absmagdb(os_pku(i,:)))
%     hold on
% %     xline(lines)
%     xline([beat_index index_end])
%     hold off
%     drawnow;
%   pause(0.5)
% ======================================================================


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


sp_array_kmh = sp_array*3.6;
sp_array_kmh_corr = sp_array_corr*3.6;
close all
figure
tiledlayout(3, 1)
nexttile
plot(rg_array)
title("Calibrated range estimations")
nexttile
plot(sp_array_kmh)
title("Calibrated speed estimations")
yline(60,'Label','Expected 60 km/h')
nexttile
plot(sp_array_kmh_corr)
title("Calibrated speed estimations with angle correction")
yline(60,'Label','Expected 60 km/h')




%% SPECTRUM PLOTTING ONLY
% dat1 = absmagdb(IQ_DN);
% dat2 = absmagdb(IQ_UP);
% % ax_dims = [0 round(n_interp/2) 60 160];
% ax_dims = [0 round(n_fft/2) 60 160];
% sweep = 1;
% close all
% fig1 = figure('WindowState','maximized');
% movegui(fig1,'east')
% tiledlayout(2,1)
% nexttile
% p1 = plot(dat1(sweep,:));
% title("UP chirp positive half")
% axis(ax_dims)
% nexttile
% p2 = plot(dat2(sweep,:));
% title("DOWN chirp flipped negative half")
% axis(ax_dims)
% 
% for i = 1:n_sweeps
%     set(p1, 'YData',dat1(i,:))
%     set(p2, 'YData',dat2(i,:))
%     drawnow;
% end

