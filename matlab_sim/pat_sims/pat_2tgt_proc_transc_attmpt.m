%% Radar Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
range_max = 62.5;
tm = 1e-3;
bw = 240e6;
k = bw/tm;
Ns = 200;
addpath('../../matlab_lib/');
fs_adc = 200e3;
fr_max = fs_adc/2; % = range2beat(75*Ns/(bw*1e-6),k, c)
fd_max = speed2dop(2*75,lambda);
fb_max = fr_max+fd_max;
fs_wav = max(2*fb_max,bw);
rng(2012);
waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs_wav, 'SweepDirection','Triangle');
% close all
% figure
% sig = waveform();
% subplot(211); 
% plot(0:1/fs_wav:tm-1/fs_wav,real(sig));
% xlabel('Time (s)'); 
% ylabel('Amplitude (v)');
% title('First 10 \mus of the FMCW signal'); 
% axis([0 1e-5 -1 1]);
% subplot(212); 
% spectrogram(sig,32,16,32,fs_wav,'yaxis');
% title('FMCW signal spectrogram');

%% Antenna
% ant_gain = aperture2gain(ant_aperture,lambda);  % in dB
ant_gain = 16.6;
Ppeak = 20; % dBm
% Ppeak = 100;
tx_ppower = 10^((Ppeak-30)/10);
tx_gain = 9+ant_gain;                           % in dB

rx_gain = 30+ant_gain;                          % in dB
rx_nf = 10.5;                                    % in dB

transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
cosineElement = phased.CosineAntennaElement;
cosineElement.FrequencyRange = [fc (fc+bw)];
% cosinePattern = figure;
% pattern(cosineElement,fc)
Nrow = 4;
Ncol = 4;
fmcwCosineArray = phased.URA;
fmcwCosineArray.Element = cosineElement;
fmcwCosineArray.Size = [Nrow Ncol];
fmcwCosineArray.ElementSpacing = [0.5*lambda 0.5*lambda];
% cosineArrayPattern = figure;
% pattern(fmcwCosineArray,fc);
radiator = phased.Radiator('Sensor',fmcwCosineArray, ...
    'OperatingFrequency', fc);

% Collector for receive array
collector = phased.Collector('Sensor',fmcwCosineArray, ...
    'OperatingFrequency',fc);

receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs_wav, 'NoiseComplexity','Complex');

transceiver = radarTransceiver('Waveform',waveform,'Transmitter', ...
    transmitter, 'TransmitAntenna',radiator,'ReceiveAntenna',collector, ...
    'Receiver', receiver);

%% Scenario

% Target parameters

% CASE 1: Static target at 50m
% car1_x_dist = 50;
% car1_y_dist = 2;
% car1_speed = 0/3.6;
% car2_x_dist = 50;
% car2_y_dist = -1000;
% car2_speed = 0/3.6;

% CASE 2: Static targets at 50 and 51m
% Test range resolution
% car1_x_dist = 50;
% car1_y_dist = 2;
% car1_speed = 0/3.6;
% car2_x_dist = 51;
% car2_y_dist = 2;
% car2_speed = 0/3.6;

% CASE 3: Static targets at 50m separated by 2m
% Test cross range resolution
% car1_x_dist = 50;
% car1_y_dist = 10;
% car1_speed = 0/3.6;
% car2_x_dist = 50;
% car2_y_dist = -10;
% car2_speed = 0/3.6;

% CASE 4: Target overtake
car1_x_dist = 40;
car1_y_dist = 2;
car1_speed = 20/3.6;
car2_x_dist = 60;
car2_y_dist = -2;
car2_speed = 80/3.6;

% Target positions
car1_dist = sqrt(car1_x_dist^2 + car1_y_dist^2);
car2_dist = sqrt(car2_x_dist^2 + car2_y_dist^2);

% Target RCS
car1_rcs = db2pow(min(10*log10(car1_dist)+5,20))*1000;
car2_rcs = db2pow(min(10*log10(car2_dist)+5,20))*1000;

car_rcs_signat = rcsSignature("Pattern",[200, 200]); % Default Swerling 0

% Define reflected signal
cartarget = phased.RadarTarget('MeanRCS',[car1_rcs car2_rcs], ...
    'PropagationSpeed',c,'OperatingFrequency',fc);

% Define target motion - 2 targets
carmotion = phased.Platform('InitialPosition',[car1_x_dist car2_x_dist; ...
    car1_y_dist car2_y_dist;0.5 0.5],...
    'Velocity',[-car1_speed -car2_speed;0 0;0 0]);

% Define propagation medium
channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs_wav,'TwoWayPropagation',true);

% Define radar motion
radar_speed = 0;
radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);

%% Simulation Loop
close all

t_total = 3;
t_step = 0.05;
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

[rdr_pos,rdr_vel] = radarmotion(1);

% Set up arrays for two targets
fbu = zeros(n_steps, 2);
fbd = zeros(n_steps, 2);
r = zeros(n_steps, 2);
v = zeros(n_steps, 2);

Dn = fix(fs_wav/fs_adc);
nfft = 512;
faxis_kHz = f_ax(nfft, fs_adc)/1000;
n_fft = 512;
train = 16;%n_fft/8;%64;
guard = 14;%n_fft/64;%8;
rank = round(3*train/4);
nbar = 3;
sll = -150;
F = 5*10e-4;
v_max = 60/3.6; 
fd_max = speed2dop(v_max, lambda)*2;
% Minimum sample number for 1024 point FFT corresponding to min range = 10m
% n_min = 83;
% for 512 point FFT:
n_min = 42;
% Divide into range bins of width 64
% bin_width = (n_fft/2)/nbins;
% nbins = 8;
% bin_width = 32; % account for scan width = 21
% scan_width = 21; % see calcs: Delta f * 21 ~ 8 kHz

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

OS1 = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA', ...
    'ThresholdOutputPort', true, ...
    'Rank',rank);

OS2 = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA', ...
    'ThresholdOutputPort', true, ...
    'Rank',rank);

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

subplot(2,2,1);
p1 = plot(rng_ax, absmagdb(IQ_UP(1:256)));
hold on
p1th = plot(rng_ax, absmagdb(upTh1(1:256)));
x  =linspace(1, nbins, nbins);
colors = cat(2, 2*x, 2*x);
win1 = scatter(cat(1,fb_idx1, fb_idx_end1), ones(2*nbins, 1)*130 ,2000, ...
colors, 'Marker', '|', 'LineWidth',1.5);
hold off
title("LHS UP chirp positive half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,2,2);
p2 = plot(rng_ax, absmagdb(IQ_DN(1:256)));
hold on
p2th = plot(rng_ax, absmagdb(dnTh1(1:256)));
win2 = scatter(cat(1,fb_idx1, fb_idx_end1), ones(2*nbins, 1)*130 ,2000, ...
colors, 'Marker', '|', 'LineWidth',1.5);
hold off
title("LHS DOWN chirp flipped negative half")
axis(ax_dims)
xticks(ax_ticks)
grid on

subplot(2,2,3)
p3 = imagesc(rgMtx1);

subplot(2,2,4)
p4 = imagesc(spMtx1);
simTime = 0;
i = 0;
for t = 1:n_steps
    i = i + 1;
    %disp(t)
    [tgt_pos,tgt_vel] = carmotion(t_step);
    tgt1 = struct('Position', tgt_pos(:,1).', 'Velocity', ...
        tgt_vel(:,1).', 'Signature', car_rcs_signat);
    tgt2 = struct('Position', tgt_pos(:,2).', 'Velocity', ...
        tgt_vel(:,2).', 'Signature', car_rcs_signat);
    % Output at sampling rate (decimation)
    % Transmit and receive up-chirp
%     xru = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
%         transmitter,channel,cartarget,transceiver, Dn, Ns, time);
    simTime = t;
    xru = sim_transceiver(transceiver, Dn, simTime, tgt1, tgt2);
%     xru = sim_transceiver(transceiver, Dn, simTime, cartarget);
    % Transmit and receive down-chirp
%     xrd = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
%         transmitter,channel,cartarget,transceiver, Dn, Ns, time);
    simTime = t + 1e-3;
    xrd = sim_transceiver(transceiver, Dn, simTime, tgt1, tgt2);
%     xrd = sim_transceiver(transceiver, Dn, simTime, cartarget);
%     
    % Window
    xru_twin = xru.'.*twin;
    xrd_twin = xrd.'.*twin;
    
    % 512-point FFT
    XRU_twin = fft(xru_twin, nfft).';
    XRD_twin = fft(xrd_twin, nfft).';

    % Halve spectra
    IQ_UP = XRU_twin(:, 1:n_fft/2);
    IQ_DN = XRD_twin(:, n_fft/2+1:end);
    
    % Null feed through
    IQ_UP(:, 1:num_nul1) = repmat(IQ_UP(:, num_nul1+1), [1, num_nul1]);
    IQ_DN(:, end-num_nul1+1:end) = ...
    repmat(IQ_DN(:, end-num_nul1), [1, num_nul1]);
    
    % Flip down spectrum
    IQ_DN = flip(IQ_DN,2);
    
    % CFAR
    [up_os1, upTh1] = OS1(abs(IQ_UP)', 1:n_fft/2);
    [dn_os1, dnTh1] = OS1(abs(IQ_DN)', 1:n_fft/2);
    
    % Extract magnitude of detections/set non-detections to zero
    upDets1 = abs(IQ_UP).*up_os1';
    dnDets1 = abs(IQ_DN).*dn_os1';
    
    % Processing
    [rgMtx1(i,:), spMtx1(i,:), spMtxCorr1(i,:), pkuClean1, ...
    pkdClean1, fbu1(i,:), fbd1(i,:), fdMtx1(i,:), fb_idx1, fb_idx_end1, ...
    beat_count_out1] = proc_sweep_multi_scan(bin_width, ...
    lambda, k, c, dnDets1, upDets1, nbins, n_fft, ...
    f_pos, scan_width, calib, lhs_road_width, beat_count_in1);
    
    % Update plots
    set(p1, 'YData', absmagdb(IQ_UP))
    set(p2, 'YData', absmagdb(IQ_DN))
    set(p1th, 'YData', absmagdb(upTh1))
    set(p2th, 'YData', absmagdb(dnTh1))
    set(p3, 'CData', rgMtx1)
    set(p4, 'CData', spMtx1)

    % Update 3D scene viewer
    sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
%     pause(0.00001)
end

%     % issue: helper updates target position and velocity within each
%     sweep. Resolved --> issue was releasing waveforms?

%     xr = simulate_sweeps2(Nsweep,waveform,radarmotion,carmotion,...
%         transmitter,channel,cartarget,transceiver);

