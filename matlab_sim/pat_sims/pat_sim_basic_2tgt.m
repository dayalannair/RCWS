%% Radar Parameters
fc = 24.005e9;%77e9;
%c = physconst('LightSpeed');
c = 3e8;
lambda = c/fc;
%range_max = 200;
range_max = 62.5;
%tm = 2e-3;
tm = 1e-3;
% range_res = 0.5;
% bw2 = rangeres2bw(range_res,c);
bw = 240e6;
sweep_slope = bw/tm;
addpath('../../matlab_lib/');
fr_max = range2beat(range_max,sweep_slope,c);
v_max = 230*1000/3600;
fd_max = speed2dop(2*v_max,lambda);
fb_max = fr_max+fd_max;
fs_wav = max(2*fb_max,bw);
fs_adc = 200e3;
%fs_wav = 200e3; % kills range est
rng(2012);
waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs_wav, 'SweepDirection','Triangle');
% close all
% figure
% sig = waveform();
% subplot(211); plot(0:1/fs_wav:tm-1/fs_wav,real(sig));
% xlabel('Time (s)'); ylabel('Amplitude (v)');
% title('FMCW signal'); axis tight;
% subplot(212); spectrogram(sig,32,16,32,fs_wav,'yaxis');
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
    'SampleRate',fs_wav);

%% Scenario

% Target parameters
car1_x_dist = 50;
car1_y_dist = 2;
car1_speed = 0/3.6;
car2_x_dist = 50;
car2_y_dist = -1000;
car2_speed = 0/3.6;

car1_dist = sqrt(car1_x_dist^2 + car1_y_dist^2);
car2_dist = sqrt(car2_x_dist^2 + car2_y_dist^2);

car1_rcs = db2pow(min(10*log10(car1_dist)+5,20));
car2_rcs = db2pow(min(10*log10(car2_dist)+5,20));

% Define reflected signal
cartarget = phased.RadarTarget('MeanRCS',[car1_rcs car2_rcs],'PropagationSpeed',c,...
    'OperatingFrequency',fc);

% Define target motion - 2 targets
carmotion = phased.Platform('InitialPosition',[car1_x_dist car2_x_dist;car1_y_dist car2_y_dist;0.5 0.5],...
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

t_total = 5;
t_step = 0.05;
Nsweep = 2;
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
    'UpdateRate',1/t_step);

[rdr_pos,rdr_vel] = radarmotion(1);

% Set up arrays for two targets
fbu = zeros(n_steps, 2);
fbd = zeros(n_steps, 2);
r = zeros(n_steps, 2);
v = zeros(n_steps, 2);

Dn = fix(fs_wav/fs_adc);
Ns = 200;
nfft = 512;
faxis_kHz = f_ax(nfft, fs_adc)/1000;
close all
f1 = figure('WindowState','normal');
movegui(f1, "west")

% Taylor window
nbar = 4;
sll = -38;
twinu = taylorwin(n_samples, nbar, sll);
twind = taylorwin(n_samples, nbar, sll);

%%
ref = waveform();
REF0 = fft(ref);
sampled_ref = decimate(ref,Dn);
REF = fft(sampled_ref, nfft);
close all
figure
% plot(real(sampled_ref))
% plot(absmagdb(REF0))
plot(real(ref))

%%

for t = 1:n_steps
    %disp(t)
    [tgt_pos,tgt_vel] = carmotion(t_step);
    
%     sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
%     drawnow;

%     % issue: helper updates target position and velocity within each
%     sweep. Resolved --> issue was releasing waveforms?

%     xr = simulate_sweeps2(Nsweep,waveform,radarmotion,carmotion,...
%         transmitter,channel,cartarget,receiver);

    % At sampling rate
    [~,xr] = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
        transmitter,channel,cartarget,receiver, Dn, Ns);
    
    xru_int = pulsint(xr(:,1:2:end),'coherent');
    xrd_int = pulsint(xr(:,2:2:end),'coherent');
    
    % Window
    xru_int = xru_int.*twinu;
    xrd_int = xrd_int.*twind;

%     fbu_rng = rootmusic(xru_int,2,fs_wav);
%     fbd_rng = rootmusic(xrd_int,2,fs_wav);
%     
%     r(t, 1) = beat2range([fbu_rng(1) fbd_rng(1)],sweep_slope,c);
%     r(t, 2) = beat2range([fbu_rng(2) fbd_rng(2)],sweep_slope,c);
% 
%     fd = -(fbu_rng(1)+fbd_rng(1))/2;
%     v(t, 1) = dop2speed(fd,lambda)/2;
% 
%     fd = -(fbu_rng(2)+fbd_rng(2))/2;
%     v(t, 2) = dop2speed(fd,lambda)/2;
%
%     fbu(t,:) = fbu_rng;
%     fbd(t,:) = fbd_rng;
    XRU = fft(xru_int, nfft);
    XRD = fft(xrd_int, nfft);
    tiledlayout(2, 1)
%     nexttile
%     plot(real(xru_int))
    nexttile
    plot(faxis_kHz,sftmagdb(XRU))
    title("Dechirped up sweep spectrum")
    xlabel("Frequency (kHz)")
    ylabel("Magnitude (dB)")
    sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
%     nexttile
%     plot(real(xrd_int))
    nexttile
    plot(faxis_kHz,sftmagdb(XRD))
    title("Dechirped down sweep spectrum")
    xlabel("Frequency (kHz)")
    ylabel("Magnitude (dB)")
    drawnow;
%     pause(0.5)
end

return
%% Plots

XR = fft(xr);
Fs = 200e3;
f = f_ax(size(XR,1),Fs);
close all
figure
tiledlayout(2,1)
nexttile
plot(real(xr))
nexttile
plot(f, fftshift(20*log(abs(XR))))
% plot(fbu(:,1))
% nexttile
% plot(r(:,1))
% nexttile
% plot(v(:,1))



