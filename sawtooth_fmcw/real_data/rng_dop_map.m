% Parameters
close all
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;                           
fs = 200e3;
% TUNE PARAMETERS
bw = 100e6; 
n = 40;
t_sweep = n/fs; 
sweep_slope = bw/t_sweep;
addpath('../../library/');
r_max = c*n/(4*bw);
v_max = lambda/(4*t_sweep);
% Sweeps per frame
n_spf = 128;
[iq, fft_frames, iq_frames, n_frames] = import_frames(n_spf, n);

% Range Doppler Map
% Nft = size(iq_frames,1); % Number of fast-time samples
% Nst = n_spf; % Number of slow-time samples
% Nr = 2^nextpow2(Nft); % Number of range samples 
% Nd = 2^nextpow2(Nst); % Number of Doppler samples 

Nr = 512;
Nd = 256;

rdresp = phased.RangeDopplerResponse('RangeMethod','FFT',...
    'DopplerOutput','Speed','SweepSlope',sweep_slope,...
    'RangeFFTLengthSource','Property','RangeFFTLength',Nr,...
    'DopplerFFTLengthSource','Property','DopplerFFTLength',Nd,...
    'PropagationSpeed',c,'OperatingFrequency',fc,'SampleRate',fs, ...
    'RangeWindow', 'Taylor', 'RangeSidelobeAttenuation',20, ...
    'DopplerWindow', 'Taylor', 'DopplerSidelobeAttenuation', 20);

% figure('WindowState','maximized');
figure
movegui('west')
t_frame = t_sweep*n_spf;
t_total = t_frame*n_frames
%%
for frame = 1:n_frames
    clf;
    plotResponse(rdresp,iq_frames(:,:,frame));    
    axis([-v_max v_max 0 r_max])
    clim = caxis;
%     pause(0.1)
    pause(t_frame)
    frame
end
%%
clf;
    plotResponse(rdresp,iq_frames(:,:,26));    
    axis([-v_max v_max 0 r_max])
    clim = caxis;
% %     pause(0.1)