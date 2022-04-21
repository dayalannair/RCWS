%% Extract IQ data from text files
% I and Q is interleaved in raw data
I = readtable('I_trolley_test.txt','Delimiter' ,' ');
Q = readtable('Q_trolley_test.txt','Delimiter' ,' ');

I_up = table2array(I(:, 1:(end-1)/2));
I_down = table2array(I(:, (end-1)/2 + 1:end-1));

Q_up = table2array(Q(:, 1:(end-1)/2));
Q_down = table2array(Q(:, (end-1)/2 + 1:end-1));

u = I_up + 1i*Q_up;
d = I_down + 1i*Q_down;
%% Range FFT
rng_u = fft(u, [], 2);
rng_d = fft(d, [], 2);
rng_u_magsft = fftshift(abs(rng_u),2);
rng_d_magsft = fftshift(abs(rng_d),2);

c = physconst('LightSpeed');
fc = 24.005e9;
lambda = c/fc;
tm = 1e-3;
bw = 240e6;
sweep_slope = bw/tm;
sz = size(u, 2);
Fs = 200e3;
f = f_ax(sz,1/Fs);
rngs = beat2range(f.', sweep_slope, c);
%% Doppler FFT

% Extract 2 sweeps for a frame
pos = 1;
frame_u = rng_u(pos:pos, :);
fr_u_tp = frame_u.';

frame_d = rng_d(pos:pos, :);
fr_d_tp = frame_d.';

dopfft(1,:) = dopfft(2,:);      % Null DC component
peak = max(dopfft);              % returns max value of each column
close all
figure
%plot(abs(peak))
plot(abs(fftshift(dopfft')))    % need transpose of dopp fft to put dopp fft cols as rows
                                % OR add an axis to transpose it as seen
                                % below

%% Loop dopp fft
close all
figure
for pos = 1:sz/2
    frame_u = rng_u(pos:pos+1, :);
    frame_d = rng_d(pos:pos+1, :);

    dopfft = fft(frame_u);
    
    dopfft(1,:) = dopfft(2,:);      % Null DC component
    peak = max(dopfft);              % returns max value of each column
    
    plot(f/1000, abs(fftshift(dopfft')))
    pause(0.2)
end
%% Plots
close all
figure
plot(rngs, fftshift(abs(dopfft)))

%% Root music
% pos = 150;
% frame_u = rng_u(pos:pos, :);
% fr_u_tp = frame_u.';
% 
% frame_d = rng_d(pos:pos, :);
% fr_d_tp = frame_d.';
% 
% fbu = rootmusic(pulsint(fr_u_tp, 'coherent'), 1, Fs);
% fbd = rootmusic(pulsint(fr_d_tp, 'coherent'), 1, Fs);
% 
% rng = beat2range([fbu fbd], sweep_slope, c);
% 
% fd = -(fbu+fbd)/2;
% v_est = dop2speed(fd,lambda)/2

%% Test

rng default
n = (0:99)';
frqs = [pi/4 pi/4+0.06];

s = 2*exp(1j*frqs(1)*n)+1.5*exp(1j*frqs(2)*n)+ ...
    0.5*randn(100,1)+1j*0.5*randn(100,1);

[~,R] = corrmtx(s,12,'mod');
[W,P] = rootmusic(R,2,'corr')


