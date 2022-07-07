%% Radar Parameters
% Fixed
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
fs = 200e3;

% Tuneable
bw = 100e6; % tuneable
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
    'SampleRate',fs);

%% Scenario
car_dist = 100;
car_speed = 20/3.6;
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

% specanalyzer = dsp.SpectrumAnalyzer('SampleRate',fs,...
%     'PlotAsTwoSidedSpectrum',true,...
%     'Title','Spectrum for received and dechirped signal',...
%     'ShowLegend',true);

%% Simulation Loop
rng(2012);
% Theoretically target in range bin for 0.09 sec therefore 90 sweeps
Nsweep = 64;
xr = complex(zeros(waveform.SampleRate*waveform.SweepTime,Nsweep));
% Decimate to simulate ADC
Dn = fix(fs_wav_gen/(fs));
for m = size(xr,2):-1:1
    xr_d(:,m) = decimate(xr(:,m),Dn,'FIR');
end

for m = 1:Nsweep
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
end
%
for m = size(xr,2):-1:1
    xr_d(:,m) = decimate(xr(:,m),Dn);%,'FIR');
end
%% Their map
rngdopresp = phased.RangeDopplerResponse('PropagationSpeed',c,...
    'DopplerOutput','Speed','OperatingFrequency',fc,'SampleRate',fs,...
    'RangeMethod','FFT','SweepSlope',sweep_slope,...
    'RangeFFTLengthSource','Property','RangeFFTLength',40,...
    'DopplerFFTLengthSource','Property','DopplerFFTLength',64);

clf;
plotResponse(rngdopresp,xr_d);    
%axis([-v_max v_max 0 r_max])
clim = caxis;
% Fixed v max error by decimating to sim adc sampling
% Range error? seems to reduce axis when reducing fft length
 %% My map





