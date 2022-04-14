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
waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs, 'SweepDirection','Triangle');
ref_sig = waveform();
%%
% I and Q is interleaved in raw data
IQ_up = readtable('..\URAD_IQ_data\test_3hand_waves\I_up_FMCW_triangle.txt','Delimiter' ,' ');
IQ_down = readtable('..\URAD_IQ_data\test_3hand_waves\I_down_FMCW_triangle.txt','Delimiter' ,' ');

%%
Iup = table2array(I_up(:, 1:2:end-2));
Idown = table2array(I_down(:, 1:end-2));
Qup = table2array(Q_up(:, 1:end-2));
Qdown = table2array(Q_down(:, 1:end-2));

% tiledlayout(4,1)
% nexttile
% plot(Iup)
% nexttile
% plot(Idown)
% nexttile
% plot(Qup)
% nexttile
% plot(Qdown)

IQ_up = Iup + Qup;
IQ_down = Qup + Qdown;

% tiledlayout(2,1)
% nexttile
% plot(IQ_up)
% nexttile
% plot(IQ_down)

tiledlayout(3,3)
 nexttile
 plot(Iup(1, :))
 nexttile
 plot(Qup(1, :))
 nexttile
 plot(IQ_up(1, :))

 nexttile
 plot(Idown(1, :))
 nexttile
 plot(Qdown(1, :))
 nexttile
 plot(IQ_down(1, :))

nexttile
 plot(Iup(end, :))
 nexttile
 plot(Qup(end, :))
 nexttile
 plot(IQ_up(end, :))

% nexttile
% plot(Qdown)
% nexttile
% plot(IQ_up)
% nexttile
% plot(IQ_down)






