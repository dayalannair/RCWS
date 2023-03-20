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
% tiledlayout(2,3)
% sig = waveform();
% % subplot(211); 
% nexttile
% plot(0:1/fs_wav:tm-1/fs_wav,real(sig));
% xlabel('Time (s)'); 
% ylabel('Amplitude (v)');
% title('First 10 \mus of the FMCW signal'); 
% axis([0 1e-5 -1 1]);
% % subplot(212); 
% nexttile
% spectrogram(sig,32,16,32,fs_wav,'yaxis');
% sig = waveform();
% % subplot(213);
% nexttile
% plot(0:1/fs_wav:tm-1/fs_wav,real(sig));
% xlabel('Time (s)'); 
% ylabel('Amplitude (v)');
% title('First 10 \mus of the FMCW signal'); 
% axis([0 1e-5 -1 1]);
% % subplot(214); 
% nexttile
% spectrogram(sig,32,16,32,fs_wav,'yaxis');
% title('FMCW signal spectrogram');
% sig = waveform();
% % subplot(213);
% nexttile
% plot(0:1/fs_wav:tm-1/fs_wav,real(sig));
% xlabel('Time (s)'); 
% ylabel('Amplitude (v)');
% title('First 10 \mus of the FMCW signal'); 
% axis([0 1e-5 -1 1]);
% % subplot(214); 
% nexttile
% spectrogram(sig,32,16,32,fs_wav,'yaxis');
% title('FMCW signal spectrogram');

% close all
% figure
% tiledlayout(1,3)
% sig = waveform();
% nexttile
% spectrogram(sig,32,16,32,fs_wav,'yaxis');
% 
% sig = waveform();
% nexttile
% spectrogram(sig,32,16,32,fs_wav,'yaxis');
% title('FMCW signal spectrogram');
% sig = waveform();
% 
% nexttile
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
% rx_nf = 0;   


Nrow = 4;
Ncol = 4;


transmitter = phased.Transmitter( ...
    'PeakPower',tx_ppower, ...
    'Gain',tx_gain);

cosineElement = phased.CosineAntennaElement;
cosineElement.FrequencyRange = [fc (fc+bw)];

taperRow = [0.5 1 1 0.5];
taper = repmat(taperRow, [Nrow,1]);
fmcwCosineArray = phased.URA( ...
    'Element', cosineElement, ...
    'ArrayNormal', 'x', ...
    'Size',[Nrow Ncol], ...
    'ElementSpacing', [0.5*lambda 0.5*lambda], ...
    'Taper',taper);


cosineArrayPattern = figure;
pattern(fmcwCosineArray,fc);

radiator = phased.Radiator( ...
    'Sensor',fmcwCosineArray, ...
    'OperatingFrequency', fc);

% Collector for receive array
collector = phased.Collector( ...
    'Sensor',fmcwCosineArray, ...
    'OperatingFrequency',fc);

receiver = phased.ReceiverPreamp( ...
    'Gain',rx_gain, ...
    'NoiseFigure',rx_nf,...
    'SampleRate',fs_wav, ...
    'NoiseComplexity','Real');

% angles = yaw, pitch, roll. roll axis is the direction platform is facing
transceiver = radarTransceiver( ...
    'Waveform',waveform, ...
    'Transmitter', transmitter, ...
    'TransmitAntenna',radiator, ...
    'ReceiveAntenna',collector, ...
    'Receiver', receiver, ...
    'MountingLocation', [0, 0, 0], ...
    'MountingAngles', [0 0 0]);
% , 'MechanicalScanMode','Circular', ...
%     'MechanicalScanRate', 360);
