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
waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs_wav, 'SweepDirection','Triangle');
% close all
% figure
sig = waveform();
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

transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
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
lhs_cartarget = phased.RadarTarget('MeanRCS',[car2_rcs car3_rcs], ...
    'PropagationSpeed',c,...
    'OperatingFrequency',fc);

rhs_cartarget = phased.RadarTarget('MeanRCS',car1_rcs, ...
    'PropagationSpeed',c,...
    'OperatingFrequency',fc);

% Define target motion - 2 targets
lhs_carmotion = phased.Platform('InitialPosition', ...
    [car2_x_dist car3_x_dist; ...
    car2_y_dist car3_y_dist; ...
    0.5 0.5],...
    'Velocity',[-car2_speed -car3_speed; ...
                0 0; ...
                0 0]);

rhs_carmotion = phased.Platform('InitialPosition', ...
    [car1_x_dist; ...
    car1_y_dist; ...
    0.5],...
    'Velocity',[-car1_speed; ...
                0; ...
                0]);

% Define propagation medium
channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc, ...
    'SampleRate',fs, ...
    'TwoWayPropagation',true);

% Define radar motion
rdr_orientation = [1 0 0;0 1 0;0 0 1];
rdr_orientation(:,:,2) = [-1 0 0;0 1 0;0 0 1];

radar_pos = [0 0;0 0;0.5 0.5];
radar_vel = [0 0;0 0;0 0];

rad_pos1 = [0; 0; 0.5];
rad_vel1 = [0; 0; 0];
radarmotion = phased.Platform('InitialPosition', ...
    radar_pos,...
    'Velocity',radar_vel, ...
    'InitialOrientationAxes',rdr_orientation);

% ========================================================================
% Simulation Loop
% ========================================================================
close all

t_total = 10;
t_step = 0.1;
Nsweep = 1;
n_steps = t_total/t_step;

[rdr_pos,rdr_vel] = radarmotion(t_step);
[tgt_pos,tgt_vel] = carmotion(t_step);

% Generate visuals
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


lhs_fftu = zeros(256);
lhs_fftd = zeros(256);

rhs_fftu = zeros(256);
rhs_fftd = zeros(256);


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
p1 = plot(lhs_toas);
title("LHS time of arrival")
nexttile
p2 = plot(rhs_toas);
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
    lhs_carmotion(t_step);
    rhs_carmotion(t_step);

%     [r_xr, l_xr] = sim_sweeps_2rdr(Nsweep,waveform,radarmotion,carmotion,...
%         transmitter,channel,cartarget,receiver, Dn, Ns);
%     rhs_echo = simulate_sweeps(Nsweep,waveform,radarmotion, ...
%         carmotion, transmitter,channel,cartarget,receiver, Dn, Ns);
%     lhs_echo = simulate_sweeps(Nsweep,waveform,radarmotion, ...
%         carmotion(:, 2:3), transmitter,channel,cartarget,receiver, Dn, Ns);

    [rhs_sig, lhs_sig] = sim_sweeps_dual(Nsweep, waveform,...
            lhs_carmotion, rhs_carmotion, transmitter, ...
            channel,lhs_cartarget, rhs_cartarget, receiver, Dn, Ns, ...
            lhs_ntarg, rhs_ntarg, ...
            rad_pos1, rad_vel1);


    [rhs_rgs(t, :), rhs_spd(t, :), rhs_toas(t, :), ...
        rhs_fftu, rhs_fftd] = icps_dsp(OS, ...
        abs(rhs_sig(:,1)).^2, ...
        abs(rhs_sig(:,2)).^2, ...
        win, ...
        n_fft, ...
        f_pos, ...
        fd_clut, ...
        n_bins);

    [lhs_rgs(t, :), lhs_spd(t, :), lhs_toas(t, :), ...
        lhs_fftu, lhs_fftd] = icps_dsp(OS, ...
        abs(lhs_sig(:,1)).^2, ...
        abs(lhs_sig(:,2)).^2, ...
        win, ...
        n_fft, ...
        f_pos, ...
        fd_clut, ...
        n_bins);
    
%     set(p1, 'YData',lhs_toas(t, :))
%     set(p2, 'YData',rhs_toas(t, :))
%     sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
%     drawnow;

    set(p1, 'YData',absmagdb(lhs_fftd))
    set(p2, 'YData',absmagdb(lhs_fftu))
    drawnow;
%     pause(1)




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



