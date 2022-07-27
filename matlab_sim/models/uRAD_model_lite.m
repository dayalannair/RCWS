rng(2012);
fc = 24e9;                                 
c = physconst('LightSpeed');               
lambda = freq2wavelen(fc,c);                             

rangeMax = 75;                 

%for FMCW, sweep time atleast 5 - 6 times the round trip time
tm = 5*range2time(rangeMax,c);   

% Note: BW = 240 Hz, ideal delta R is smaller!
rangeRes = 1.5;
bw = rangeres2bw(rangeRes,c);           
sweepSlope = bw/tm;                     

%FMCW: sample rate 2x fbeat
fbeatMax = range2beat(rangeMax,sweepSlope,c); 

vMax = 75;                   
fdopMax = speed2dop(2*vMax,lambda);    
% see equations for fifmax
fifMax = fbeatMax+fdopMax;
% sample rate is the larger of 2fif or bw
fs = max(2*fifMax,bw);      

waveform = phased.FMCWWaveform('SweepTime',tm, ...
    'SweepBandwidth',bw, ...
    'SampleRate',fs, ...
    'SweepDirection','Triangle');%, ...
    %'NumSweeps',2);

sig = waveform();

%Note effects of other cmpnts e.g. coupler and mixer left out
antElmnt = phased.IsotropicAntennaElement('BackBaffled',true);
Ne = 4; % uRAD has 4 x4 elements
rxArray = phased.ULA('Element',antElmnt, ...
    'NumElements',Ne, ...
    'ElementSpacing',lambda/2);

hpbw = beamwidth(rxArray,fc,'PropagationSpeed',c);

% antAperture = 6.06e-4;                        % Antenna aperture (m^2)
% phased array aperture unknown, but gain is known

%antGain = aperture2gain(antAperture,lambda);  % Antenna gain (dB)
antGain = 16.6; % (dB)

txPkPower = 0.1; % (W) from 20 dBm
%txPkPower = db2pow(5)*1e-3;                   % Tx peak power (W)

% Why tx gain 2 x ant gain?
txGain = 2*antGain;                             % Tx antenna gain (dB)

rxGain = antGain;                             % Rx antenna gain (dB)
rxNF = 4.5;                                   % Receiver noise figure (dB)

transmitter = phased.Transmitter('PeakPower',txPkPower,'Gain',txGain);
radiator = phased.Radiator('Sensor',antElmnt,'OperatingFrequency',fc);
collector = phased.Collector('Sensor',rxArray,'OperatingFrequency',fc);

receiver = phased.ReceiverPreamp('Gain',rxGain,'NoiseFigure',rxNF,'SampleRate',fs);
radar = radarTransceiver('Waveform',waveform,'Transmitter',transmitter,...
    'TransmitAntenna',radiator,'ReceiveAntenna',collector,'Receiver',receiver);

% Plots
sig2 = step(waveform);
windowlength = 32;
noverlap = 16;
nfft = 32;
spectrogram(sig2,windowlength,noverlap,nfft,waveform.SampleRate,'yaxis')
%Plot FMCW
subplot(211);plot(real(sig)) % plot(0:1/fs:tm-1/fs,real(sig));
xlabel('Time (s)'); ylabel('Amplitude (v)');
title('FMCW signal'); %axis tight;


subplot(212); spectrogram(sig,32,16,32,fs,'yaxis');
axis([0 5 0 100])
title('FMCW signal spectrogram');