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
% I and Q is interleaved in raw data
I = readtable('I_trolley_test.txt','Delimiter' ,' ');
Q = readtable('Q_trolley_test.txt','Delimiter' ,' ');

% Calculate times and sampling frequencies
total_time = I.Var401(200) - I.Var401(1)     % Total time of data recording
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

IQ_u = I_up + 1i*Q_up;
IQ_d = I_down + 1i*Q_down;

% IQ_up_whole = reshape(IQ_up.',1,[]);
% IQ_down_whole = reshape(IQ_down.',1,[]);
%% Spectrogram - returns short-time Fourier transform
% close all
% IQ_triangle = cat(2, IQ_up(100,:), IQ_down(100,:));
% figure
% tiledlayout(2,1)
% nexttile
% spectrogram(IQ_up(100,:),32,16,32,fs,'yaxis');
% %spectrogram(IQ_up(100,:))
% nexttile
% %spectrogram(ref_sig)
% spectrogram(ref_sig,32,16,32,fs,'yaxis');

%% Periodogram
close all
figure
Fs = 200e6
tiledlayout(3,2)
nexttile
periodogram(IQ_u',[],[], Fs, 'centered');
title(sprintf("Periodogram of IQ\\_up range (rows) rect window"));

nexttile
periodogram(IQ_u,[],[], Fs, 'centered');
%title("Periodogram of IQ\_up doppler (cols) rect window");

nexttile
periodogram(IQ_u',kaiser(size(IQ_u',1),38),[], Fs, 'centered');
%title("Periodogram of IQ\_up range (rows) kaiser window, \Beta = 38");

nexttile
periodogram(IQ_u,kaiser(size(IQ_u,1),38),[], Fs, 'centered');
%title("Periodogram of IQ\_up doppler (cols) kaiser window, \Beta = 38");

nexttile
periodogram(IQ_u',kaiser(size(IQ_u',1),19),[], Fs, 'centered');
%title("Periodogram of IQ\_up range (rows) kaiser window, \Beta = 19");

nexttile
periodogram(IQ_u,kaiser(size(IQ_u,1),19),[], Fs, 'centered');
%title("Periodogram of IQ\_up doppler (cols) kaiser window, \Beta = 19");
%% Visualisation
sz = size(I_up,1);
figure
% for i = 1: sz
%     pause(0.05)
%     tiledlayout(4,1)
%     nexttile
%     plot(I_up(i, :))
%     title("I up chirp")
%     nexttile
%     plot(I_down(i, :))
%     title("I down chirp")
%     nexttile
%     plot(Q_up(i, :))
%     title("Q up chirp")
%     nexttile
%     plot(Q_down(i, :))
%     title("Q down chirp")
% end

% tiledlayout(2,1)
% nexttile
% plot(abs(IQ_up_whole))
% nexttile
% plot(abs(IQ_down_whole))