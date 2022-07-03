format long g
subset = 200:210;
iq_tbl=readtable('../../data/urad_usb/IQ_sawtooth.txt','Delimiter' ,' ');
i_dat = table2array(iq_tbl(subset,1:200));
q_dat = table2array(iq_tbl(subset,201:400));
iq = i_dat + 1i*q_dat;
%%

n_samples = size(i_dat,2);
n_sweeps = size(i_dat,1);
time = iq_tbl.Var401;
t0 = time(1);
t_sweeps = time - t0;
periods = diff(t_sweeps);
avg_period = mean(periods);

t = zeros(n_sweeps, n_samples);
for i = length(t)
    t(i,:) = linspace(t_sweeps(i),t_sweeps(i+1), n_samples);
end
%%
close all
figure
tiledlayout(3,1)
nexttile
plot(t',i_dat')
title("Sawtooth I data")
nexttile
plot(t', q_dat')
title("Sawtooth Q data")
nexttile
plot(real(iq.'))
title("Sawtooth IQ data")

%%
IQ = fft(iq, [], 2);
fs = 200e3;
f = f_ax(200, fs)/1000;

close all
figure
tiledlayout(2,1)
nexttile
plot(f, 20*log10(fftshift(abs(IQ.'))))
title("Sawtooth FFT magnitude")
xlabel("Frequency (kHz)")
ylabel("Magnitude (dB)")
nexttile
plot(f, fftshift(angle(IQ.')))
title("Sawtooth FFT phase")
xlabel("Frequency (kHz)")
%ylabel("Magnitude (dB)")


