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
fs = max(2*fb_max,bw);
%fs = 200e3; % kills range est
rng(2012);
waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs, 'SweepDirection','Triangle');
close all
figure
sig = waveform();
subplot(211); plot(0:1/fs:tm-1/fs,real(sig));
xlabel('Time (s)'); ylabel('Amplitude (v)');
title('FMCW signal'); axis tight;
subplot(212); spectrogram(sig,32,16,32,fs,'yaxis');
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

%% Simulation Loop
close all

t_total = 1;
t_step = 0.1;
Nsweep = 16;
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
fbu_a = zeros(n_steps, 1);
fbd_a = zeros(n_steps, 1);
r = zeros(n_steps, 1);
v = zeros(n_steps, 1);

for t = 1:n_steps
    [tgt_pos,tgt_vel] = carmotion(t_step);
    
    sceneview(rdr_pos,rdr_vel,tgt_pos,tgt_vel);
    drawnow;

    xr = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
        transmitter,channel,cartarget,receiver);
    
    i = pulsint(xr(:,1:2:end),'coherent');
    q = pulsint(xr(:,2:2:end),'coherent');

    i = i.';
    q = q.';
    iq = i + 1i*q;
    
    Ns = size(iq, 2);
    Fs = 200e3;
    f = f_ax(Ns, Fs);

    IQ = fftshift(fft(iq,[],2),2);
    IQ_mag = abs(IQ);
    
    [peak, freq] = findpeaks(IQ_mag, f, 'MinPeakDistance', 1500,'MinPeakProminence',1e4,'MinPeakHeight',0.5e4,'MinPeakWidth', 1000, 'NPeaks', 4);

     if (numel(peak)>1)
         pk_sorted = sort(peak, 2, 'descend');
         idx = find(peak==pk_sorted(1));
         fq = freq(idx);
         if fq>1
            fbu = fq;
            idx = find(peak==pk_sorted(2));
            fbd = freq(idx);
         else
             fbd = fq;
            idx = find(peak==pk_sorted(2));
            fbu = freq(idx);
         end
     end
    r(t) = beat2range([fbu fbd],sweep_slope,c);
    
    fd = -(fbu+fbd)/2;
    v(t) = dop2speed(fd,lambda)/2;
    fbu_a(t) = fbu;
    fbd_a(t) = fbd;
end






