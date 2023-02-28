addpath('../../matlab_lib/');
%% Import radar model
uRAD_model;
%% Select Scenario
monoRadarScenario1;
% monoRadarScenario2;
% monoRadarScenario3;
% monoRadarScenario4;
%% Configure processing
proc_config;
%% Configure simulation plots
sim_plot_config;
%%



i = 0;
for t = 1:(n_steps)
%     pause(1)
    i = t;
    %disp(t)
%     sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
    [tgt_pos, tgt_vel] = carmotion(t_step);
%     disp(tgt_pos)
    actual_range(i) = sqrt(tgt_pos(1, 2)^2 + tgt_pos(2,2)^2);
    time(i) = t*t_step
%     actual_x = 

%     % issue: helper updates target position and velocity within each
%     sweep. Resolved --> issue was releasing waveforms?

%     xr = simulate_sweeps2(Nsweep,waveform,radarmotion,carmotion,...
%         transmitter,channel,cartarget,receiver);

    % Output at sampling rate (decimation)
    xru = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
        transmitter, channel, cartarget, receiver, Dn, Ns, 0);

    xrd = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
        transmitter, channel, cartarget, receiver, Dn, Ns, tm);
    
    % Window
    xru = xru.*win;
    xrd = xrd.*win;

    XRU = fft(xru, nfft).';
    XRD = fft(xrd, nfft).';

    IQ_UP = XRU(:, 1:n_fft/2);
    IQ_DN = XRD(:, n_fft/2+1:end);
    
    IQ_UP(:, 1:num_nul1) = repmat(IQ_UP(:, num_nul1+1), [1, num_nul1]);
    IQ_DN(:, end-num_nul1+1:end) = ...
    repmat(IQ_DN(:, end-num_nul1), [1, num_nul1]);
    
    IQ_DN = flip(IQ_DN,2);

    [up_os1, upTh1] = OS1(abs(IQ_UP)', 1:n_fft/2);
    [dn_os1, dnTh1] = OS1(abs(IQ_DN)', 1:n_fft/2);

    upDets1 = abs(IQ_UP).*up_os1';
    dnDets1 = abs(IQ_DN).*dn_os1';
    
    % calib set to 1 since no calibration needed for simulated radar
    [rgMtx1(i,:), spMtx1(i,:), spMtxCorr1(i,:), pkuClean1, ...
    pkdClean1, fbu1(i,:), fbd1(i,:), fdMtx1(i,:), fb_idx1, fb_idx_end1, ...
    beat_count_out1] = proc_sweep_multi_scan(bin_width, ...
    lambda, k, c, dnDets1, upDets1, nbins, n_fft, ...
    freqkHz, scan_width, 1, lhs_road_width, beat_count_in1);
%     disp(rgMtx1(i,:))
    ratio = rgMtx1(i,:)./spMtx1(i,:);
    if (any(ratio<t_safe))
        % 1 indicates sweep contained target at unsafe distance
        % UPDATE: put the ratio/time into array to scale how
        % safe the turn is
        safety(i) = min(ratio);
        % for colour map:
%         safe_sweeps(sweep) = t_safe-min(ratio);
    end

    fb_idx1 = rng_ax(fb_idx1);
    fb_idx_end1 = rng_ax(fb_idx_end1);
    set(win1,'XData',cat(1,fb_idx1, fb_idx_end1))
    set(win2,'XData',cat(1,fb_idx1, fb_idx_end1))

    set(p1, 'YData', absmagdb(IQ_UP))
    set(p2, 'YData', absmagdb(IQ_DN))

%     set(p1, 'YData', pkuClean1)
%     set(p2, 'YData', pkdClean2)

    set(p1th, 'YData', absmagdb(upTh1))
    set(p2th, 'YData', absmagdb(dnTh1))
%     set(p1th, 'YData', abs(xrd))

%     set(p3, 'CData', rgMtx1)
    set(p3, 'YData', safety)
    % Plot speed with angle correction
    set(p4, 'CData', abs(spMtxCorr1)*3.6)

    % Plot speed without angle correction
%     set(p4, 'CData', spMtx1*3.6)
    pause(0.000000001)
%     disp('Running')
end

%% Results



spMtx1Kmh = spMtx1*3.6;
spMtxCorr1Kmh = real(spMtxCorr1*3.6);

% spMtx1Kmh_mean = mean(nonzeros(spMtx1Kmh), 2);
% spMtxCorr1Kmh_mean = mean(nonzeros(spMtxCorr1Kmh), 2);

% rgMtx1_mean = mean(rgMtx1~=0, 2);
% rgMtx1_NAN = rgMtx1;
% rgMtx1_NAN(rgMtx1_NAN == 0) = nan;
% rgMtx1Clean = rmmissing(rgMtx1_NAN, 2)
for i = 1:size(rgMtx1(:,1))
    rgMtx1_mean(i,:) = mean(nonzeros(rgMtx1(i,:)));
    spMtx1Kmh_mean(i,:) = mean(nonzeros(spMtx1Kmh(i,:)));
    spMtxCorr1Kmh_mean(i,:) = mean(nonzeros(spMtxCorr1Kmh(i,:)));
end
% spMtx1Kmh_mean = mean(removeMatZeros(spMtx1Kmh), 2, 'omitnan');
% spMtxCorr1Kmh_mean = mean(removeMatZeros(spMtxCorr1Kmh), 2, 'omitnan');
% 
% rgMtx1_mean = mean(removeMatZeros(rgMtx1'), 2, 'omitnan');
% 
% function B = removeMatZeros(A)
%     B = [];
%     for i = 1: size(A, 1)
%         r = A(i,:);
%         r(r==0) = []; % remove zeros
%           % handle expansion
%           ncolR = size(r, 2);
%           ncolB = size(B, 2);
%           diffcol = ncolR - ncolB;
%           if (diffcol > 0) % previous rows need more cols
%               for j = ncolB+1:ncolR
%                   B(:,j) = NaN;
%               end
%           elseif (diffcol < 0) % this row needs more cols
%               r = [r, NaN(1, abs(diffcol))];
%           end
%           B(i,:) = r;
%      end
% end
