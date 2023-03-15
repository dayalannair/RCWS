
addpath('../../matlab_lib/')
uRAD_transcv_model;
%% Plot antenna
% close all
% cosinePattern = figure;
% pattern(cosineElement,fc)
% cosineArrayPattern = figure;
% pattern(fmcwCosineArray,fc);

mono_radar_transcv_scenario0;

%% Simulation Loop
close all

t_total = 6;
t_step = 0.1;
Nsweep = 1; % Number of ups and downs, not number of periods
n_steps = t_total/t_step;
% Generate visuals
sceneview = phased.ScenarioViewer('BeamRange',62.5,...
    'BeamWidth',[30; 30], ...
    'ShowBeam', 'All', ...
    'CameraPerspective', 'Custom', ...
    'CameraPosition', [2101.04 -1094.5 644.77], ...
    'CameraOrientation', [-152 -15.48 0]', ...
    'CameraViewAngle', 1.45, ...
    'ShowName',true,...
    'ShowPosition', true,...
    'ShowSpeed', true,...
    'ShowRadialSpeed',false,...
    'UpdateRate',1/t_step);%, ...
%     'Position',[1000 100 1000 900]);


% Set up arrays for two targets
fbu = zeros(n_steps, 2);
fbd = zeros(n_steps, 2);
r = zeros(n_steps, 2);
v = zeros(n_steps, 2);

Dn = fix(fs_wav/fs_adc);
nfft = 512;
faxis_kHz = f_ax(nfft, fs_adc)/1000;
n_fft = 512;
nbar = 3;
sll = -80;


nbins = 16;
bin_width = 16; % account for scan width = 21
scan_width = 8;

calib = 1.2463;
lhs_road_width = 2;
rhs_road_width = 4;

% Taylor window
twin = taylorwin(Ns, nbar, sll);

fs = 200e3;
f = f_ax(n_fft, fs);
f_neg = f(1:n_fft/2);
f_pos = f((n_fft/2 + 1):end);

% Range axis
rng_ax = beat2range((f_pos)', k, c);

%%
close all
f1 = figure('WindowState','normal', 'Position',[0 100 1000 900]);
movegui(f1, "west")

f_bin_edges_idx = size(f_pos(),2)/nbins;
prev_det = 0;

fb_idx1 = zeros(nbins,1);
fb_idx2 = zeros(nbins,1);
fb_idx_end1 = zeros(nbins,1);
fb_idx_end2 = zeros(nbins,1);
ax_dims = [0 max(rng_ax) -120 100];
ax_ticks = 1:2:60;
nswp1  = n_steps;
fbu1   = zeros(nswp1, nbins);
fbd1   = zeros(nswp1, nbins);
fdMtx1 = zeros(nswp1, nbins);
rgMtx1 = zeros(nswp1, nbins);
spMtx1 = zeros(nswp1, nbins);
spMtxCorr1 = zeros(nswp1, nbins);

beat_count_out1 = zeros(1,256);
beat_count_out2 = zeros(1,256);
beat_count_in1 = zeros(1,256);
beat_count_in2 = zeros(1,256);

% IQ_UP = zeros(nswp1, 512);
% IQ_DN = zeros(nswp1, 512);
% upTh1 = zeros(nswp1, 512);
% dnTh1 = zeros(nswp1, 512);

IQ_UP = zeros(1, 512);
IQ_DN = zeros(1, 512);
upTh1 = zeros(512, 1);
dnTh1 = zeros(512, 1);

nul_width_factor = 0.04;
num_nul1 = round((n_fft/2)*nul_width_factor);

nexttile
p1 = plot(rng_ax, absmagdb(IQ_UP(1:256)));
title("LHS UP chirp positive half")
axis(ax_dims)

nexttile
p2 = plot(rng_ax, absmagdb(IQ_DN(1:256)));
title("LHS DOWN chirp flipped negative half")
axis(ax_dims)
simTime = 0;
i = 0;
tgt2 = 0;
rdr_pos = [0;0;0];
rdr_vel = [0;0;0];
for t = 1:n_steps
    % Update car RCS for new position
%     car_rcs_signat = rcsSignature("Pattern",[car1_rcs, car1_rcs; ]);
    i = i + 1;
    % Step targets forward in time
    [tgt_pos,tgt_vel] = carmotion(t_step);

    % Update the position and velocity
    tgt1 = struct('Position', tgt_pos(:,1).', 'Velocity', ...
        tgt_vel(:,1).', 'Signature', car1_rcs_signat);
    
    simTime = simTime + t_step;


    xru = sim_transceiver(transceiver, Dn, simTime, tgt1, tgt2);

    simTime = simTime + 1e-3;
    xrd = sim_transceiver(transceiver, Dn, simTime, tgt1, tgt2);

    xru_twin = xru.*twin;
    xrd_twin = xrd.*twin;
    
    % 512-point FFT
    XRU_twin = fft(xru_twin.', nfft);
    XRD_twin = fft(xrd_twin.', nfft);
    
    % Halve spectra
    IQ_UP = XRU_twin(:, 1:n_fft/2);
    IQ_DN = XRD_twin(:, n_fft/2+1:end);
    
    IQ_DN = flip(IQ_DN,2);
    
    % Update plots
    set(p1, 'YData', absmagdb(IQ_UP))
    set(p2, 'YData', absmagdb(IQ_DN))

    % Update 3D scene viewer
    sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
    pause(0.00001)
end

%% Km/h

spMtx1kmh = spMtx1*3.6;
spMtx1Corrkmh = spMtxCorr1*3.6;
%     % issue: helper updates target position and velocity within each
%     sweep. Resolved --> issue was releasing waveforms?

%     xr = simulate_sweeps2(Nsweep,waveform,radarmotion,carmotion,...
%         transmitter,channel,cartarget,transceiver);

