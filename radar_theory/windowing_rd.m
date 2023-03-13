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
max_arr = max(FFTSdbsft);
FFTSdbsft = FFTSdbsft - max_arr;
%%
close all
figure
set(gcf,'color','w');
% plot(f, U))), 'DisplayName','Rectangular')
% title("Effect of windowing on signal spectrum for 1024 point FFT",'FontSize', 12)

% wins = cat(2, rwin, twin, gwin, bwin, kwin, nbhwin, hmwin, hnwin);
plot(f, FFTSdbsft(:,1),'DisplayName','Rectangular')
ylabel("Normalised Magnitude (dB)", 'FontSize', 16)
xlabel("Freqeuncy (kHz)", 'FontSize', 16)
axis([38, 65, -65, 20])
ax = gca; 
ax.FontSize = 16; 

hold on
plot(f, FFTSdbsft(:,2),'DisplayName','Taylor')
hold on
plot(f, FFTSdbsft(:,3),'DisplayName','Gaussian')
hold on
plot(f, FFTSdbsft(:,4),'DisplayName','Blackman')
hold on
plot(f, FFTSdbsft(:,5),'DisplayName','Kaiser')
hold on
plot(f, FFTSdbsft(:,6),'DisplayName','Nuttall')
hold on
plot(f, FFTSdbsft(:,7),'DisplayName','Hamming')
hold on
plot(f, FFTSdbsft(:,8),'DisplayName','Hanning')
hold off
legend('FontSize', 16)


% close all
% figure
% plot(f, FFTS))), 'DisplayName','Gaussian')
% title("Effect of windowing on signal spectrum for 1024 point FFT")
% ylabel("Magnitude (dB)")
% xlabel("Freqeuncy (kHz)")
% hold on
% plot(f, U))),'DisplayName','No')
% legend

% NOTES: Does not seem to improve much after 1024 point fft


% plot(real(FFTS))