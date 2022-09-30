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
% fs_wav =1*240e6;
%fs_wav = 200e3; % kills range est
rng(2012);
waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs_wav, 'SweepDirection','Triangle');
% close all
% figure
% sig = waveform();
% subplot(211); plot(0:1/fs_wav:tm-1/fs_wav,real(sig));
% xlabel('Time (s)'); ylabel('Amplitude (v)');
% title('First 10 \mus of the FMCW signal'); axis([0 1e-5 -1 1]);
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

car1_dist = sqrt(car1_x_dist^2 + car1_y_dist^2);
car2_dist = sqrt(car2_x_dist^2 + car2_y_dist^2);

car1_rcs = db2pow(min(10*log10(car1_dist)+5,20));
car2_rcs = db2pow(min(10*log10(car2_dist)+5,20));

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
    'UpdateRate',1/t_step, ...
    'Position',[1000 100 1000 900]);

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


% Taylor window
nbar = 4;
sll = -38;
twin = taylorwin(Ns, nbar, sll);
% wind = taylorwin(n_samples, nbar, sll);
% Gaussian
% win = gausswin(n_samples);
% Blackmann 
bwin = blackman(Ns);
% % Kaiser
% kbeta = 5;
% win = kaiser(n_samples, kbeta);

% Range axis
rng_ax = beat2range((faxis_kHz*1000)', sweep_slope, c);

%%
close all
f1 = figure('WindowState','normal', 'Position',[0 100 1000 900]);
movegui(f1, "west")

for t = 1:n_steps
    %disp(t)
    [tgt_pos,tgt_vel] = carmotion(t_step);

%     % issue: helper updates target position and velocity within each
%     sweep. Resolved --> issue was releasing waveforms?

%     xr = simulate_sweeps2(Nsweep,waveform,radarmotion,carmotion,...
%         transmitter,channel,cartarget,receiver);

    % Output at sampling rate (decimation)
    xru = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
        transmitter,channel,cartarget,receiver, Dn, Ns);

    xrd = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
        transmitter,channel,cartarget,receiver, Dn, Ns);
    
    % NOTE: Up and Down are reversed for some reason in F domain
    % find out why. For now set one to the other
    % NOTE: Somehow resolved using range axis
%     xru_int = pulsint(xr(:,1:2:end),'coherent');
%     xrd_int = pulsint(xr(:,2:2:end),'coherent');
%     xru_int = xr(:,1);
%     xrd_int = xr(:,2);
    % Window
    xru_twin = xru.*twin;
    xrd_twin = xrd.*twin;
    
    xru_bwin = xru.*bwin;
    xrd_bwin = xrd.*bwin;

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
    XRU = fft(xru, nfft);
    XRD = fft(xrd, nfft);
    
    XRU_twin = fft(xru_twin, nfft);
    XRD_twin = fft(xrd_twin, nfft);
    
    XRU_bwin = fft(xru_bwin, nfft);
    XRD_bwin = fft(xrd_bwin, nfft);
% --------------------------------------------------------
% Plotting received signals
% --------------------------------------------------------
%     plot(real(xrd))
%     drawnow;
% % remove the two lines below to use original program
% end
% return;
% --------------------------------------------------------
    subplot(3,2,1)
    plot(rng_ax,sftmagdb(XRU))
    title("Dechirped up sweep spectrum")
    xlabel("Range (m)")
    ylabel("Magnitude (dB)")
    grid on
%     axis([-62.5 62.5 -90 -20])
%     subplot(2,2,2)
%     plot(faxis_kHz,sftmagdb(XRD))
%     title("Dechirped down sweep spectrum")
%     xlabel("Frequency (kHz)")
%     ylabel("Magnitude (dB)")
    
    subplot(3,2,3)
    plot(rng_ax,sftmagdb(XRU_twin))
    title("Dechirped and Taylor windowed up sweep spectrum")
    xlabel("Range (m)")
    ylabel("Magnitude (dB)")
%     axis([-62.5 62.5 -110 -20])
    grid on

    subplot(3,2,5)
    plot(rng_ax,sftmagdb(XRU_bwin))
    title("Dechirped and Blackmann windowed up sweep spectrum")
    xlabel("Range (m)")
    ylabel("Magnitude (dB)")

   % ==================================================================
   % Down chirps
    subplot(3,2,2)
    plot(rng_ax,sftmagdb(XRD))
    title("Dechirped up sweep spectrum")
    xlabel("Range (m)")
    ylabel("Magnitude (dB)")
    grid on
%     axis([-62.5 62.5 -90 -20])
%     subplot(2,2,2)
%     plot(faxis_kHz,sftmagdb(XRD))
%     title("Dechirped down sweep spectrum")
%     xlabel("Frequency (kHz)")
%     ylabel("Magnitude (dB)")
    
    subplot(3,2,4)
    plot(rng_ax,sftmagdb(XRD_twin))
    title("Dechirped and Taylor windowed up sweep spectrum")
    xlabel("Range (m)")
    ylabel("Magnitude (dB)")
%     axis([-62.5 62.5 -110 -20])
    grid on

    subplot(3,2,6)
    plot(rng_ax,sftmagdb(XRD_bwin))
    title("Dechirped and Blackmann windowed up sweep spectrum")
    xlabel("Range (m)")
    ylabel("Magnitude (dB)")
%     axis([-62.5 62.5 -200 -20])


    grid on
    sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
    
%     subplot(2,2,4)
%     plot(faxis_kHz,sftmagdb(XRD_win))
%     title("Dechirped down sweep spectrum")
%     xlabel("Frequency (kHz)")
%     ylabel("Magnitude (dB)")
%     drawnow;
%     pause(0.5)
end

return
%% Plots

% XR = fft(xr);
% Fs = 200e3;
% f = f_ax(size(XR,1),Fs);
% close all
% figure
% tiledlayout(2,1)
% nexttile
% plot(real(xr))
% nexttile
% plot(f, fftshift(20*log(abs(XR))))
% plot(fbu(:,1))
% nexttile
% plot(r(:,1))
% nexttile
% plot(v(:,1))



