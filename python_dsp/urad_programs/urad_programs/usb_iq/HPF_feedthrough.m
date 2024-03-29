function Hd = HPF_feedthrough
%HPF_FEEDTHROUGH Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 9.12 and DSP System Toolbox 9.14.
% Generated on: 23-Apr-2022 10:30:09

% Equiripple Highpass filter designed using the FIRPM function.

% All frequency values are in kHz.
Fs = 200;  % Sampling Frequency

Fstop = 2;               % Stopband Frequency
Fpass = 3;               % Passband Frequency
Dstop = 0.0001;          % Stopband Attenuation
Dpass = 0.057501127785;  % Passband Ripple
dens  = 20;              % Density Factor

% Calculate the order from the parameters using FIRPMORD.
[N, Fo, Ao, W] = firpmord([Fstop, Fpass]/(Fs/2), [0 1], [Dstop, Dpass]);

% Calculate the coefficients using the FIRPM function.
b  = firpm(N, Fo, Ao, W, {dens});
Hd = dfilt.dffir(b);

% [EOF]
