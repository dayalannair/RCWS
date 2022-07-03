sweeps = 1:1024;% 200:205;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(sweeps);
%F = 0.015; % see relevant papers


n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);

%%
u = iq_u(200,:).';
% Gaussian
gwin = gausswin(n_samples);
% Blackmann 
% See sflag 'periodic' option
bwin = blackman(n_samples);
% Kaiser
% See shape factor
kwin = kaiser(n_samples);
% Nuttall's Blackman-Harris
% See sflag 'periodic' option
nbhwin = nuttallwin(n_samples);
% Hamming
% See sflag 'periodic' option
hmwin = hamming(n_samples);
% Hanning
hnwin = hann(n_samples);

uwing = u.*gwin;
uwinb = u.*bwin;
uwink = u.*kwin;
uwinnbh = u.*nbhwin;
uwinhm = u.*hmwin;
uwinhn = u.*hnwin;

uwins = [uwing, uwinb, uwink, uwinnbh, uwinhm, uwinhn];

nfft = 1024;
fs = 200e3;
f = f_ax(nfft, fs);
f = f/1000;
UWIN = fft(uwins, nfft);
U = fft(u, nfft);
 close all
figure
plot(f, 10*log10(fftshift(abs(U))), 'DisplayName','No Window')
title("Effect of windowing on signal spectrum for 1024 point FFT")
ylabel("Magnitude (dB)")
xlabel("Freqeuncy (kHz)")
hold on
plot(f, 10*log10(fftshift(abs(UWIN(:,1)))),'DisplayName','Guassian Window')
hold on
plot(f, 10*log10(fftshift(abs(UWIN(:,2)))),'DisplayName','Blackmann Window')
hold on
plot(f, 10*log10(fftshift(abs(UWIN(:,3)))),'DisplayName','Kaiser Window')
hold on
plot(f, 10*log10(fftshift(abs(UWIN(:,4)))),'DisplayName','Nutall Window')
hold on
plot(f, 10*log10(fftshift(abs(UWIN(:,5)))),'DisplayName','Hamming Window')
hold on
plot(f, 10*log10(fftshift(abs(UWIN(:,6)))),'DisplayName','Hanning Window')
legend


% close all
% figure
% plot(f, 10*log10(fftshift(abs(UWIN))), 'DisplayName','Gaussian Window')
% title("Effect of windowing on signal spectrum for 1024 point FFT")
% ylabel("Magnitude (dB)")
% xlabel("Freqeuncy (kHz)")
% hold on
% plot(f, 10*log10(fftshift(abs(U))),'DisplayName','No Window')
% legend

% NOTES: Does not seem to improve much after 1024 point fft


% plot(real(uwin))