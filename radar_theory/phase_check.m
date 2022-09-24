% first portion 60 kmh
subset = 1050:1100;

addpath('../../../matlab_lib/');
addpath('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);

n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);

hmwin = hamming(n_samples);
iq_u = iq_u.*hmwin.';

IQ_UP = fft(iq_u,n_fft,2);
IQ_DN = fft(iq_d,n_fft,2);

close all
figure
tiledlayout(2, 1)
nexttile
plot(sftmagdb(IQ_UP(1,:)))
nexttile
plot(angle(fftshift(IQ_UP(1,:))))
