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
ant_gain = 16.6;
Ppeak = 50; % dBm
% Ppeak = 100;
tx_ppower = 10^((Ppeak-30)/10);
tx_gain = 9+ant_gain;                           % in dB

rx_gain = 30+ant_gain;                          % in dB
rx_nf = 4.5;                                    % in dB
rx_nf = 0;   
transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
cosineElement = phased.CosineAntennaElement;
cosineElement.FrequencyRange = [fc (fc+bw)];

Nrow = 4;
Ncol = 4;
fmcwCosineArray = phased.URA;
fmcwCosineArray.Element = cosineElement;
fmcwCosineArray.Size = [Nrow Ncol];
% Change spacing for uRAD
fmcwCosineArray.ElementSpacing = [0.5*lambda 0.5*lambda];
radiator = phased.Radiator('Sensor',fmcwCosineArray, ...
    'OperatingFrequency', fc);

% Collector for receive array
collector = phased.Collector('Sensor',fmcwCosineArray, ...
    'OperatingFrequency',fc);

receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs_wav, 'NoiseComplexity','Real');

% angles = yaw, pitch, roll. roll axis is the direction platform is facing
transceiver = radarTransceiver('Waveform',waveform,'Transmitter', ...
    transmitter, 'TransmitAntenna',radiator,'ReceiveAntenna',collector, ...
    'Receiver', receiver, 'MountingLocation', [0, 0, 0.5], ...
    'MountingAngles', [0 90 0]);
% , 'MechanicalScanMode','Circular', ...
%     'MechanicalScanRate', 360);
