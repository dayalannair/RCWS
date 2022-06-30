sweeps = 200:205;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(sweeps);
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);
trn = 20;
grd = 4;
Pfa = 0.015;
n_fft = n_samples;
[fft_up, fft_dw, up_det, dw_det, detu, detd] = myCFAR(trn, grd, ...
    Pfa, iq_u, iq_d, n_fft);
fs = 200e3; %200 kHz
f = f_ax(n_fft, fs);
[usim, dsim] = generate_sm_data();
%%
A = rescale(real(iq_u(2, :)));
B = rescale(real(iq_d(2, :)));
C = rescale(real(usim(2, :)));
D = rescale(real(dsim(2, :)));

close all
figure
tiledlayout(2,1)
nexttile
plot(A);
hold on
plot(C);
nexttile
plot(B)
hold on
plot(D)

%%

usmftt = fftshift(fft(usim,[],2));
dsmftt = fftshift(fft(dsim,[],2));

A = rescale(abs(fft_up(2, :)));
B = rescale(abs(fft_dw(2, :)));
C = rescale(abs(usmftt(2, :)));
D = rescale(abs(dsmftt(2, :)));

close all
figure
tiledlayout(2,1)
nexttile
plot(A);
hold on
plot(C);
nexttile
plot(B)
hold on
plot(D)
%% 
close all
figure
tiledlayout(2,1)
nexttile
plot(real(usim(2,:)))
nexttile
plot(real(dsim(2,:)))














%%
close all
figure
tiledlayout(2,1)
nexttile
stem(f, detu')% not sure why transpose is needed
hold on
plot(f, abs(fft_up))
nexttile
stem(f, detd')
hold on
plot(f, abs(fft_dw))