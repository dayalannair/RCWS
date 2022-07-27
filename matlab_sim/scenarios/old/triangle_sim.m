rng(2012);
example_radar_model;
%uRAD_model;

car_dist = 100;
car_speed = -96*1000/3600;
car_rcs = db2pow(min(10*log10(car_dist)+5,20));

cartarget = phased.RadarTarget('MeanRCS',car_rcs,'PropagationSpeed',c,...
    'OperatingFrequency',fc);
carmotion = phased.Platform('InitialPosition',[car_dist;0;0.5],...
    'Velocity',[car_speed;0;0]);

channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs, ...
    'TwoWayPropagation',true);

radar_speed = 0;%100*1000/3600;
radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);

specanalyzer = dsp.SpectrumAnalyzer('SampleRate',fs,...
    'PlotAsTwoSidedSpectrum',true,...
    'Title','Spectrum for received and dechirped signal',...
    'ShowLegend',true);

Nsweep = 16;
% Triangle wave sim
xr = helperFMCWSimulate(Nsweep,waveform,radarmotion,carmotion,...
    transmitter,channel,cartarget,receiver);

% get up and down chirp beat frequencies
fbu_rng = rootmusic(pulsint(xr(:,1:2:end),'coherent'),1,fs);
fbd_rng = rootmusic(pulsint(xr(:,2:2:end),'coherent'),1,fs);

rng_est = beat2range([fbu_rng fbd_rng],sweep_slope,c)

fd = -(fbu_rng+fbd_rng)/2;
v_est = dop2speed(fd,lambda)/2