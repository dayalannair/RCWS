addpath('../../matlab_lib/');
%% Import radar model
uRAD_model;
%% Select Scenario
monoRadarScenario1;
% monoRadarScenario2;
% monoRadarScenario3;
%% Configure processing
t_total = 3;
t_step = 0.05;
Nsweep = 1; % Number of ups and downs, not number of periods
n_steps = t_total/t_step;

proc_config;
%% Configure simulation plots
sim_plot_config;
%%

fbu1   = zeros(nswp1, nbins);
fbd1   = zeros(nswp1, nbins);
fdMtx1 = zeros(nswp1, nbins);
rgMtx1 = zeros(nswp1, nbins);
spMtx1 = zeros(nswp1, nbins);
safety = zeros(nswp1, 1);
t_safe = 3.5;
spMtxCorr1 = zeros(nswp1, nbins);

i = 0;
for t = 1:n_steps
    i = t;
    %disp(t)
    sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
    [tgt_pos,tgt_vel] = carmotion(t_step);

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
    
    
    [rgMtx1(i,:), spMtx1(i,:), spMtxCorr1(i,:), pkuClean1, ...
    pkdClean1, fbu1(i,:), fbd1(i,:), fdMtx1(i,:), fb_idx1, fb_idx_end1, ...
    beat_count_out1] = proc_sweep_multi_scan(bin_width, ...
    lambda, k, c, dnDets1, upDets1, nbins, n_fft, ...
    f_pos, scan_width, calib, lhs_road_width, beat_count_in1);
    
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
    set(p4, 'CData', spMtx1)
    pause(0.000000001)
%     disp('Running')
end

%% Results

spMtx1Kmh = spMtx1*3.6;
spMtxCorr1Kmh = spMtxCorr1*3.6;


