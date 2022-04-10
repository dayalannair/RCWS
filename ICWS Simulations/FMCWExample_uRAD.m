

fc = 24.005e9;
c = 3e8;
lambda = c/fc;


range_max = 100;
tm = 5.5*range2time(range_max,c);
%tm = 2e-3

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

sig = waveform();

subplot(211); plot(0:1/fs:tm-1/fs,real(sig));
xlabel('Time (s)'); ylabel('Amplitude (v)');
title('FMCW signal'); axis tight;
subplot(212); spectrogram(sig,32,16,32,fs,'yaxis');
title('FMCW signal spectrogram');

car_dist = 90;
car_speed = -20;
car_rcs = db2pow(min(10*log10(car_dist)+5,20));
cartarget = phased.RadarTarget('MeanRCS',car_rcs,'PropagationSpeed',c,...
    'OperatingFrequency',fc);
carmotion = phased.Platform('InitialPosition',[car_dist;0;0.5],...
    'Velocity',[car_speed;0;0]);

channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs,'TwoWayPropagation',true);

ant_aperture = 6.06e-4;                         % in square meter
ant_gain = aperture2gain(ant_aperture,lambda);  % in dB

tx_ppower = db2pow(5)*1e-3;                     % in watts
tx_gain = 9+ant_gain;                           % in dB

rx_gain = 15+ant_gain;                          % in dB
rx_nf = 4.5;                                    % in dB

transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs);

radar_speed = 0;
radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);

rng(2012);
Nsweep = 32;
uRAD_update_rate = 13;
% Generate visuals
sceneview = phased.ScenarioViewer('BeamRange',75,...
    'BeamWidth',[30; 30], ...
    'ShowBeam', 'All', ...
    'CameraPerspective', 'Custom', ...
    'CameraPosition', [2147.9 -1071.99 520.03], ...
    'CameraOrientation', [-153.06 -12.55 0]', ...
    'CameraViewAngle', 7.09, ...
    'ShowName',true,...
    'ShowPosition', true,...
    'ShowSpeed', true,...
    'ShowRadialSpeed',true,...
    'UpdateRate',uRAD_update_rate);


xr = complex(zeros(waveform.SampleRate*waveform.SweepTime,Nsweep));

for m = 1:Nsweep
    % Update radar and target positions
    [radar_pos,radar_vel] = radarmotion(waveform.SweepTime);
    [tgt_pos,tgt_vel] = carmotion(waveform.SweepTime);

    % Transmit FMCW waveform
    sig = waveform();
    txsig = transmitter(sig);
    
    % Propagate the signal and reflect off the target
    txsig = channel(txsig,radar_pos,tgt_pos,radar_vel,tgt_vel);
    txsig = cartarget(txsig);
    
    % Dechirp the received radar return
    txsig = receiver(txsig);    
    dechirpsig = dechirp(txsig,sig);
    xr(:,m) = dechirpsig;
    
%     sceneview(radar_pos,radar_vel,tgt_pos,tgt_vel);
%     drawnow;
end

radar_pos
tgt_pos
tgt_vel
% longer sweep time makes range doppler more prominent
waveform_tr = clone(waveform);
release(waveform_tr);

% NB: CHANGING TM HERE AFFECTS ESTIMATION ACCURACY
tm = 2e-3;
waveform_tr.SweepTime = tm;
sweep_slope = bw/tm;

waveform_tr.SweepDirection = 'Triangle';

% Now simulate the signal return. Because of the longer sweep time,
% fewer sweeps (16 vs. 64) are collected before processing.

Nsweep = 16

xr = helperFMCWSimulate(Nsweep,waveform_tr,radarmotion,carmotion,...
    transmitter,channel,cartarget,receiver);

fbu_rng = rootmusic(pulsint(xr(:,1:2:end),'coherent'),1,fs);
fbd_rng = rootmusic(pulsint(xr(:,2:2:end),'coherent'),1,fs);

rng_est = beat2range([fbu_rng fbd_rng],sweep_slope,c)

fd = -(fbu_rng+fbd_rng)/2;
v_est = dop2speed(fd,lambda)/2

% NEED TO SEE IF I CAN CREATE RD PLOT FOR TRIANGLE SWEEP XR. SEEMS WORKING
% ABOVE FOR TRIANGLE. THE LONGER TM CAUSES NARROWING!
% rngdopresp = phased.RangeDopplerResponse('PropagationSpeed',c,...
%     'DopplerOutput','Speed','OperatingFrequency',fc,'SampleRate',fs,...
%     'RangeMethod','FFT','SweepSlope',sweep_slope,...
%     'RangeFFTLengthSource','Property','RangeFFTLength',2048,...
%     'DopplerFFTLengthSource','Property','DopplerFFTLength',256);
% 
% clf;
% plotResponse(rngdopresp,xr);                     % Plot range Doppler map
% %axis([-v_max v_max 0 range_max])
% clim = caxis;

%% Two-ray Propagation
% To complete the discussion, in reality, the actual signal propagation
% between the radar and the target vehicle is more complicated than what is
% modeled so far. For example, the radio wave can also arrive at the target
% vehicle via reflections. A simple yet widely used model to describe such
% a multipath scenario is a two-ray model, where the signal propagates from
% the radar to the target vehicle via two paths, one direct path and one
% reflected path off the road, as shown in the following figure.
%
% <<../FMCWExample_tworay.png>>
%
% The reflection off the road affects the phase of the signal and the
% received signal at the target vehicle is a coherent combination of the
% signals via the two paths. The same thing happens on the return trip 
% where the reflected signal from the target vehicle travels back to the
% radar. Hence depending on the distance between the vehicles, the signals
% from different paths may add constructively or destructively, making
% signal strength fluctuate over time. Such fluctuation can pose some
% challenge in the successive detection stage.
%
% To showcase the multipath effect, next section uses the two-ray channel
% model to propagate the signal between the radar and the target vehicle.

txchannel = twoRayChannel('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs);
rxchannel = twoRayChannel('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs);
Nsweep = 64;
xr = helperFMCWTwoRaySimulate(Nsweep,waveform,radarmotion,carmotion,...
    transmitter,txchannel,rxchannel,cartarget,receiver);
nexttile
plotResponse(rngdopresp,xr);   
title("Two-ray propagation");% Plot range Doppler map
axis([-v_max v_max 0 range_max]);
caxis(clim);

%%
% With all settings remaining same, the comparison of the resulting
% range-Doppler map with two-ray propagation and the range-Doppler map
% obtained before with a line of sight (LOS) propagation channel suggests
% that the signal strength dropped almost 40 dB, which is significant.
% Therefore, such effect must be considered during the design. One possible
% choice is to form a very sharp beam on the vertical direction to null out
% the reflections.

%% Summary
% This example shows how to use FMCW signal to perform range and Doppler
% estimation in an automotive automatic cruise control application. The
% example also shows how to generate a range Doppler map from the received
% signal and how to use triangle sweep to compensate for the
% range Doppler coupling effect for the FMCW signal. Finally, the effect on
% the signal level due to the multipath propagation is discussed.

%% References
%
% [1] Karnfelt, Camilla, et al. "77 GHz ACC
% Radar Simulation Platform." _2009 9th International Conference on
% Intelligent Transport Systems Telecommunications, (ITST), IEEE, 2009_ , pp.
% 209&ndash;14. DOI.org (Crossref), https://doi.org/10.1109/ITST.2009.5399354.
%
% [2] Rohling, H., and M. M. Meinecke. "Waveform Design Principles for
% Automotive Radar Systems." _2001 CIE International Conference on Radar
% Proceedings (Cat No.01TH8559)_ , IEEE, 2001, pp. 1&ndash;4. DOI.org (Crossref),
% https://doi.org/10.1109/ICR.2001.984612.
%
% REFERENCE CRUISE CONTROL MATLAB THING


