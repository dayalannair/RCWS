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
nbar = 3;
sll = -50;
twin = taylorwin(n_samples, nbar, sll);
% Gaussian
gwin = gausswin(n_samples);
% Blackmann 
% See sflag 'periodic' option
bwin = blackman(n_samples);
% Kaiser
% See shape factor
kbeta = 2.5;
kwin = kaiser(n_samples, kbeta);
% Nuttall's Blackman-Harris
% See sflag 'periodic' option
nbhwin = nuttallwin(n_samples);
% Hamming
% See sflag 'periodic' option
hmwin = hamming(n_samples);
% Hanning
hnwin = hann(n_samples);
% rwin = ones(n_samples, 1);
rwin = rectwin(n_samples);
wins = cat(2, rwin, twin, gwin, bwin, kwin, nbhwin, hmwin, hnwin);
% wins = cat(2, rwin, twin, bwin, kwin, hnwin);
% return

nfft = 1024;
fs = 200e3;
f = f_ax(nfft, fs);
% f = f/1000

[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = ...
    import_data(sweeps, rwin.');
rngAx = beat2range(f.', k, c);
FFTS = zeros(nfft, 8);
FFTSdbsft = zeros(nfft, 8);
data = iq_u(116, :).';
for i = 1:8
    win = wins(:, i);
    FFTS(:, i) = fft(data.*win, nfft, 1);
    FFTSdbsft(:, i) = sftmagdb(FFTS(:, i));
    max_arr = max(FFTSdbsft(:, i));
    FFTSdbsft(:, i) = FFTSdbsft(:, i) - max_arr;
end

% test = fft(data, nfft, 1);
% FFTS(:,1)-test
% % test-test
% test = mag2db(fftshift(abs(test)))
% %%
% 
% test - FFTSdbsft(:,1)
% return
% max_arr = max(FFTSdbsft);
% FFTSdbsft = FFTSdbsft - max_arr;
%%
close all
figure
set(gcf,'color','w');
% plot(f, U))), 'DisplayName','Rectangular')
% title("Effect of windowing on signal spectrum for 1024 point FFT",'FontSize', 12)
 grid on
% wins = cat(2, rwin, twin, gwin, bwin, kwin, nbhwin, hmwin, hnwin);
plot(rngAx.', FFTSdbsft(:,1),'DisplayName','Rectangular');
ylabel("Normalised Magnitude (dB)", 'FontSize', 14)
xlabel("Freqeuncy (kHz)", 'FontSize', 14)
% axis([38, 65, -65, 20])
axis([24, 33, -65, -10])
ax = gca; 
ax.FontSize = 14; 

hold on
plot(rngAx.', FFTSdbsft(:,2),'DisplayName','Taylor, nbar=3, sll=50 dB');
 grid on
% % hold on
% % plot(rngAx, FFTSdbsft(:,3),'DisplayName','Gaussian');
% hold on
plot(rngAx.', FFTSdbsft(:,4),'DisplayName','Blackman');
 grid on
plot(rngAx.', FFTSdbsft(:,5),'DisplayName','Kaiser, \beta = 2.5');
 grid on
% % hold on
% % plot(rngAx, FFTSdbsft(:,6),'DisplayName','Nuttall');
% % hold on
% % plot(rngAx, FFTSdbsft(:,7),'DisplayName','Hamming');
% hold on
plot(rngAx.', FFTSdbsft(:,8),'DisplayName','Hanning');
legend('FontSize', 13)
 grid on
hold off

% legend({''})
% legend([p1,p2,p3,p4,p5)
% legend([p1,p2,p3,p4,p5],'FontSize', 16)


% close all
% figure
% plot(f, FFTS))), 'DisplayName','Gaussian')
% title("Effect of windowing on signal spectrum for 1024 point FFT")
% ylabel("Magnitude (dB)")
% xlabel("Freqeuncy (kHz)")
% hold on
% plot(f, U))),'DisplayName','No')
% legend
%%
% NOTES: Does not seem to improve much after 1024 point fft
% x = sftmagdb(fft(iq_u(116,:),nfft,2));
% 
% 
% close all
% plot(x)

% plot(real(FFTS))