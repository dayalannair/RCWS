sweeps = 200:205;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(sweeps);
n_samples = size(iq_u,2);
n_sweeps = size(iq_u, 1);
%% 1. CFAR
trn = 20;
grd = 4;
Pfa = 0.0010;
n_fft = n_samples;
fs = 200e3;
f = f_ax(n_fft, fs);

[fft_up, fft_dw, up_det, dw_det] = CFAR(trn, grd, ...
    Pfa, iq_u, iq_d, n_fft);

fft_up_pks = abs(fft_up).*up_det';
fft_dw_pks = abs(fft_dw).*dw_det';
fb_cf = zeros(n_sweeps,2);

fft_up_pks(:,98:104) = 0;
fft_dw_pks(:,98:104) = 0;

[highest_SNR_up, pk_idx_up]= max(fft_up_pks, [],2);
[highest_SNR_down, pk_idx_down] = max(fft_dw_pks,[],2);

fb_cf(:, 1) = f(pk_idx_up);
fb_cf(:, 2) = f(pk_idx_down);
%%
close all
figure
tiledlayout(2,1)
nexttile
plot(f, fft_up_pks)
nexttile
plot(f, fft_dw_pks)

%% root-MUSIC


% subpspace dimension = number of sweeps
fb_rm_a = zeros(n_sweeps,2);
fb_rm_b = zeros(n_sweeps,2);

fb_rm_a(:, 1) = rootmusic(iq_u,n_sweeps,fs);
fb_rm_a(:, 2) = rootmusic(iq_d,n_sweeps,fs);

% loop over sweeps with subspace dim = 1
for i = 1:n_sweeps
    fb_rm_b(i, 1) = rootmusic(iq_u(i,:),1,fs);
    fb_rm_b(i, 2) = rootmusic(iq_d(i,:),1,fs);
end

% CONCLUSION: signal subspace dimension is NOT
% the number of sweeps... need to figure it out
% Also, need to find out why rootmusic != cfar

% If the input signal x is real, and an odd number of sinusoids
% is specified by p, an error message is displayed:
% Real signals require an even number p of complex sinusoids.

% This seems to indicate that the subspace dimension is the number
% of sinusoids to detect... we should expect to see only one which
% is the beat frequency (complex so one sided)

% rootmusic is most useful for frequency estimation of signals made up 
% of a sum of sinusoids embedded in additive white Gaussian noise.



