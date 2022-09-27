% ========================================================================
% Simulation Parameters
% ========================================================================
addpath('../../matlab_lib/')
fc = 24.005e9;%77e9;
c = physconst('LightSpeed');
% c = 3e8;
lambda = c/fc;
%range_max = 200;
range_max = 62.5;
%tm = 2e-3;
tm = 1e-3;
% range_res = 0.5;
% bw2 = rangeres2bw(range_res,c);
bw = 240e6;
sweep_slope = bw/tm;

fr_max = range2beat(range_max,sweep_slope,c);
v_max = 230*1000/3600;
fd_max = speed2dop(2*v_max,lambda);
fb_max = fr_max+fd_max;
fs_wav = max(2*fb_max,2*bw);
fs = 200e3; % adc sampling rate
%fs = 200e3; % kills range est
rng(2012);
wave = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs_wav, 'SweepDirection','Triangle');
% close all
% figure
sig = wave();
% subplot(211); 
% plot(0:1/fs_wav:tm-1/fs_wav,real(sig));
% xlabel('Time (s)'); ylabel('Amplitude (v)');
% title('FMCW signal'); axis tight;
% f_wav = f_ax(2*bw/1000, fs_wav);
% SIG = fft(sig);
% subplot(212); 
% plot(f_wav, sftmagdb(SIG))
% subplot(212); spectrogram(sig,32,16,32,fs,'yaxis');
% title('FMCW signal spectrogram');
%%
ant_aperture = 6.06e-4;                         % in square meter
ant_gain = aperture2gain(ant_aperture,lambda);  % in dB

tx_ppower = db2pow(5)*1e-3;                     % in watts
tx_gain = 9+ant_gain;                           % in dB

rx_gain = 30+ant_gain;                          % in dB
rx_nf = 4.5;                                    % in dB

txer = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs);

% ========================================================================
% Scenario
% ========================================================================
% Target parameters
car1_x_dist = 70;
car1_y_dist = 2; % RHS Lane
car1_speed = 60/3.6;
car2_x_dist = -50;
car2_y_dist = 4; % LHS Lane
car2_speed = -40/3.6;
car3_x_dist = 30;
car3_y_dist = 2; % LHS Lane
car3_speed = 30/3.6;

car1_dist = sqrt(car1_x_dist^2 + car1_y_dist^2);
car2_dist = sqrt(car2_x_dist^2 + car2_y_dist^2);
car3_dist = sqrt(car3_x_dist^2 + car3_y_dist^2);

car1_rcs = db2pow(min(10*log10(car1_dist)+5,20));
car2_rcs = db2pow(min(10*log10(car2_dist)+5,20));
car3_rcs = db2pow(min(10*log10(car3_dist)+5,20));



% Define reflected signal
rhs_cartarg = phased.RadarTarget('MeanRCS',[car2_rcs car3_rcs], ...
    'PropagationSpeed',c,...
    'OperatingFrequency',fc);

lhs_cartarg = phased.RadarTarget('MeanRCS',car1_rcs, ...
    'PropagationSpeed',c,...
    'OperatingFrequency',fc);

% Define target motion - 2 targets
rhs_carmo = phased.Platform('InitialPosition', ...
    [car2_x_dist car3_x_dist; ...
    car2_y_dist car3_y_dist; ...
    0.5 0.5],...
    'Velocity',[-car2_speed -car3_speed; ...
                0 0; ...
                0 0]);

lhs_carmo = phased.Platform('InitialPosition', ...
    [car1_x_dist; ...
    car1_y_dist; ...
    0.5],...
    'Velocity',[-car1_speed; ...
                0; ...
                0]);

% Define propagation medium
chann = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc, ...
    'SampleRate',fs, ...
    'TwoWayPropagation',true);

% Define radar motion
rdr_orientation = [1 0 0;0 1 0;0 0 1];
rdr_orientation(:,:,2) = [-1 0 0;0 1 0;0 0 1];

% radar_pos = [0 0;0 0;0.5 0.5];
% radar_vel = [0 0;0 0;0 0];
% 
% rad_pos1 = [0; 0; 0.5];
% rad_vel1 = [0; 0; 0];
% 
% radmo = phased.Platform('InitialPosition', ...
%     radar_pos,...
%     'Velocity',radar_vel, ...
%     'InitialOrientationAxes',rdr_orientation);

lhs_radmo = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[0;0;0]);

rhs_radmo = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[0;0;0], 'InitialOrientationAxes', [-1 0 0;0 1 0;0 0 1]);

% ========================================================================
% Simulation Loop
% ========================================================================
close all

t_total = 3;
t_step = 0.05;
Nsweep = 1; % Number of ups and downs, not number of periods
n_steps = t_total/t_step;

rdr_pos = zeros(3,2);
rdr_vel = zeros(3,2);

tgt_pos = zeros(3,3);
tgt_vel = zeros(3,3);


[rdr_pos(:,1),rdr_vel(:,1)] = lhs_radmo(t_step);
[tgt_pos(:,1),tgt_vel(:,1)] = lhs_carmo(t_step);

[rdr_pos(:,2:end),rdr_vel(:,2:end)] = rhs_radmo(t_step);
[tgt_pos(:,2:end),tgt_vel(:,2:end)] = rhs_carmo(t_step);

% Generate visuals
% sceneview = phased.ScenarioViewer('BeamRange',62.5,...
%     'BeamWidth',[30; 30], ...
%     'ShowBeam', 'All', ...
%     'CameraPerspective', 'Custom', ...
%     'CameraPosition', [2101.04 -1094.5 644.77], ...
%     'CameraOrientation', [-152 -15.48 0]', ...
%     'CameraViewAngle', 1.45, ...
%     'ShowName',true,...
%     'ShowPosition', true,...
%     'ShowSpeed', true,...
%     'ShowRadialSpeed',false,...
%     'UpdateRate',1/t_step, ...
%     'Position',[1000 100 1000 900]);



% DUAL RADAR
sceneview = phased.ScenarioViewer('Title', ...
    'Dual Radar Cross-Traffic Observation', ...
    'PlatformNames', {'RHS Radar', 'LHS Radar', ...
    'Car 1', 'Car 2', 'Car 3'},...
    'ShowLegend',true,...
    'BeamRange',[62.5 62.5],...
    'BeamWidth',[30 30; 30 30], ...
    'ShowBeam', 'All', ...
    'CameraPerspective', 'Custom', ...
    'CameraPosition', [1840.2 -1263.6 1007.01], ...
    'CameraOrientation', [-145.39 -24.16 0]', ...
    'CameraViewAngle', 1.5, ...
    'ShowName',false,...
    'ShowPosition', true,...
    'ShowSpeed', true,...
    'UpdateRate',1/t_step, ...
    'BeamSteering', [0 180;0 0]);

%     sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
%     drawnow;

% return;
% ========================================================================
% Signal Processing Configuration
% ========================================================================
Ns = 200;
win = hamming(Ns);
n_fft = 512;

% guard = 2*n_fft/n_samples;
% guard = floor(guard/2)*2; % make even
% % too many training cells results in too many detections
% train = round(20*n_fft/n_samples);
% train = floor(train/2)*2;
train = 64;
guard = 4;
F = 0.1e-3; 

OS = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',train);

% Define frequency axis

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
fbu = zeros(n_steps,nbins);
fbd = zeros(n_steps,nbins);

rhs_rgs = zeros(n_steps,nbins);
rhs_spd = zeros(n_steps,nbins);
rhs_toas = zeros(n_steps,nbins);

lhs_rgs = zeros(n_steps,nbins);
lhs_spd = zeros(n_steps,nbins);
lhs_toas = zeros(n_steps,nbins);


lhs_fftu = zeros(1, 256);
lhs_fftd = zeros(1, 256);

rhs_fftu = zeros(1, 256);
rhs_fftd = zeros(1, 256);


beat_arr = zeros(n_steps,nbins);

osu_pk_clean = zeros(n_steps,n_fft/2);
osd_pk_clean = zeros(n_steps,n_fft/2);

% Make slightly larger to allow for holding previous
% >16 will always be 0 and not influence results
% previous_det = zeros(nbins+2, 1);
scan_width = 15;
% f_bin_edges_idx = size(f_pos(),2)/nbins;

index_end = 0;
beat_index = 0;
close all
fig1 = figure('WindowState','maximized');
tiledlayout(2,1)
nexttile
p1 = plot(lhs_fftd);
title("LHS time of arrival")
nexttile
p2 = plot(lhs_fftd);
title("RHS time of arrival")


movegui(fig1, 'east');
% % Set up arrays for two targets
% fbu = zeros(n_steps, 2);
% fbd = zeros(n_steps, 2);
% r = zeros(n_steps, 2);
% v = zeros(n_steps, 2);

% Doppler clutter
fd_clut = 400;

Dn = fix(fs_wav/fs);

lhs_ntarg = 2;
rhs_ntarg = 1;
n_bins = 16;
%%
for t = 1:n_steps
    %disp(t)
    lhs_carmo(t_step);
    rhs_carmo(t_step);
    
    [rdr_pos(:,1),rdr_vel(:,1)] = lhs_radmo(t_step);
    [tgt_pos(:,1),tgt_vel(:,1)] = lhs_carmo(t_step);
    
    [rdr_pos(:,2:end),rdr_vel(:,2:end)] = rhs_radmo(t_step);
    [tgt_pos(:,2:end),tgt_vel(:,2:end)] = rhs_carmo(t_step);
    
    sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
    drawnow;



    l_xru = simulate_sweeps(Nsweep,wave,lhs_radmo,lhs_carmo,...
        txer,chann,lhs_cartarg,receiver, Dn, Ns);

    l_xrd = simulate_sweeps(Nsweep,wave,lhs_radmo,lhs_carmo,...
        txer,chann,lhs_cartarg,receiver, Dn, Ns);

    r_xru = simulate_sweeps(Nsweep,wave,rhs_radmo,rhs_carmo,...
        txer,chann,rhs_cartarg,receiver, Dn, Ns);

    r_xrd = simulate_sweeps(Nsweep,wave,rhs_radmo,rhs_carmo,...
        txer,chann,rhs_cartarg,receiver, Dn, Ns);


%     rhs_sig = simulate_sweeps(Nsweep,wave,rhs_radmo, ...
%         rhs_carmo, txer, chann, rhs_cartarg, receiver, ...
%         Dn, Ns);
% 
%     lhs_sig = simulate_sweeps(Nsweep,wave,lhs_radmo, ...
%         lhs_carmo, txer, chann, lhs_cartarg, receiver, ...
%         Dn, Ns);



    [rhs_rgs(t, :), rhs_spd(t, :), rhs_toas(t, :), ...
        rhs_fftu, rhs_fftd] = icps_dsp(OS, ...
        abs(r_xru.').^2, ...
        abs(r_xrd.').^2, ...
        win, ...
        n_fft, ...
        f_pos, ...
        fd_clut, ...
        n_bins);

    [lhs_rgs(t, :), lhs_spd(t, :), lhs_toas(t, :), ...
        lhs_fftu, lhs_fftd] = icps_dsp(OS, ...
        abs(l_xru.').^2, ...
        abs(l_xrd.').^2, ...
        win, ...
        n_fft, ...
        f_pos, ...
        fd_clut, ...
        n_bins);
    
%     set(p1, 'YData',lhs_toas(t, :))
%     set(p2, 'YData',rhs_toas(t, :))
%     sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
%     drawnow;

    set(p1, 'YData', absmagdb(lhs_fftd))
    set(p2, 'YData', absmagdb(lhs_fftu))
    drawnow;
    pause(0.5)




%     
%     r(t, 1) = beat2range([fbu_r fbd_r],sweep_slope,c);
%     r(t, 2) = beat2range([fbu_l fbd_l],sweep_slope,c);
% 
%     fd = -(fbu_r+fbd_r)/2;
%     v(t, 1) = dop2speed(fd,lambda)/2;
% 
%     fd = -(fbu_l+fbd_l)/2;
%     v(t, 2) = dop2speed(fd,lambda)/2;
% 
%     fbu(t,1) = fbu_r;
%     fbu(t,2) = fbu_l;
%     fbd(t,1) = fbd_r;
%     fbd(t,2) = fbd_l;


end


%% Plots

% XR = fft(xr(:,8));
% Fs = 200e3;
% f = f_ax(size(XR,1),Fs);
% close all
% figure
% % tiledlayout(2,1)
% % nexttile
% % plot(real(xr))
% % nexttile
% plot(f, fftshift(10*log(abs(XR))))
% plot(fbu(:,1))
% nexttile
% plot(r(:,1))
% nexttile
% plot(v(:,1))



