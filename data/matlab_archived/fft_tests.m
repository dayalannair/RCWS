iq_tbl=readtable('IQ_0_1024_sweeps.txt','Delimiter' ,' ');
time = iq_tbl.Var801;
i_up = table2array(iq_tbl(:,1:200));
i_down = table2array(iq_tbl(:,201:400));
q_up = table2array(iq_tbl(:,401:600));
q_down = table2array(iq_tbl(:,601:800));

iq_up = i_up + 1i*q_up;
iq_down = i_down + 1i*q_down;
%% FFT
n_fft = 2048;
IQ_UP = fftshift(fft(iq_up,n_fft,2));
IQ_DOWN = fftshift(fft(iq_down,n_fft,2));
IQ_UP_peaks(:,98:104) = 0;
IQ_DOWN_peaks(:,98:104) = 0;
n_samples = size(IQ_UP, 2);
fs = 200e3; %200 kHz
f = f_ax(n_fft, fs);

%%
close all 
tiledlayout(2, 1);
nexttile
plot(f/1000, 10*log10(abs(IQ_UP)));
%axis([-100 100 0 0.5e5])
nexttile
plot(f/1000, abs(IQ_DOWN));
axis([-100 100 0 0.5e5])