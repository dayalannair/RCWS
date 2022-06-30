sweeps = 1:1024;% 200:205;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(sweeps);
%F = 0.015; % see relevant papers


n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);

%%
nfft = 256;
fs = 200e3;
f = f_ax(nfft, fs);
f = f/1000;

u = iq_u(200,:).';
gwin = gausswin(n_samples);
uwin = u.*gwin;
UWIN = fft(uwin, nfft);
U = fft(u, nfft);

close all
figure
plot(f, 10*log10(fftshift(abs(UWIN))), 'DisplayName','Gaussian Window')
title("Effect of windowing on signal spectrum for 1024 point FFT")
ylabel("Magnitude (dB)")
xlabel("Freqeuncy (kHz)")
hold on
plot(f, 10*log10(fftshift(abs(U))),'DisplayName','No Window')
legend

% NOTES: Does not seem to improve much after 1024 point fft


% plot(real(uwin))