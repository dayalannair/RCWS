%% Reference Waveform
fc = 24.005e9;
c = 3e8;
lambda = c/fc;
range_max = 100;
%tm = 5.5*range2time(range_max,c);
tm = 1e-3; % uRAD ramp time is 1ms
range_res = 1;
%bw = rangeres2bw(range_res,c);
bw = 240e6;
sweep_slope = bw/tm;
fr_max = range2beat(range_max,sweep_slope,c);
v_max = 75;
fd_max = speed2dop(2*v_max,lambda);
fb_max = fr_max+fd_max;
fs = max(2*fb_max,bw);
%fs = 2*24.245e9
waveform = phased.FMCWWaveform('SweepTime',tm, ...
    'SweepBandwidth',bw, ...
    'SampleRate',fs, ...
    'SweepDirection','Triangle', ...
    'OutputFormat', 'Samples', ...
    'NumSamples', 200);

ref_sig = waveform();

%% Extract IQ data from text files

%IQ = readtable('IQ.txt','Delimiter' ,' ');
I = readtable('I.txt','Delimiter' ,' ');
Q = readtable('Q.txt','Delimiter' ,' ');
% Q_d = readtable('Q_down_FMCW_triangle.txt','Delimiter' ,' ');

%% Sampling Metrics
total_time = I.Var401(end) - I.Var401(1)     % Total time of data recording
t_sweep = I.Var401(2)-I.Var401(1)            % Sweep time
update_f = 1/t_sweep                         % Sweep frequency   
delta_t = t_sweep/200                        % sampling period: estimation   
fs_real = 1/delta_t                               % Sampling frequency estimation
t_axis_sweep = 1:delta_t:t_sweep;            % time axis for plotting one sweep   
t_axis_whole = 1:delta_t:total_time;         % time axis for whole received signal   
%% Convert IQ data tables to arrays
I_up = table2array(I(:, 1:(end-1)/2));
I_down = table2array(I(:, (end-1)/2 + 1:end-1));

Q_up = table2array(Q(:, 1:(end-1)/2));
Q_down = table2array(Q(:, (end-1)/2 + 1:end-1));

%%
x = max(I_up)
%%
u = I_up + 1i*Q_up;
d = I_down + 1i*Q_down;
%% Spectrogram - returns short-time Fourier transform
close all
%IQ_triangle = cat(2, IQ_up(100,:), IQ_down(100,:));
figure
tiledlayout(2,1)
nexttile
spectrogram(u(100,:),32,16,32,fs,'yaxis');
%spectrogram(IQ_up(100,:))
nexttile
%spectrogram(ref_sig)
spectrogram(ref_sig,32,16,32,fs,'yaxis');

%% Periodogram
figure
tiledlayout(2,1)
nexttile
periodogram(IQ_u(100,:))
nexttile
periodogram(ref_sig)
%% Visualisation

sz = size(Iu,1);
figure
% for i = 1: sz
%     pause(0.05)
%     tiledlayout(4,1)
%     nexttile
%     plot(Iu(i, :))
%     title("I up chirp")
%     nexttile
%     plot(Id(i, :))
%     title("I down chirp")
%     nexttile
%     plot(Qu(i, :))
%     title("Q up chirp")
%     nexttile
%     plot(Qd(i, :))
%     title("Q down chirp")
% end

% tiledlayout(2,1)
% nexttile
% plot(abs(IQ_up_whole))
% nexttile
% plot(abs(IQ_down_whole))
%% Range Doppler map

rngdopresp = phased.RangeDopplerResponse('PropagationSpeed',c,...
    'DopplerOutput','Speed','OperatingFrequency',fc,'SampleRate',fs,...
    'RangeMethod','FFT','SweepSlope',sweep_slope,...
    'RangeFFTLengthSource','Property','RangeFFTLength',2048,...
    'DopplerFFTLengthSource','Property','DopplerFFTLength',256);
clf;

plotResponse(rngdopresp,IQ_u'); 

%% Estimate results

% fbu_rng = rootmusic(pulsint(IQ_u(:,1:2:end)','coherent'),1,fs);
% fbd_rng = rootmusic(pulsint(IQ_d(:,2:2:end)','coherent'),1,fs);

% Dechirp having no effect!
IQ_up_dechirp = dechirp(IQ_u', ref_sig);
IQ_down_dechirp = dechirp(IQ_d', ref_sig); % need to get down ramp of triangle

fbu_rng = rootmusic(IQ_up_dechirp,1,fs); % size in dim 2 since matrix transposed
fbd_rng = rootmusic(IQ_down_dechirp,1,fs);

% fbu_rng = rootmusic(IQ_u',1,fs); % size in dim 2 since matrix transposed
% fbd_rng = rootmusic(IQ_d',1,fs);

rng_ests = beat2range([fbu_rng fbd_rng],sweep_slope,c)
fds = -(fbu_rng+fbd_rng)/2;
v_ests = dop2speed(fds,lambda)/2

%% Learnt method
% note: for a matrix, fft operates on columns by default

%% Range-FFT

% Method 1
% range_fft_up = fft(IQ_u');
% range_fft_up = range_fft_up';

% Method 2
range_fft_up = fft(IQ_u,[],2);
range_fft_down = fft(IQ_d,[],2);
% ref_range_fft = fft(ref_sig);
% Only first col the same in both methods. Find out why. Try both out.
% Method 2 explained in matlab and is correct
Fs = 200e3;
f = f_ax(range_fft_up,1/Fs);
close all
figure
tiledlayout(2,2)
nexttile
plot(abs(range_fft_up'));
nexttile
plot(angle(range_fft_down'));
nexttile
plot(abs(range_fft_up'));
nexttile
plot(angle(range_fft_down'));
%sz = size(range_fft_up,1);
% for i = 1:sz
%     plot(abs(range_fft_up(i,:)))
%     pause(0.1)
%     disp(i)
% 
% end

%% Doppler-FFT

doppler_fft_up = fft(IQ_u);
doppler_fft_down = fft(IQ_d);
close all

figure
tiledlayout(2,2)
nexttile
plot(abs(doppler_fft_up)) % plots columns
nexttile
plot(angle(doppler_fft_down))
nexttile
plot(abs(doppler_fft_up)) % plots columns
nexttile
plot(angle(doppler_fft_down))

%%
% figure
% sz = size(range_fft_up,2);
% for i = 1:sz
%     plot(abs(doppler_fft_up(:,i)))
%     pause(0.1)
%     disp(i)
% end

%% Plots of each frame IQ up
figure
tiledlayout(2,1)
nexttile
plot(abs(IQ_u'))
nexttile
plot(angle(IQ_u'))
%%
figure
tiledlayout(2,1)
nexttile
plot(abs(range_fft_up'))
nexttile
plot(ref_sig)




