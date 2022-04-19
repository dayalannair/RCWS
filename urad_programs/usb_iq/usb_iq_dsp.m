%% Reference Waveform
fc = 24.005e9;
c = 3e8;
lambda = c/fc;
range_max = 62.5;
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
total_time = I.Var401(344) - I.Var401(1)     % Total time of data recording
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
%% Range FFT
range_fft_up = fft(IQ_u,[],2);
range_fft_down = fft(IQ_d,[],2);
sz = size(IQ_u, 2);
Fs = 200e3; % twice f_beat_max
f = f_ax(sz,1/Fs);
close all
figure
tiledlayout(2,2)
nexttile
plot(f/1000, 10*log10(fftshift(abs(range_fft_up'))));
xlabel("Frequency (kHz)");
ylabel("Magnitude (dB)");
%axis([-30 30 0 ])
nexttile
plot(angle(range_fft_down'));
nexttile
plot(f/1000, 10*log10(fftshift(abs(range_fft_up'))));
xlabel("Frequency (kHz)");
ylabel("Magnitude (dB)");
nexttile
plot(angle(range_fft_down'));

%% Beat frequency extraction
% each row is a frame
% the time and frequency domain matrices have same dims
frames = size(IQ_u, 1);
% array of indices/sample numbers where target detected
detections = zeros(size(IQ_u));
% sample numbers of detections
indices = zeros(size(IQ_u));
% array of fftshifted magnitudes
rng_fftshift_mag_u = fftshift(abs(range_fft_up));
%% Threshold Detection
threshold = 1.6e4;
for frame = 1:frames
    %detections(frame, :) = range_fft_up(range_fft_up(frame, :)>threshold, :);
    for sample = 1:sz
        % need to use fftshift to correspond to defined f_ax
        if (rng_fftshift_mag_u(frame, sample) > threshold)
            detections(frame, sample) = rng_fftshift_mag_u(frame, sample);
        else
            detections(frame, sample) = 0;
        end
    end
end
close all
figure
plot(abs(detections'))

%% Extract beat frequencies
f_beats = zeros(frames, 1);
for frame = 1:frames
   % get the two largest values/magnitudes
   peaks = maxk(detections(frame, :), 2);
   if peaks(2)>0
    index = find(detections(frame,:)==peaks(2));
    f_beats(frame) = f(index); % get frequency from specified frequency axis
   else
       f_beats(frame) = 0;
   end
end

Ns = 200;
t = 0:total_time/frames:total_time;
% figure
% plot(f_beats)
close all
figure
ranges = beat2range(f_beats, sweep_slope, c);
plot(t(1:end-1),fftshift(ranges))
xticks(1:1:15)
title("Distance of target 1");
xlabel("Time (s)");
ylabel("Target distance (m)");

%% Import uRAD processed results for comparison
% Note that the results for the IQ and uRAD processed tests are not from
% the same test, for the same scenario

% urad_usb = readtable('USB_results_test1_2','Delimiter' ,' ');
% 
% usb_targ1 = zeros(height(urad_usb), 3);
% 
% % Needed as gaps will occur in targ 1 array when targ 2 is next in table
% array_index1 = 0;
% array_index2 = 0;
% 
% for i = 1:height(urad_usb)
%     if (urad_usb.Var1(i) == 1)
%         array_index1 = array_index1 + 1;
%         usb_targ1(array_index1,:) = table2array(urad_usb(i, 2:end-2));       
%     end
% end
% 
% size_usbtarg_1 = array_index1;
% % resize array
% usb_targ1 = usb_targ1(1:size_usbtarg_1, :);
% 
% close all
% figure
% tiledlayout(2,1)
% 
% nexttile
% plot(usb_targ1(:,1))
% ylabel("Distance (m)");
% xlabel("Time");
% title("uRAD processed results");
% 
% nexttile
% plot(t(1:end-1),fftshift(ranges))
% xticks(1:1:15)
% title("Distance of target 1");
% xlabel("Time (s)");
% ylabel("Target distance (m)");
%%
% close all
% for i = 1:sz
%     pause(0.05)
%     tiledlayout(2,3)
%     nexttile
%     plot(f/1000, 10*log10(fftshift(abs(range_fft_up(i,:)))));
%     xlabel("Frequency (kHz)");
%     ylabel("Magnitude (dB)");
%     yline(45)
%     nexttile
%     plot(f/1000, fftshift(abs(range_fft_up(i,:))));
%     xlabel("Frequency (kHz)");
%     ylabel("Magnitude (dB)");
%     yline(45)
%      nexttile
%     plot(f/1000, fftshift(abs(range_fft_up(i,:))));
%     xlabel("Frequency (kHz)");
%     ylabel("Magnitude (dB)");
%     yline(1.6e4)
%     axis([-30 30 0 4e4])
%     nexttile
%     plot(f/1000, 10*log(fftshift(abs(range_fft_down(i,:)))));
%     xlabel("Frequency (kHz)");
%     ylabel("Magnitude (dB)");
%     nexttile
%     plot(f/1000, fftshift(abs(range_fft_down(i,:))));
%     xlabel("Frequency (kHz)");
%     ylabel("Magnitude (dB)");
%     nexttile
%     plot(f/1000, fftshift(abs(range_fft_down(i,:))));
%     xlabel("Frequency (kHz)");
%     ylabel("Magnitude (dB)");
%     yline(1.6e4)
%     axis([-30 30 0 4e4])
% end
%% Dechirp

du = dechirp(IQ_u', ref_sig);

[duu,F] = periodogram(du,kaiser(size(IQ_u',1),38),[],Fs,'centered');
plot(F/1000,10*log10(duu));
xlabel('Frequency (kHz)');
ylabel('Power/Frequency (dB/Hz)');
grid
title('Periodogram Power Spectral Density Estimate After Dechirping');
r = beat2range(90e3,sweep_slope)
%% ref dechirp
ref_dcp = dechirp(ref_sig,ref_sig)
close all
plot(abs(ref_dcp))

%% moving plot
% close all
% figure
% sz = size(range_fft_up,2);
% for i = 1:sz
%     plot(abs(ref_dcp(:,i)))
%     pause(0.1)
%     disp(i)
% end

%% Doppler FFT
doppler_fft_up = fft(range_fft_up);%fft(IQ_u,[],1);
doppler_fft_down = fft(range_fft_down);%fft(IQ_d,[],1);
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
figure
sz = size(range_fft_up,2);
for i = 1:sz
    plot(abs(doppler_fft_up(10:end,i)))
    pause(0.1)
    disp(i)
end




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
%% Estimate results


fbu_rngs = zeros(1,size(IQ_u, 2));
fbd_rngs = zeros(1,size(IQ_u, 2));
rng_ests = zeros(1,size(IQ_u, 2));
v_ests = zeros(1,size(IQ_u, 2));
%sz = size(IQ_u, 2);
% for i = 1:sz
% 
%    % transposing just reflects over x axis
%     fbu_rngs(i) = rootmusic(IQ_u(i,:),1,fs);
%     fbd_rngs(i) = rootmusic(IQ_d(i,:),1,fs);
%     rng_ests(i) = beat2range([fbu_rngs(i) fbd_rngs(i)],sweep_slope,c);
% 
%     fd = -(fbu_rngs(i)+fbd_rngs(i))/2;
%     v_ests(i) = dop2speed(fd,lambda)/2;
% end
figure
tiledlayout(2,1)
nexttile
plot(rng_ests)
nexttile
plot(v_ests)
% fbu_rng = rootmusic(IQ_u(:,1),1,fs); % size in dim 2 since matrix transposed
% fbd_rng = rootmusic(IQ_d(:,1),1,fs);

% fbu_rng = rootmusic(IQ_u',1,fs); % size in dim 2 since matrix transposed
% fbd_rng = rootmusic(IQ_d',1,fs);

% rng_ests = beat2range([fbu_rng fbd_rng],sweep_slope,c)
% fds = -(fbu_rng+fbd_rng)/2;
%v_ests = dop2speed(fds,lambda)/2
%% Ambiguity function
Fs = 200e3;
PRF = 1/(1e-3);
[afmag_u,delay,doppler] = ambgfun(IQ_u(1,:), Fs, PRF);
[afmag_d,delay_d,doppler_d] = ambgfun(IQ_d(1,:), Fs, PRF);
figure(1)
% contour3(delay,doppler,afmag_u)
% xlabel('Delay (seconds)')
% ylabel('Doppler Shift (hertz)')

surf(delay*1e6,doppler/1e3,afmag_u,'LineStyle','none'); 
axis tight; grid on; view([140,35]); colorbar;
xlabel('Delay \tau (us)');ylabel('Doppler f_d (kHz)');
title('Linear FM Pulse Waveform Ambiguity Function');

figure(2)
surf(delay_d*1e6,doppler_d/1e3,afmag_d,'LineStyle','none'); 
axis tight; grid on; view([140,35]); colorbar;
xlabel('Delay \tau (us)');ylabel('Doppler f_d (kHz)');
title('Linear FM Pulse Waveform Ambiguity Function');


[afmag_ref,delay_ref,doppler_ref] = ambgfun(ref_sig, Fs, PRF);
figure(3)
surf(delay_ref*1e6,doppler_ref/1e3,afmag_ref,'LineStyle','none'); 
axis tight; grid on; view([140,35]); colorbar;
xlabel('Delay \tau (us)');ylabel('Doppler f_d (kHz)');
title('Linear FM Pulse Waveform Ambiguity Function');

%% Periodic AF

[pafmag, del, dop] = pambgfun(IQ_u(1,:), Fs);
close all
figure(4)
surf(del*1e6,dop/1e3,afmag_u,'LineStyle','none'); 
axis tight; grid on; view([140,35]); colorbar;
xlabel('Delay \tau (us)');ylabel('Doppler f_d (kHz)');
title('Linear FM Pulse Waveform Ambiguity Function');

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