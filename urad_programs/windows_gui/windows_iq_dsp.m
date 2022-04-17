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

I_u = readtable('I_up_FMCW_triangle.txt','Delimiter' ,' ');
I_d = readtable('I_down_FMCW_triangle.txt','Delimiter' ,' ');
Q_u = readtable('Q_up_FMCW_triangle.txt','Delimiter' ,' ');
Q_d = readtable('Q_down_FMCW_triangle.txt','Delimiter' ,' ');

%%
% Calculate times and sampling frequencies
% total_time = I.Var401(200) - I.Var401(1)     % Total time of data recording
% t_sweep = I.Var401(2)-I.Var401(1)            % Sweep time
% update_f = 1/t_sweep                         % Sweep frequency   
% delta_t = t_sweep/200                        % sampling period: estimation   
% fs_real = 1/delta_t                               % Sampling frequency estimation
% t_axis_sweep = 1:delta_t:t_sweep;            % time axis for plotting one sweep   
% t_axis_whole = 1:delta_t:total_time;         % time axis for whole received signal   
%% Convert IQ data tables to arrays
Iu = table2array(I_u(:,1:end-2));
Id = table2array(I_d(:,1:end-2));
Qu = table2array(Q_u(:,1:end-2));
Qd = table2array(Q_d(:,1:end-2));

IQ_u = Iu + 1i*Qu;
IQ_d = Id + 1i*Qd;
%% Spectrogram - returns short-time Fourier transform
close all
%IQ_triangle = cat(2, IQ_up(100,:), IQ_down(100,:));
figure
tiledlayout(2,1)
nexttile
spectrogram(IQ_u(100,:),32,16,32,fs,'yaxis');
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

fbu_rng = rootmusic(IQ_u,size(IQ_u,1),fs); % size in dim 2 since matrix transposed
fbd_rng = rootmusic(IQ_d,size(IQ_u,1),fs);

rng_ests = beat2range([fbu_rng fbd_rng],sweep_slope,c);
fds = -(fbu_rng+fbd_rng)/2;
v_ests = dop2speed(fds,lambda)/2;
