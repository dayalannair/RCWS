
%% Reference Waveform
fc = 24.005e9;
c = 3e8;
lambda = c/fc;
range_max = 100;
tm = 1e-3; % uRAD ramp time is 1ms
range_res = 1;
bw = rangeres2bw(range_res,c);
sweep_slope = bw/tm;
fr_max = range2beat(range_max,sweep_slope,c);
v_max = 75;
fd_max = speed2dop(2*v_max,lambda);
fb_max = fr_max+fd_max;
fs = max(2*fb_max,bw);
fs = 2*24.245e9
waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs, 'SweepDirection','Triangle');
ref_sig = waveform();

%%
% figure
% tiledlayout(2,1)
% nexttile
% plot(0:1/fs:tm-1/fs,real(ref_sig))
% axis tight
% REF = fft(ref_sig);
% f = f_ax(REF, 1/fs);
% nexttile
% plot(f, fftshift(abs(REF)))
%% Extract IQ data from text files
% I and Q is interleaved in raw data
I = readtable('I.txt','Delimiter' ,' ');
Q = readtable('Q.txt','Delimiter' ,' ');

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

%%
sz = size(I_up,1);
% figure
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

%% Sum IQ data to get complex signal
close all
IQ_up = I_up + 1i*Q_up;
IQ_down = I_down + 1i*Q_down;

IQ = IQ_up + IQ_down; %NB CHECK THIS> NOT VIABLE PROBABLY
% for i = 1:sz
%     pause(0.01)
%     tiledlayout(2,1)
%     nexttile
%     plot(abs(IQ_up(i, :)))
%     hold on
%     plot(abs(IQ_down(i, :)))
%     nexttile
%     plot(IQ(i, :))
%     axis([0 200 4000 11000])
% end

%% Reshape arrays to get whole timeline from individual sweeps
I_up_whole = reshape(I_up.',1,[]);
IQ_up_whole = reshape(IQ_up.',1,[]);
IQ_down_whole = reshape(IQ_down.',1,[]);
% figure 
% 
% tiledlayout(3,1)
% nexttile
% plot(abs(IQ_up_whole))
% nexttile
% plot(abs(IQ_down_whole))
% nexttile
% plot(real(ref_sig(end-10000:end - 1000)))
%% Frequency domain - FFT
figure
% IQ_UP = fft(IQ_up_whole)
% plot(abs(IQ_UP) )

% L=length(I_up(150,:));                      
% f = fs/2*linspace(0,1,NFFT/2+1);  % single-sided positive frequency
% X = fft(I_up(150,:))/L;                     % normalized fft
% PSD=2*abs(X(1:L/2+1))
% plot(f, PSD)
% psd = pwelch(I_up(150,:))
% plot(psd)

UP_WHOLE = fft(IQ_up_whole);
plot(abs(UP_WHOLE))
            
REF_SIG = fft(ref_sig(1:end-100));  % as length increases, tails shorten
f = f_ax(REF_SIG, 1/fs);
% plot(f, abs(REF_SIG))
% axis([-10e10 10e10 0 500])


% TEST = fft(test)
% f = f_ax(TEST, 1/fs);
% plot(f, fftshift(abs(TEST)))
% hold on
% plot(f, abs(TEST))
%%

f_test = 24e9;
fs = 4*f_test;
t = 0:1/fs:0.000000001;
test = sin(2*pi*f_test*t);
% plot(t, test)
%axis([0 0.1 -1 1])
%%
TEST = fft(test)
f = f_ax(TEST, 1/fs);
% plot(f, abs(TEST))

%%
close all
tiledlayout(2,1)
IQ_UP = fft(IQ_up_whole);
REF = fft(ref_sig);

% plot(abs(fftshift(I_UP)))
%f = f_ax(IQ_UP, delta_t);
% 
% nexttile
% plot(fftshift(abs(IQ_UP)))
% 
% nexttile
% plot(fftshift(abs(REF)))

% scope = spectrumAnalyzer(SampleRate=fs)
% scope(I_up_whole')



% fbu_rng = rootmusic(pulsint(xr(:,1:2:end),'coherent'),1,fs);
% fbd_rng = rootmusic(pulsint(xr(:,2:2:end),'coherent'),1,fs);

%%
figure
periodogram(IQ_up_whole,hamming(length(IQ_up_whole)),[],fs,"centered")


%%
% tiledlayout(3,3)
%  nexttile
%  plot(Iup(1, :))
%  nexttile
%  plot(Qup(1, :))
%  nexttile
%  plot(IQ_up(1, :))
% 
%  nexttile
%  plot(Idown(1, :))
%  nexttile
%  plot(Qdown(1, :))
%  nexttile
%  plot(IQ_down(1, :))
% 
% nexttile
%  plot(Iup(end, :))
%  nexttile
%  plot(Qup(end, :))
%  nexttile
%  plot(IQ_up(end, :))

% nexttile
% plot(Qdown)
% nexttile
% plot(IQ_up)
% nexttile
% plot(IQ_down)






