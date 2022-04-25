%% Parameters - uRAD
fc = 24.005e9;
c = 3e8;
lambda = c/fc;
range_max = 62.5;
tm = 1e-3;
range_res = 1;
bw = 240e6;
sweep_slope = bw/tm;
%% Extract IQ data from text files
% I and Q is interleaved in raw data
I = readtable('I_trolley_test.txt','Delimiter' ,' ');
Q = readtable('Q_trolley_test.txt','Delimiter' ,' ');

%% Calculate times and sampling frequencies
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

u = I_up + 1i*Q_up;
d = I_down + 1i*Q_down;

%% DSP
Fs = 200e3;
Ns = 200e3;
% Matrix transpose using .'
ut = u.';
dt = d.';

fbu = zeros(344,1);
fbd = zeros(344,1);
p_u = zeros(344,1);
p_d = zeros(344,1);
for row =1:344
    [fbu(row), p_u(row)] = rootmusic(u(row,:),1,Fs);
    [fbd(row), p_d(row)] = rootmusic(d(row,:),1,Fs);
end
close all
figure
tiledlayout(2,1)
nexttile
plot(powu);
nexttile
plot(powd);

rng_est = beat2range([fbu fbd],sweep_slope,c)
fd = -(fbu+fbd)/2;
v_est = dop2speed(fd,lambda)/2




