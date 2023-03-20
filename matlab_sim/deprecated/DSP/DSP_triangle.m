%phased_example;
uRAD_model_lite;
%example_radar_model;

car_dist = 50; % distance in meters
car_speed = 0; % speed in m/s

car_rcs = db2pow(min(10*log10(car_dist)+5,20)); % check calculation
cartarget = phased.RadarTarget('MeanRCS',car_rcs,...
    'PropagationSpeed',c,...
    'OperatingFrequency',fc);
carmotion = phased.Platform('InitialPosition',[car_dist;0;0.5],...
    'Velocity',[car_speed;0;0]);

channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,...
    'SampleRate',fs,'TwoWayPropagation',true);

% Radar parameters defined in uRAD_sim.m
radar_speed = 0; % Stationary
% radar height = 0.5m above ground level
radarmotion = phased.Platform('InitialPosition',[0;0;0.5], 'Velocity',[radar_speed;0;0]);

% Simulate
Nsweep = 16;
xr = helperFMCWSimulate(Nsweep,waveform,radarmotion,carmotion,...
     transmitter,channel,cartarget,receiver);

% Separate processing for up and down sweeps
fbu_rng = rootmusic(pulsint(xr(:,1:2:end),'coherent'),1,fs);
fbd_rng = rootmusic(pulsint(xr(:,2:2:end),'coherent'),1,fs);

% Range and Doppler estimation
rng_est = beat2range([fbu_rng fbd_rng],sweepSlope,c)

fd = -(fbu_rng+fbd_rng)/2;
v_est = dop2speed(fd,lambda)/2


rngdopresp = phased.RangeDopplerResponse('PropagationSpeed',c,...
    'DopplerOutput','Speed','OperatingFrequency',fc,'SampleRate',fs,...
    'RangeMethod','FFT','SweepSlope',sweepSlope,...
    'RangeFFTLengthSource','Property','RangeFFTLength',2048,...
    'DopplerFFTLengthSource','Property','DopplerFFTLength',256);

clf;

plotResponse(rngdopresp,xr);                     % Plot range Doppler map
axis([-v_max v_max 0 range_max])
clim = caxis;

