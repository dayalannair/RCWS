%{
%% Test various FFT lengths on calibrated data
Compute N of a frame of sweeps. Find peaks/detections in each
sweep - taken as max for short range calibration data. Use index of max to
extract beat frequency from up and down spectra. Compute triangle FMCW
range. Store data from each value of N, then plot on a single scatter plot.
%}
% Import data and parameters
subset = 1:2700;
addpath('../matlab_lib/')

addpath(['../../../OneDrive - University of Cape Town/'...
    'RCWS_DATA/calibration'])

Ns = 200;

nbar = 3;
sll = -20;
% win = taylorwin(Ns, nbar, sll);

win =   rectwin(Ns);

[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = ...
    import_data(subset, win.');

n_sweeps = size(iq_u,1);

fs = 200e3;


%% FFT, compute ABS magnitude and 
% FFT - note that true value is normalised by dividing by Ns
n_fft = 256;
n_fft = 512;
% n_fft = 1024;
% n_fft = 2048;
% n_fft = 4096;
% n_fft = 8192;
% n_fft = 16384;
% n_fft = 32768;
n_fft = 65536;

% Create axes
f = f_ax(n_fft, fs);
f_neg_flipped = flip(-f(1:n_fft/2),2);
f_pos = f((n_fft/2 + 1):end);
rngAxPos = c*f_pos/(2*k);
rngAxNeg = c*f_neg_flipped/(2*k);

FFT_U = fft(iq_u,n_fft,2)/Ns;
FFT_D = fft(iq_d,n_fft,2)/Ns;

% Halve FFTs
FFT_U = FFT_U(:, 1:n_fft/2);
FFT_D = FFT_D(:, n_fft/2+1:end);

% Flip negative half of down chirp spectrum
FFT_D = flip(FFT_D,2);

% Abs magnitude in dB
FFT_U = absmagdb(FFT_U);
FFT_D = absmagdb(FFT_D);

%% Compute max of each sweep and store indices

[ ~ , fbuIdx] = max(FFT_U, [], 2);
[ ~ , fbdIdx] = max(FFT_D, [], 2);

%% Extract range measurments
rng_u = rngAxPos(fbuIdx);
rng_d = rngAxNeg(fbdIdx);
% (f_pos(fbuIdx) + f_pos(fbdIdx))/2;
fbu = f_pos(fbuIdx).';
fbd = f_neg_flipped(fbdIdx).';
fbAvg = (fbu + fbd)/2;
rngMtFn = beat2range([fbu, -fbd], k, c);

% rngEqn = beat2range(fbAvg, k, c);
rngEqn = c*fbAvg/(2*k);
% cor = corrcoef(rngEqn, rngMtFn
isequal(rngEqn, rngMtFn)
%% Save data from FFT
% n256    = rngMtFn;
% n512    = rngMtFn;
% n1024   = rngMtFn;
% n2048   = rngMtFn;
% n4096   = rngMtFn;
% n8192   = rngMtFn;
% n16384  = rngMtFn;
% n32768  = rngMtFn;
n65536  = rngMtFn;
return
%% Get time in seconds

% hours = floor(t_stamps);
% minutes = floor((t_stamps - hours) * 60);
% seconds = round((t_stamps - hours - minutes/60) * 3600);

% % Convert to MATLAB datenum format
% matlab_time = datenum(datetime(1970, 1, 1) + seconds(t_stamps));
% 
% % Convert to hh:mm:ss format
% hh_mm_ss = datestr(matlab_time, 'HH:MM:SS');

t_fmt = t_stamps - min(t_stamps);

%% Calculate calibration value for 1024-point FFT

offset = (n1024(1)-3)/3
offset_percent = offset*100
calibration_value = 1 - offset

%%
close all
figure()
scatter(t_fmt, n256, 20, Marker="+", DisplayName="256")
xlabel("Time (s)",'FontSize',14)
ylabel("Range (m)",'FontSize',14)
ax = gca; 
ax.FontSize = 14;
axis([0, max(t_fmt) 3 3.8])
hold on
scatter(t_fmt, n512, 20, Marker="+", DisplayName="512")
hold on
scatter(t_fmt, n1024, 20, Marker="+", DisplayName="1024")
hold on
scatter(t_fmt, n2048, 20, Marker="+", DisplayName="2048")
hold on
scatter(t_fmt, n4096, 20, Marker="+", DisplayName="4096")
hold on
scatter(t_fmt, n8192, 20, Marker="+", DisplayName="8192")
hold on
scatter(t_fmt, n16384, 20, Marker="+", DisplayName="16534")
hold on
scatter(t_fmt, n32768, 20, Marker="+", DisplayName="32768")

hold on
scatter(t_fmt, n65536, 20, Marker="+", DisplayName="65536")

actual = yline(3, '-','Actual Range', LabelHorizontalAlignment='left', ...
    HandleVisibility='off');
actual.FontSize = 14;
% actual.HandleVisibility = off;
leg = legend(Location="southeast");

title(leg,'FFT Length')

% hold on