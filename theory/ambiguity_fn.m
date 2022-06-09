% NOTE: for FMCW signals, a periodic ambiguity function is needed
% compare the periodic to the normal 
% normally, ambiguity function represents the output of the matched filter 
% for a specific waveform at the input. This would require a matched filter
% based on the reference wave
% For FMCW, matched filter is not used, though the downconversion using a
% mixer works similarly 
%% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
sweep_slope = bw/tm;
fs = 240e6;

wf_obj = phased.FMCWWaveform('SweepTime',tm, ...
    'SweepBandwidth',bw, ...
    'SampleRate',fs, ...
    'SweepDirection','Triangle', ...
    'NumSweeps',2); % may need to remove num sweeps

wf = wf_obj();
%PRF = 1e-3; % 2 ms
%PRF = wf_obj.PRF;
Fs = wf_obj.SampleRate;%200e3; 
% twice max beat freq. The fs above allows for simulation of
% the waveform, though processing is done on a downconverted signal

% needs PRF which is for pulsed radar
%AF = ambgfun(wf, Fs, PRF);

PAF = pambgfun(wf,fs);
PAF

%% Plots
close all
figure
subplot(211); 
plot(real(wf));
xlabel('Time (s)'); 
ylabel('Amplitude (v)');
title('FMCW signal'); 
axis tight;
subplot(212); 
spectrogram(wf,32,16,32,fs,'yaxis');
title('FMCW signal spectrogram');




