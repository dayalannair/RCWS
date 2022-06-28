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
close all
figure
sig = waveform();
subplot(211); plot(0:1/fs_wav:tm-1/fs_wav,real(sig));
xlabel('Time (s)'); ylabel('Amplitude (v)');
title('FMCW signal'); axis tight;
subplot(212); spectrogram(sig,32,16,32,fs_wav,'yaxis');
title('FMCW signal spectrogram');

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
fbu = zeros(n_steps, 1);
fbd = zeros(n_steps, 1);
r = zeros(n_steps, 1);
v = zeros(n_steps, 1);

xr_d = zeros(n_samples, 2);



for t = 1:n_steps
    %disp(t)
    [tgt_pos,tgt_vel] = carmotion(t_step);
    
%     sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
%     drawnow;

    xr = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
        transmitter,channel,cartarget,receiver);
    
    xr_d(:,1) = decimate(xr(:,1),Dn);%,'FIR');
    xr_d(:,2) = decimate(xr(:,2),Dn);

    fbu_rng = rootmusic(xr(:,1),1,fs_wav);
    fbd_rng = rootmusic(xr(:,2),1,fs_wav);
    
    r(t) = beat2range([fbu_rng fbd_rng],sweep_slope,c);
    
    fd = -(fbu_rng+fbd_rng)/2;
    v(t) = dop2speed(fd,lambda)/2;
    fbu(t) = fbu_rng;
    fbd(t) = fbd_rng;
end

%%

close all
figure
tiledlayout(2,1)
nexttile
plot(xr(:, 1))
nexttile
plot(xr(:,2))


%     % issue: helper updates target position and velocity within each
%     sweep. Resolved --> issue was releasing waveforms?



