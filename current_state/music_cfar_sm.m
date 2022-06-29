%% Radar Parameters
fc = 24.005e9;%77e9;
%c = physconst('LightSpeed');
c = 3e8;
lambda = c/fc;
%range_max = 200;
range_max = 62.5;
%tm = 2e-3;
tm = 1e-3;
% range_res = 1;
% bw = rangeres2bw(range_res,c);
bw = 240e6;
sweep_slope = bw/tm;

fr_max = range2beat(range_max,sweep_slope,c);
v_max = 230*1000/3600;
fd_max = speed2dop(2*v_max,lambda);
fb_max = fr_max+fd_max;
fs_wav = max(2*fb_max,bw);
%fs_wav = 200e3; % kills range est
rng(2012);
waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs_wav, 'SweepDirection','Triangle');
close all
figure
sig = waveform();
subplot(211); plot(0:1/fs_wav:tm-1/fs_wav,real(sig));
xlabel('Time (s)'); ylabel('Amplitude (v)');
title('FMCW signal'); axis tight;
subplot(212); spectrogram(sig,32,16,32,fs_wav,'yaxis');
title('FMCW signal spectrogram');

%%

ant_aperture = 6.06e-4;                         % in square meter
ant_gain = aperture2gain(ant_aperture,lambda);  % in dB

tx_ppower = db2pow(5)*1e-3;                     % in watts
tx_gain = 9+ant_gain;                           % in dB

rx_gain = 15+ant_gain;                          % in dB
rx_nf = 4.5;                                    % in dB

transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs_wav);

%% Scenario
car_dist = 50;
car_speed = 80/3.6;
car_rcs = db2pow(min(10*log10(car_dist)+5,20));

cartarget = phased.RadarTarget('MeanRCS',car_rcs,'PropagationSpeed',c,...
    'OperatingFrequency',fc);

carmotion = phased.Platform('InitialPosition',[car_dist;0;0.5],...
    'Velocity',[-car_speed;0;0]);

channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs_wav,'TwoWayPropagation',true);

radar_speed = 0;
radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);
%% CFAR
n_samples = 200; % samples per sweep
trn = 20;
grd = 4;
Pfa = 0.0010;
n_fft = n_samples;
fs = 200e3;
f = f_ax(n_fft, fs);

%% Simulation Loop
close all

t_total = 1;
t_step = 0.05;
Nsweep = 2; % up and down
n_steps = t_total/t_step;
fs_adc = 200e3;% 2fbmax
Dn = fix(fs_wav/fs_adc);


[rdr_pos,rdr_vel] = radarmotion(1);
fbu = zeros(n_steps, 1);
fbd = zeros(n_steps, 1);
r = zeros(n_steps, 1);
v = zeros(n_steps, 1);

fbucf = zeros(n_steps, 1);
fbdcf = zeros(n_steps, 1);
rcf = zeros(n_steps, 1);
vcf = zeros(n_steps, 1);

fb_cf = zeros(n_steps,2);
xr_d = zeros(n_samples, 2);

for t = 1:n_steps
    [tgt_pos,tgt_vel] = carmotion(t_step);
   
    xr = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
        transmitter,channel,cartarget,receiver);

    xr_d(:,1) = decimate(xr(:,1),Dn);%,'FIR');
    xr_d(:,2) = decimate(xr(:,2),Dn);

    [fft_up, fft_dw, up_det, dw_det] = CFAR(trn, grd, ...
    Pfa, xr_d(:,1).', xr_d(:,2).', n_fft);

    fft_up_pks = abs(fft_up).*up_det';
    fft_dw_pks = abs(fft_dw).*dw_det';
    
    fft_up_pks(:,98:104) = 0;
    fft_dw_pks(:,98:104) = 0;
    
    [highest_SNR_up, pk_idx_up]= max(fft_up_pks, [],2);
    [highest_SNR_down, pk_idx_down] = max(fft_dw_pks,[],2);
    
    fb_cf(:, 1) = f(pk_idx_up);
    fb_cf(:, 2) = f(pk_idx_down);

    rcf(t) = beat2range([fb_cf(:, 1) fb_cf(:, 2)],sweep_slope,c);
    fd = -(fb_cf(:, 1)+fb_cf(:, 2))/2;
    vcf(t) = dop2speed(fd,lambda)/2;
    fbucf(t) = fb_cf(:, 1);
    fbdcf(t) = fb_cf(:, 2);

    % high sampling
%     fbu_rng = rootmusic(xr(:,1),1,fs_wav);
%     fbd_rng = rootmusic(xr(:,2),1,fs_wav);
   
    % sampling at 2fbmax
    fbu_rng = rootmusic(xr_d(:,1),1,fs_adc);
    fbd_rng = rootmusic(xr_d(:,2),1,fs_adc);

    r(t) = beat2range([fbu_rng fbd_rng],sweep_slope,c);
    
    fd = -(fbu_rng+fbd_rng)/2;
    v(t) = dop2speed(fd,lambda)/2;
    fbu(t) = fbu_rng;
    fbd(t) = fbd_rng;
end

%%
XRu = fftshift(fft(xr(:,1)));
XRd = fftshift(fft(xr(:,2)));

XR_Du = fftshift(fft(xr_d(:,1)));
XR_Dd = fftshift(fft(xr_d(:,2)));

% XRu = fft(xr(:,1));
% XRd = fft(xr(:,2));
% 
% XR_Du = fft(xr_d(:,1));
% XR_Dd = fft(xr_d(:,2));
%% Plot FFT of received wave before and after sampling
f1 = f_ax(length(xr), fs_wav);
f2 = f_ax(n_samples, fs_adc);
close all
figure
tiledlayout(4,1)
nexttile
plot(f1/1e6, abs(XRu))
nexttile
plot(f1/1e6, abs(XRd))

nexttile
plot(f2/1000,abs(XR_Du))
nexttile
plot(f2/1000,abs(XR_Dd))


%% Plot received wave before and after sampling
close all
figure
tiledlayout(4,1)
nexttile
plot(real(xr(:, 1)))
nexttile
plot(real(xr(:,2)))
nexttile
plot(real(xr_d(:, 1)))
nexttile
plot(real(xr_d(:,2)))


% nexttile
% plot(real(xr(:, 1)))
% nexttile
% plot(real(xr(:,2)))


%     % issue: helper updates target position and velocity within each
%     sweep. Resolved --> issue was releasing waveforms?



