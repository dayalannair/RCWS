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
%fd_max = speed2dop(2*v_max,lambda)
%fb_max = fr_max+fd_max;
fb_max = 100e3;
% fs_wav_gen = max(2*fb_max,bw);
% fs = 200e3;

fs = max(2*fb_max,bw);
rng(2012);
waveform = phased.FMCWWaveform('SweepTime',tm, ...
    'SweepBandwidth',bw, ...
    'SampleRate',fs, ...
    'SweepDirection','Triangle');
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

rx_gain = 15+ant_gain;                          % in dB
rx_nf = 4.5;                                    % in dB

transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs);

%% Scenario
car_dist = 50;
car_speed = 80/3.6;
car_rcs = db2pow(min(10*log10(car_dist)+5,20));

cartarget = phased.RadarTarget('MeanRCS',car_rcs,'PropagationSpeed',c,...
    'OperatingFrequency',fc);

carmotion = phased.Platform('InitialPosition',[car_dist;0;0.5],...
    'Velocity',[-car_speed;0;0]);

channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs,'TwoWayPropagation',true);

radar_speed = 0;
radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);

%% CFAR
F = 0.015;
CFAR = phased.CFARDetector('NumTrainingCells',20, ...
    'NumGuardCells',4, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'SOCA');




%% Simulation Loop
close all


t_total = 1;
% Time between observations
t_step = 0.01;
sweeps_per_dwell = 2;
n_steps = t_total/t_step;
n_sweeps = n_steps;

% Below does not work. LINSPACE :)
%t = 1:t_step:t_total;
t = linspace(0,t_total, n_steps);

% makes sense. We only look at a sweep
% at each step increment
% does this affect triangle?
% NO. we use 2 sweeps per dwell, meaning one up and one down
% during each step
% the maximum ?useful? step is around the CW period
%n_sweeps = n_steps;
%n_sweeps = 200;
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
r = zeros(n_steps, 1);
v = zeros(n_steps, 1);
Dn = fix(fs/(2*fb_max));
fs_adc = 200e3;

n_samples = 200;
f = f_ax(n_samples, fs_adc);
v_max = 80/3.6; 
%fd_max = speed2dop(v_max, lambda)*2
fd_max = 100000;
fb = zeros(n_sweeps,2);
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);
%rng(2012);
for i = 1:n_steps
    %disp(t)
    [tgt_pos,tgt_vel] = carmotion(t_step);
    
%     sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
%     drawnow;

%     % issue: helper updates target position and velocity within each
%     sweep. Resolved --> issue was releasing waveforms?
    
    % Received demodulation (mixer) signal
    xr = simulate_sweeps(sweeps_per_dwell,waveform,radarmotion,carmotion,...
        transmitter,channel,cartarget,receiver);

    % sample signal at twice max beat frequency - decimation
    % round to integer
    % FIR seems to not work - need to find optimal filter
    % currently uses Chebychev IIR
    xr_d_up = decimate(xr(:,1),Dn);%,'FIR');
    xr_d_down = decimate(xr(:,2),Dn);%,'FIR');

    IQ_UP = fftshift(fft(xr_d_up,[],1));
    IQ_DOWN = fftshift(fft(xr_d_down,[],1));
   
    up_detections = CFAR(abs(IQ_UP), 1:200);
    down_detections = CFAR(abs(IQ_DOWN), 1:200);
    
    [highest_SNR_up, pk_idx_up]= max(up_detections.*IQ_UP);
    [highest_SNR_down, pk_idx_down] = max(down_detections.*IQ_DOWN);

    fb(i, 1) = f(pk_idx_up);
    fb(i, 2) = f(pk_idx_down);

    fd = -fb(i,1)-fb(i,2);
    if and(abs(fd)<=fd_max, fd > 0)
        fd_array(i) = fd/2;
        speed_array(i) = dop2speed(fd/2,lambda)/2;
        range_array(i) = beat2range([fb(i,1) fb(i,2)], sweep_slope, c);
    end
end

%% Results

expected_range = car_dist - car_speed.*t;
expected_speed = car_speed .* ones(1, n_steps);

close all 
figure
tiledlayout(2,1)
nexttile

plot(t, range_array)
title("Range")
ylabel("range (m)")
xlabel("time (s)")
hold on
plot(t, expected_range)
%legend({'result', 'expected'});
nexttile

plot(t, speed_array)
title("Speed")
ylabel("speed (m/s)")
xlabel("time (s)")
hold on
plot(t, expected_speed)
%legend({'result', 'expected'});

%% Plots
% close all
% up_peaks = up_detections.*IQ_UP;
% down_peaks = down_detections.*IQ_DOWN;
% figure
% tiledlayout(4,1)
% nexttile
% plot(f/1000, 10*log10(abs(IQ_UP)))
% hold on
% stem(f/1000, 10*log10(up_peaks))
% nexttile
% plot(f/1000, 10*log10(abs(IQ_DOWN)))
% hold on
% stem(f/1000, 10*log10(down_peaks))
% % nexttile
% % plot(f/1000, abs(IQ_UP))
% % nexttile
% % plot(f/1000, abs(IQ_DOWN))
% nexttile
% plot(real(xr_d_up))
% nexttile
% plot(real(xr_d_down))
% plot(real(xr(:,1)))
% nexttile
% plot(real(xr(:,2)))



