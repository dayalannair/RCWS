% Set random number generator for repeatable results
rng(2017);

% Compute hardware parameters from specified long-range requirements
fc = 24e9;                                  % Center frequency 24 GHz
c = physconst('LightSpeed');                % Speed of light in air (m/s)
lambda = freq2wavelen(fc,c);                              % Wavelength (m)

% Set the chirp duration to be 5 times the max range requirement
rangeMax = 75;                             % Maximum range (m) for car RCS
tm = 5*range2time(rangeMax,c);              % Chirp duration (s) converted to FMCW


% Determine the waveform bandwidth from the required range resolution
rangeRes = 1.5;                               % Desired range resolution (m)
% for uRAD: 1.5m or different velocity in modes 3 & 4

bw = rangeres2bw(rangeRes,c);               % Corresponding bandwidth (Hz)
% BW should be 240 MHz, however the equation above results in 100 MHz
% Setting BW as in uRAD spec, need TO CHECK ON THIS!
% may be that the 1.5 m resolution is the real/measured resolution which
% will deviate/be larger than the theoretical one calculated above

% BW = c/2deltaR
% In sim, use only theoretical values! can leave range res as 1.5m
%bw = 240e6;
% error - set range res s.t. BW = 240 MHz


% Set the sampling rate to satisfy both the range and velocity requirements
% for the radar
sweepSlope = bw/tm;                           % FMCW sweep slope (Hz/s)
fbeatMax = range2beat(rangeMax,sweepSlope,c); % Maximum beat frequency (Hz)

vMax = 75;                    % Maximum Velocity of cars (m/s)
fdopMax = speed2dop(2*vMax,lambda);      % Maximum Doppler shift (Hz)

fifMax = fbeatMax+fdopMax;   % Maximum received IF (Hz)
fs = max(2*fifMax,bw);       % Sampling rate (Hz)


%% FMCW WAVEFORM
% Configure the FMCW waveform using the waveform parameters derived from
% the long-range requirements
% create an FMCW waveform object
waveform = phased.FMCWWaveform('SweepTime',tm, ...
    'SweepBandwidth',bw, ...
    'SampleRate',fs, ...
    'SweepDirection','Triangle');%, ...
    %'NumSweeps',2);

% strcmp - compare strings 
if strcmp(waveform.SweepDirection,'Down')
    %if sweep direction is 'down', invert slope
    sweepSlope = -sweepSlope;
end

sig = waveform();

%% Get wave for FERS
plot(real(sig));

I = real(sig);  
Q = imag(sig);  
hdf5write('triangle.h5', '/I/value', I, '/Q/value', Q);  
%% MODEL TRANSCEIVER
% Model the antenna element - NEED TO CREATE CUSTOM ELEMENT FOR URAD
% backbaffle - antenna response for >+-90 deg i.e. behind antenna
antElmnt = phased.IsotropicAntennaElement('BackBaffled',true);

% Construct the receive array
Ne = 4; % uRAD has 4 x4 elements
rxArray = phased.ULA('Element',antElmnt, ...
    'NumElements',Ne, ...
    'ElementSpacing',lambda/2);

% Half-power beamwidth of the receive array
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

% Waveform transmitter
transmitter = phased.Transmitter('PeakPower',txPkPower,'Gain',txGain);

% Radiator for single transmit element
% narrow band signal radiator object
radiator = phased.Radiator('Sensor',antElmnt,'OperatingFrequency',fc);

% Collector for receive array
% narrow band collector
collector = phased.Collector('Sensor',rxArray,'OperatingFrequency',fc);

% Receiver preamplifier
receiver = phased.ReceiverPreamp('Gain',rxGain,'NoiseFigure',rxNF,'SampleRate',fs);

% Define radar
radar = radarTransceiver('Waveform',waveform,'Transmitter',transmitter,...
    'TransmitAntenna',radiator,'ReceiveAntenna',collector,'Receiver',receiver);

% Plots
% sig2 = step(waveform);
% windowlength = 32;
% noverlap = 16;
% nfft = 32;
% spectrogram(sig2,windowlength,noverlap,nfft,waveform.SampleRate,'yaxis')
%Plot FMCW
% subplot(211);plot(real(sig)) % plot(0:1/fs:tm-1/fs,real(sig));
% xlabel('Time (s)'); ylabel('Amplitude (v)');
% title('FMCW signal'); %axis tight;
% 
% 
% subplot(212); %plot(real(fft(sig)))%spectrogram(sig,32,16,32,fs,'yaxis');
% %axis([0 5 0 100])
% title('FMCW signal spectrogram');