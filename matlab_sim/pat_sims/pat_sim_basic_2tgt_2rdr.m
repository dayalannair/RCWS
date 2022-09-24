%% Radar Parameters
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
fs = max(2*fb_max,bw);
%fs = 200e3; % kills range est
rng(2012);
waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs, 'SweepDirection','Triangle');
% close all
% figure
% sig = waveform();
% subplot(211); plot(0:1/fs:tm-1/fs,real(sig));
% xlabel('Time (s)'); ylabel('Amplitude (v)');
% title('FMCW signal'); axis tight;
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

%% Scenario

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
cartarget = phased.RadarTarget('MeanRCS',[car1_rcs car2_rcs car3_rcs], ...
    'PropagationSpeed',c,...
    'OperatingFrequency',fc);

% Define target motion - 2 targets
carmotion = phased.Platform('InitialPosition', ...
    [car1_x_dist car2_x_dist car3_x_dist; ...
    car1_y_dist car2_y_dist car3_y_dist; ...
    0.5 0.5 0.5],...
    'Velocity',[-car1_speed -car2_speed -car3_speed; ...
                0 0 0; ...
                0 0 0]);

% Define propagation medium
channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc, ...
    'SampleRate',fs, ...
    'TwoWayPropagation',true);

% Define radar motion
rdr_orientation = [1 0 0;0 1 0;0 0 1];
rdr_orientation(:,:,2) = [-1 0 0;0 1 0;0 0 1];

radarmotion = phased.Platform('InitialPosition', ...
    [0 0;0 0;0.5 0.5],...
    'Velocity',[0 0;0 0;0 0], ...
    'InitialOrientationAxes',rdr_orientation);

%% Simulation Loop
close all

t_total = 10;
t_step = 1;
Nsweep = 2;
n_steps = t_total/t_step;

[rdr_pos,rdr_vel] = radarmotion(t_step);
[tgt_pos,tgt_vel] = carmotion(t_step);

% Generate visuals
sceneview = phased.ScenarioViewer('Title', 'Dual Radar Cross-Traffic Observation', ...
    'PlatformNames', {'RHS Radar', 'LHS Radar', 'Car 1', 'Car 2', 'Car 3'},...
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

sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
drawnow
%%

% Set up arrays for two targets
fbu = zeros(n_steps, 2);
fbd = zeros(n_steps, 2);
r = zeros(n_steps, 2);
v = zeros(n_steps, 2);

for t = 1:n_steps
    %disp(t)
    [tgt_pos,tgt_vel] = carmotion(t_step);
    
    sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
    drawnow;

%     % issue: helper updates target position and velocity within each
%     sweep. Resolved --> issue was releasing waveforms?

    [r_xr, l_xr] = sim_sweeps_2rdr(Nsweep,waveform,radarmotion,carmotion,...
        transmitter,channel,cartarget,receiver);

%     fbu_r = rootmusic(pulsint(r_xr(:,1:2:end),'coherent'),1,fs);
%     fbd_r = rootmusic(pulsint(l_xr(:,2:2:end),'coherent'),1,fs);
%     fbu_l = rootmusic(pulsint(r_xr(:,1:2:end),'coherent'),1,fs);
%     fbd_l = rootmusic(pulsint(l_xr(:,2:2:end),'coherent'),1,fs);
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



