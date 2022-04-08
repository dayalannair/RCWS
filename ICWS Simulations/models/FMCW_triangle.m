
fc = 24e9;                                  % Center frequency 24 GHz
c = physconst('LightSpeed');
bw = 240e6;


vMax = 75;                    % Maximum Velocity of cars (m/s)
fdopMax = speed2dop(2*vMax,lambda);      % Maximum Doppler shift (Hz)

fifMax = fbeatMax+fdopMax;   % Maximum received IF (Hz)
fs = max(2*fifMax,bw);       % Sampling rate (Hz)

wave = phased.FMCWWaveform("SampleRate")