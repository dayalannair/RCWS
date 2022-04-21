%% Parameters - uRAD
fc = 24.005e9;
c = 3e8;
lambda = c/fc;
range_max = 62.5;
tm = 1e-3;
range_res = 1;
bw = 240e6;
sweep_slope = bw/tm;
fr_max = range2beat(range_max,sweep_slope,c);
v_max = 75;
fd_max = speed2dop(2*v_max,lambda);
fb_max = fr_max+fd_max;
fs = max(2*fb_max,bw);
%% Extract IQ data from text files
% I and Q is interleaved in raw data
I = readtable('I_trolley_test.txt','Delimiter' ,' ');
Q = readtable('Q_trolley_test.txt','Delimiter' ,' ');

% Calculate times and sampling frequencies
total_time = I.Var401(344) - I.Var401(1)     % Total time of data recording
t_sweep = I.Var401(2)-I.Var401(1)            % Sweep time
update_f = 1/t_sweep                         % Sweep frequency   
delta_t = t_sweep/200                        % sampling period: estimation   
fs_real = 1/delta_t                          % Sampling frequency estimation
t_axis_sweep = 1:delta_t:t_sweep;            % time axis for plotting one sweep   
t_axis_whole = 1:delta_t:total_time;         % time axis for whole received signal   
%% Convert IQ data tables to arrays

I_up = table2array(I(:, 1:(end-1)/2));
I_down = table2array(I(:, (end-1)/2 + 1:end-1));

Q_up = table2array(Q(:, 1:(end-1)/2));
Q_down = table2array(Q(:, (end-1)/2 + 1:end-1));

IQ_u = I_up + 1i*Q_up;
IQ_d = I_down + 1i*Q_down;

%% 2D FFT
% Important note:
% ' ----> conjugate and transpose
% .' ---> transpose - used for complex numbers
frame_length = 100;
sz = size(IQ_u, 2);
Fs = 200e3;
f = f_ax(sz,1/Fs);
Tc = 2e-3;

IQ_U = fft2(IQ_u(205:210,:), 2048, 2048);
figure(1)
%plot(abs(IQ_U));
close all
imagesc(f/1000, linspace(0, 100), 10*log(abs(fftshift(IQ_U, 2))))
xlabel("Range (m)")
ylabel("Velocity (m/s)")
%%
% frame_length = 5;
% close all
% figure
% for i =1:5:2048
%     temp = fft2(IQ_u(i:sz+frame_length, :), 2048, 2048);
%     imagesc(f/1000, linspace(0, 100), 10*log(abs(fftshift(temp, 2))))
%     pause(0.1)
% end

%% Range FFT
close all
figure(2)
clims = [3000 5000];
rng_u = fft(IQ_u, [], 2);
rng_d = fft(IQ_d, [], 2);
rng_u_magsft = fftshift(abs(rng_u),2);
rng_d_magsft = fftshift(abs(rng_d),2);
rngs = beat2range(f.', sweep_slope, c);
tiledlayout(2,2)
nexttile
plot(rngs, 10*log(rng_u_magsft));
title("Up chirp range-FFT magnitude");
xlabel("Range (m)")
ylabel("Magnitude (dB)")
nexttile
imagesc(rngs,linspace(0, 344), 10*log(rng_u_magsft));
title("Up chirp range map")
xlabel("Range (m)")
ylabel("Sweep number")
nexttile
plot(rngs, 10*log(rng_d_magsft));
title("Down chirp range-FFT magnitude");
xlabel("Range (m)")
ylabel("Magnitude (dB)")
nexttile
imagesc(rngs,linspace(0, 344), 10*log(rng_d_magsft));
title("Down chirp range map")
xlabel("Range (m)")
ylabel("Sweep number")
%% Doppler FFT
% need to consider frame length

dop_u = fft(rng_u, [], 1);
dop_d = fft(rng_d, [], 1);
dop_u_magsft = fftshift(abs(dop_u),2);
dop_d_magsft = fftshift(abs(dop_d),2);
vels = dop2speed(f.', lambda);
close all
tiledlayout(2,2)
nexttile
plot(rngs, 10*log(dop_u_magsft));
title("Up chirp range-FFT magnitude");
xlabel("Range (m)")
ylabel("Magnitude (dB)")
nexttile
imagesc(rngs,linspace(0, 344), 10*log(dop_u_magsft));
title("Up chirp range map")
xlabel("Range (m)")
ylabel("Sweep number")
nexttile
plot(rngs, 10*log(dop_d_magsft));
title("Down chirp range-FFT magnitude");
xlabel("Range (m)")
ylabel("Magnitude (dB)")
nexttile
imagesc(rngs,linspace(0, 344), 10*log(dop_d_magsft));
title("Down chirp range map")
xlabel("Range (m)")
ylabel("Sweep number")

%% Range-Doppler response
Fs = 200e3;
u_pad = padarray(IQ_u, [2048 - size(IQ_u, 1) 2048 - size(IQ_u, 2)], 'post');
rdresp = phased.RangeDopplerResponse(...
   'RangeMethod','FFT',...
   'PropagationSpeed',physconst('LightSpeed'),...
   'SampleRate',Fs,...
   'SweepSlope',sweep_slope, ...
   'DopplerFFTLengthSource','Property', ...
   'DopplerFFTLength', 50, ...
   'DopplerWindow', 'Kaiser', ...
   'DopplerSidelobeAttenuation', 38, ...
   'DopplerOutput','Speed', ...
   'OperatingFrequency', fc);
close all
figure
plotResponse(rdresp, u_pad)
close all
figure
plotResponse(rdresp, IQ_u)


