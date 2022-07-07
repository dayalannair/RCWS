%% Radar Parameters
% Fixed
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
fs = 200e3;

% Tuneable
% Cant make tc too small without reducing BW as well
bw = 75e6; % tuneable
% n = 60;     % tuneable
tc = 0.2e-3;

% Calculated
% tc = n/fs;
n = round(fs*tc);
rng_res = bw2rangeres(bw,c);
sweep_slope = bw/tc;


r_max = c*n/(4*bw);
v_max = lambda/(4*tc);
fd_max = speed2dop(2*v_max,lambda);
fr_max = range2beat(r_max,sweep_slope,c);
fb_max = fr_max+fd_max;
fs_wav_gen = max(2*fb_max,bw);
% fs_wav_gen = 2*bw;
waveform = phased.FMCWWaveform('SweepTime',tc, ...
    'SweepBandwidth',bw, ...
    'SampleRate',fs_wav_gen, ...
    'SweepDirection','Up');

t_ax = 0:1/fs_wav_gen:tc-1/fs_wav_gen;
% close all
% figure
% sig = waveform();
% subplot(211); plot(t_ax*1000,real(sig));
% xlabel('Time (ms)'); ylabel('Amplitude (v)');
% title('FMCW signal'); axis tight;
% subplot(212); spectrogram(sig,32,16,32,fs_wav_gen,'yaxis');
% title('FMCW signal spectrogram');
%% NEEDS WORK
ant_gain =  16.6; % in dB

tx_ppower = 63.1e-3;    % in watts. Is peak power the max power?
tx_gain = 10+ant_gain;     % in dB. With output amp?

rx_gain = 15+ant_gain;  % in dB. With LNA?
rx_nf = 4.5;            % in dB

transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs_wav_gen);

%% Scenario
car_dist = 30;
car_speed = 20/3.6;
car_rcs = db2pow(min(10*log10(car_dist)+5,20));

cartarget = phased.RadarTarget('MeanRCS',car_rcs,'PropagationSpeed',c,...
    'OperatingFrequency',fc);

carmotion = phased.Platform('InitialPosition',[car_dist;0;0.5],...
    'Velocity',[-car_speed;0;0]);

channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs_wav_gen,'TwoWayPropagation',true);

radar_speed = 0;
radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);

% specanalyzer = dsp.SpectrumAnalyzer('SampleRate',fs,...
%     'PlotAsTwoSidedSpectrum',true,...
%     'Title','Spectrum for received and dechirped signal',...
%     'ShowLegend',true);

%% Simulation Loop
rng(2012);
% Theoretically target in range bin for 0.09 sec therefore 90 sweeps
n_sweeps = 64;
xr = complex(zeros(waveform.SampleRate*waveform.SweepTime,n_sweeps));
% Decimate to simulate ADC
Dn = fix(fs_wav_gen/(fs));
%Dn = fix(fs_wav_gen/(2*fb_max));
xr_d = zeros(n,n_sweeps);

for m = 1:n_sweeps
    % Update radar and target positions
    [radar_pos,radar_vel] = radarmotion(waveform.SweepTime);
    [tgt_pos,tgt_vel] = carmotion(waveform.SweepTime);

    % Transmit FMCW waveform
    sig = waveform();
    txsig = transmitter(sig);

    % Propagate the signal and reflect off the target
    txsig = channel(txsig,radar_pos,tgt_pos,radar_vel,tgt_vel);
    txsig = cartarget(txsig);

    % Dechirp the received radar return
    txsig = receiver(txsig);
    dechirpsig = dechirp(txsig,sig);

    % Visualize the spectrum
%     specanalyzer([txsig dechirpsig]);

    xr(:,m) = dechirpsig;
    xr_d(:,m) = decimate(xr(:,m),Dn);%,'FIR');
end
%% Their map
rngdopresp = phased.RangeDopplerResponse('PropagationSpeed',c,...
    'DopplerOutput','Speed','OperatingFrequency',fc,'SampleRate',fs,...
    'RangeMethod','FFT','SweepSlope',sweep_slope,...
    'RangeFFTLengthSource','Property','RangeFFTLength',1024,...
    'DopplerFFTLengthSource','Property','DopplerFFTLength',256);

clf;
plotResponse(rngdopresp,xr_d);    
%axis([-v_max v_max 0 r_max])
clim = caxis;
% Fixed v max error by decimating to sim adc sampling
% Range error? seems to reduce axis when reducing fft length
return;

%% FFT
rng_len = size(xr_d,1);
vel_len = size(xr_d,2);

% Range FFT
f = f_ax(rng_len, fs);
XR_D = fft(xr_d);
close all
figure 
tiledlayout(2,1)
nexttile
% plot(real(xr(:,1)))
plot(real(xr_d(:,1)))
nexttile
plot(f/1000, sftmagdb(XR_D(:,1)))
%% Optimal parameters experimentally determined for simulated scenario

r_max
v_max_kmh = v_max*3.6
rng_res
t_frame = tc*n_sweeps;
vel_res = lambda/(2*t_frame)*3.6



 %% My map

% rng_bins = beat2range(f.', sweep_slope, c);
% angular_freq = f_ax(vel_len, 1/tc);
% vel_bins = lambda/(4*pi*tc).*angular_freq;
% 
% XR = fft2(xr_d);
% close all
% figure
% imagesc(vel_bins, rng_bins, sftmagdb(XR))
% xlabel("Velocity")
% ylabel("Range")
% 

