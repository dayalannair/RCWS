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
%%

fb_rm = zeros(n_sweeps,2);
for i = 1:n_sweeps
    a = rootmusic(iq_u(i,:),2,fs);
    b = rootmusic(iq_d(i,:),2,fs);
    fb_rm(i, 1) = a(2);
    fb_rm(i, 2) = b(2);
end

%% Periodogram
periodogram(iq_u.', [], [], fs, 'centered');
hold on
periodogram(iq_d.', [], [], fs, 'centered');
% [pdg,~] = periodogram(iq_u.', [],[],fs);
% 
% close all
% figure
% plot(pdg)
%% Quick plot
% close all
% figure
% tiledlayout(2,1)
% nexttile
% plot(real(iq_u)')
% nexttile
% plot(real(iq_d)')
% 
% fft_up(:,98:104) = 0;
% fft_dw(:,98:104) = 0;
% 
% close all
% figure
% tiledlayout(2,1)
% nexttile
% plot(f/1000, abs(fft_up))
% nexttile
% plot(f/1000, abs(fft_dw))


%% Result comparison
%fd_max = speed2dop(v_max, lambda)*2;
% fd_max = 100e3;
% 
% fd_cf = -fb_cf(:,1)-fb_cf(:,2);
% 
% dop_cf = fd_rm/2;
% spd_cf = dop2speed(fd_cf/2,lambda)/2;
% rng_cf = beat2range([fb_cf(:,1) fb_cf(:,2)], k, c);
% 
% 
% fd_rm = -fb_rm(:,1)-fb_rm(:,2);
% 
% 
% dop_rm = fd_rm/2;
% spd_rm = dop2speed(fd_rm/2,lambda)/2;
% rng_rm = beat2range([fb_rm(:,1) fb_rm(:,2)], k, c);


%%
% t0 = t_stamps(1);
% t = t_stamps - t0;
% close all
% figure('WindowState','maximized');
% movegui('east')
% tiledlayout(2,1)
% nexttile
% plot(rng_rm)
% title('Range estimations of APPROACHING targets')
% xlabel('Time (seconds)')
% ylabel('Range (m)')
% hold on
% plot(rng_cf)
% nexttile
% plot(spd_rm*3.6*5e2)
% title('Radial speed estimations of APPROACHING targets')
% xlabel('Time (seconds)')
% ylabel('Speed (km/h)')
% hold on
% plot(spd_cf*3.6)
% 
% % pass FFT to root MUSIC
% % ofcourse, incorrect
% %rm_u =  rootmusic(fft_up(1,:),1,fs);
% %%
% beat=10e3;
% total_t = 1e-3;
% delta_t = 5e-6;
% t = 0:delta_t:(total_t-delta_t);
% x = sin(2*pi*beat*t);
% close all
% figure 
% plot(x)
% tic
% msc = rootmusic(x, 2, fs);
% toc
% 
% X = fft(x);
% Get runtime of CFAR




%%
% convert unsigned data to signed by centering on zero
% CONCLUSION: only the DC frequency component changes
% sweep = 200;
% iq_tbl=readtable('trig_fmcw_data\IQ_0_1024_sweeps.txt','Delimiter' ,' ');
% t_stamps = iq_tbl.Var801;
% i_up = table2array(iq_tbl(sweep,1:200));
% i_down = table2array(iq_tbl(sweep,201:400));
% q_up = table2array(iq_tbl(sweep,401:600));
% q_down = table2array(iq_tbl(sweep,601:800));
% 
% iqu = i_up + 1i*q_up;
% iqd = i_down+1i*q_down;

% IQU1 = fft(iqu);
% IQD1 = fft(iqd);
% close all
% figure
% tiledlayout(4,1)
% nexttile
% plot(i_up)
% nexttile
% plot(i_down)
% nexttile
% plot(q_up)
% nexttile
% plot(q_down)
%% 
% i_up = i_up - 4096/2;
% i_down = i_down - 4096/2;
% q_up = q_up - 4096/2;
% q_down = q_down - 4096/2;
% 
% close all
% figure
% tiledlayout(4,1)
% nexttile
% plot(i_up)
% nexttile
% plot(i_down)
% nexttile
% plot(q_up)
% nexttile
% plot(q_down)
%% FFT

% iqu = i_up + 1i*q_up;
% iqd = i_down+1i*q_down;
% 
% IQU = fft(iqu);
% IQD = fft(iqd);
% 
% close all
% figure
% tiledlayout(2,1)
% nexttile
% plot(f, 10*log10(abs(fftshift(IQU))))
% hold on
% plot(f, 10*log10(abs(fftshift(IQU1))))
% nexttile
% plot(f, 10*log10(abs(fftshift(IQD))))
% hold on
% plot(f, 10*log10(abs(fftshift(IQD1))))
% nexttile
% plot(f, 10*log10(abs(fftshift(IQU1))))
% nexttile
% plot(f, 10*log10(abs(fftshift(IQD1))))

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



