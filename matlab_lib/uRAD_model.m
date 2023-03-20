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
k = sweep_slope;
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

% Antenna

% ant_aperture = 6.06e-4;                         % in square meter
% ant_gain = aperture2gain(ant_aperture,lambda);  % in dB
ant_gain = 16.6;
tx_ppower = db2pow(5)*1e-3;                     % in watts
tx_gain = 19-30;                           % dbm to db

rx_gain = ant_gain;                          % in dB
rx_nf = 10;                                    % in dB
% rx_nf = 0;

transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs_wav, 'NoiseComplexity','Real', );