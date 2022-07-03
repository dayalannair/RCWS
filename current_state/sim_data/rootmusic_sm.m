%% Radar Parameters
fc = 24.005e9;%77e9;
%c = physconst('LightSpeed');
c = 3e8;
lambda = c/fc;
%range_max = 200;
range_max = 62.5;
%tm = 2e-3;
tm = 1e-3;
% range_res = 1;
% bw = rangeres2bw(range_res,c);
bw = 240e6;
sweep_slope = bw/tm;

fr_max = range2beat(range_max,sweep_slope,c);
v_max = 230*1000/3600;
fd_max = speed2dop(2*v_max,lambda);
fb_max = fr_max+fd_max;
fs_wav = max(2*fb_max,bw);
%fs_wav = 200e3; % kills range est
rng(2012);
waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs_wav, 'SweepDirection','Triangle');

%%

ant_aperture = 6.06e-4;                         % in square meter
ant_gain = aperture2gain(ant_aperture,lambda);  % in dB

tx_ppower = db2pow(5)*1e-3;                     % in watts
tx_gain = 9+ant_gain;                           % in dB

rx_gain = 15+ant_gain;                          % in dB
rx_nf = 4.5;                                    % in dB

transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs_wav);

%% Scenario
car_dist = 50;
car_speed = 80/3.6;
car_rcs = db2pow(min(10*log10(car_dist)+5,20));

cartarget = phased.RadarTarget('MeanRCS',car_rcs,'PropagationSpeed',c,...
    'OperatingFrequency',fc);

carmotion = phased.Platform('InitialPosition',[car_dist;0;0.5],...
    'Velocity',[-car_speed;0;0]);

channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs_wav,'TwoWayPropagation',true);

radar_speed = 0;
radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);

%% Simulation Loop
close all

t_total = 1;
t_step = 0.05;
Nsweep = 2; % up and down
n_steps = t_total/t_step;
fs_adc = 200e3;% 2fbmax
Dn = fix(fs_wav/fs_adc);
n_samples = 200; % samples per sweep
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
%     'UpdateRate',1/t_step);

[rdr_pos,rdr_vel] = radarmotion(1);

fbu1 = zeros(n_steps, 1);
fbd1 = zeros(n_steps, 1);
r1 = zeros(n_steps, 1);
v1 = zeros(n_steps, 1);

fbu2 = zeros(n_steps, 1);
fbd2 = zeros(n_steps, 1);
r2 = zeros(n_steps, 1);
v2 = zeros(n_steps, 1);

xr_d = zeros(n_samples, 2);

for t = 1:n_steps
    [tgt_pos,tgt_vel] = carmotion(t_step);
    
%     sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
%     drawnow;

    xr = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
        transmitter,channel,cartarget,receiver);
    
    xr_d(:,1) = decimate(xr(:,1),Dn);%,'FIR');
    xr_d(:,2) = decimate(xr(:,2),Dn);

    % high sampling
    fbu_rng = rootmusic(xr(:,1),1,fs_wav);
    fbd_rng = rootmusic(xr(:,2),1,fs_wav);
   
    fd = -(fbu_rng+fbd_rng)/2;
    r1(t) = beat2range([fbu_rng fbd_rng],sweep_slope,c);
    v1(t) = dop2speed(fd,lambda)/2;
    fbu1(t) = fbu_rng;
    fbd1(t) = fbd_rng;

    % sampling at 2fbmax
    fbu_rng = rootmusic(xr_d(:,1),1,fs_adc);
    fbd_rng = rootmusic(xr_d(:,2),1,fs_adc);
   
    fd = -(fbu_rng+fbd_rng)/2;
    r2(t) = beat2range([fbu_rng fbd_rng],sweep_slope,c);
    v2(t) = dop2speed(fd,lambda)/2;
    fbu2(t) = fbu_rng;
    fbd2(t) = fbd_rng;
end

%% Plot results



%% FFT
XRu = fftshift(fft(xr(:,1)));
XRd = fftshift(fft(xr(:,2)));

XR_Du = fftshift(fft(xr_d(:,1)));
XR_Dd = fftshift(fft(xr_d(:,2)));

% XRu = fft(xr(:,1));
% XRd = fft(xr(:,2));
% 
% XR_Du = fft(xr_d(:,1));
% XR_Dd = fft(xr_d(:,2));
%% Plot FFT of received wave before and after sampling
f1 = f_ax(length(xr), fs_wav);
f2 = f_ax(n_samples, fs_adc);
close all
figure
tiledlayout(4,1)
nexttile
plot(f1/1e6, abs(XRu))
nexttile
plot(f1/1e6, abs(XRd))

nexttile
plot(f2/1000,abs(XR_Du))
nexttile
plot(f2/1000,abs(XR_Dd))


%% Plot received wave before and after sampling
close all
figure
tiledlayout(4,1)
nexttile
plot(real(xr(:, 1)))
nexttile
plot(real(xr(:,2)))
nexttile
plot(real(xr_d(:, 1)))
nexttile
plot(real(xr_d(:,2)))


% nexttile
% plot(real(xr(:, 1)))
% nexttile
% plot(real(xr(:,2)))


%     % issue: helper updates target position and velocity within each
%     sweep. Resolved --> issue was releasing waveforms?



