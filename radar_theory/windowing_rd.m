sweeps = 800:1200;% 200:205;
addpath('../matlab_lib/');
addpath('../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
% [fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(sweeps);
%F = 0.015; % see relevant papers

% n_samples = size(iq_u,2);
% n_sweeps = size(iq_u,1);

%%
n_samples = 200;
% Taylor
nbar = 4;
sll = -38;
twin = taylorwin(n_samples, nbar, sll);
% Gaussian
gwin = gausswin(n_samples);
% Blackmann 
% See sflag 'periodic' option
bwin = blackman(n_samples);
% Kaiser
% See shape factor
kbeta = 5;
kwin = kaiser(n_samples, kbeta);
% Nuttall's Blackman-Harris
% See sflag 'periodic' option
nbhwin = nuttallwin(n_samples);
% Hamming
% See sflag 'periodic' option
hmwin = hamming(n_samples);
% Hanning
hnwin = hann(n_samples);
rwin = ones(n_samples, 1);
wins = cat(2, rwin, twin, gwin, bwin, kwin, nbhwin, hmwin, hnwin);
% return

nfft = 1024;
fs = 200e3;
f = f_ax(nfft, fs);
f = f/1000;

FFTS = zeros(nfft, 8);
for i = 1:8
    win = wins(:, i);
    [fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = ...
        import_data(sweeps, win.');
    FFTS(:, i) = fft(iq_u(116, :), nfft, 2);
end
%%
FFTSdbsft = sftmagdb(FFTS);
% FFTSdbsft = normalize(FFTSdbsft,2);
%%
close all
figure
% plot(f, U))), 'DisplayName','Rectangular Window')
title("Effect of windowing on signal spectrum for 1024 point FFT")
ylabel("Magnitude (dB)")
xlabel("Freqeuncy (kHz)")

plot(f, FFTSdbsft(:,1),'DisplayName','Guassian Window')
axis([0, max(f), -65, 20])
hold on
plot(f, FFTSdbsft(:,2),'DisplayName','Blackmann Window')
hold on
plot(f, FFTSdbsft(:,3),'DisplayName','Kaiser Window')
hold on
plot(f, FFTSdbsft(:,4),'DisplayName','Nutall Window')
hold on
plot(f, FFTSdbsft(:,5),'DisplayName','Hamming Window')
hold on
plot(f, FFTSdbsft(:,6),'DisplayName','Hanning Window')
hold on
plot(f, FFTSdbsft(:,7),'DisplayName','Taylor Window')
hold on
plot(f, FFTSdbsft(:,8),'DisplayName','Taylor Window')
hold off
legend


% close all
% figure
% plot(f, FFTS))), 'DisplayName','Gaussian Window')
% title("Effect of windowing on signal spectrum for 1024 point FFT")
% ylabel("Magnitude (dB)")
% xlabel("Freqeuncy (kHz)")
% hold on
% plot(f, U))),'DisplayName','No Window')
% legend

% NOTES: Does not seem to improve much after 1024 point fft


% plot(real(FFTS))