
t_total = 3.7;
t_step = 0.05;% 100 ms - updates 10 times per second
Nsweep = 1; % Number of ups and downs, not number of periods
n_steps = t_total/t_step;

t_ax = linspace(0,t_total,n_steps);

% Set up arrays for two targets
fbu = NaN(n_steps, 2);
fbd = NaN(n_steps, 2);
r = NaN(n_steps, 2);
v = NaN(n_steps, 2);

Dn = fix(fs_wav/fs_adc);
Ns = 200;
nfft = 1024;
% faxis_kHz = f_ax(nfft, fs_adc)/1000;
n_fft = 1024;
train = 16;%n_fft/8;%64;
guard = 14;%n_fft/64;%8;
rank = round(3*train/4);
nbar = 3;
sll = -150;
F = 3*10e-3;
v_max = 60/3.6; 
fd_max = speed2dop(v_max, lambda)*2;
% Minimum sample number for 1024 point FFT corresponding to min range = 10m
% n_min = 83;
% for 512 point FFT:
n_min = 42;
% Divide into range bins of width 64
% bin_width = (n_fft/2)/nbins;
% nbins = 8;
% bin_width = 32; % account for scan width = 21
% scan_width = 21; % see calcs: Delta f * 21 ~ 8 kHz

nbins = 16;
bin_width = 32; % account for scan width = 21
scan_width = 32;

calib = 1.2463;
lhs_road_width = 3.3;
rhs_road_width = 1.1;

% Taylor window
win = taylorwin(Ns, nbar, sll);
% win = hanning(Ns);
% win = hamming(Ns);
% wind = taylorwin(n_samples, nbar, sll);
% Gaussian
% win = gausswin(n_samples);
% Blackmann 
% bwin = blackman(Ns);
% % Kaiser
% kbeta = 5;
% win = kaiser(n_samples, kbeta);

fs = 200e3;
f = f_ax(n_fft, fs);
f_neg = flip(-f(1:n_fft/2),2);
f_pos = f((n_fft/2 + 1):end);
% freqkHz = linspace(0, 100000, 256);

% Range axis
rng_ax = beat2range((f_pos)', sweep_slope, c);

OS1 = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',rank);

OS2 = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',rank);

f_bin_edges_idx = size(f_pos(),2)/nbins;
prev_det = 0;

fb_idx1 = NaN(nbins,1);
fb_idx2 = NaN(nbins,1);
fb_idx_end1 = NaN(nbins,1);
fb_idx_end2 = NaN(nbins,1);
ax_dims = [0 max(rng_ax) -140 -10];
ax_ticks = 1:2:60;
nswp1  = n_steps;

fbu1   = NaN(nswp1, nbins);
fbd1   = NaN(nswp1, nbins);
fdMtx1 = NaN(nswp1, nbins);
rgMtx1 = NaN(nswp1, nbins);
spMtx1 = NaN(nswp1, nbins);
safety = NaN(nswp1, 1);
actual_rng = NaN(nswp1, nbins);
actual_spd = NaN(nswp1, nbins);

beat_count_out1 = NaN(1,256);
beat_count_out2 = NaN(1,256);
beat_count_in1 = NaN(1,256);
beat_count_in2 = NaN(1,256);

% IQ_UP = NaN(nswp1, 512);
% IQ_DN = NaN(nswp1, 512);
% upTh1 = NaN(nswp1, 512);
% dnTh1 = NaN(nswp1, 512);

IQ_UP = NaN(1, nfft);
IQ_DN = NaN(1, nfft);
upTh1 = NaN(nfft, 1);
dnTh1 = NaN(nfft, 1);

BIN_MAG = -60;

nul_width_factor = 0.04;
num_nul1 = round((n_fft/2)*nul_width_factor);



