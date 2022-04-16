 % Source: https://lost-contact.mit.edu/afs/inf.ed.ac.uk/group/teaching/matlab-help/R2016b/phased/examples/automotive-adaptive-cruise-control-using-fmcw-technology.html

phased_scenario2;

rngdopresp = phased.RangeDopplerResponse('PropagationSpeed',c,...
    'DopplerOutput','Speed','OperatingFrequency',fc,'SampleRate',fs,...
    'RangeMethod','FFT','SweepSlope',sweep_slope,...
    'RangeFFTLengthSource','Property','RangeFFTLength',2048,...
    'DopplerFFTLengthSource','Property','DopplerFFTLength',256);

clf;
plotResponse(rngdopresp,xr);                     % Plot range Doppler map
axis([-v_max v_max 0 range_max])
clim = caxis;


%% Range-Doppler decoupling
% ensure value remains small
deltaR = rdcoupling(fd,sweep_slope,c)


%% Changing sweep duration
% the sweep duration must be chosen for the specific application
% generally, cars move slowly and so a longer sweep duration can be used
waveform_tr = clone(waveform);
release(waveform_tr);
tm = 2e-3;
waveform_tr.SweepTime = tm;
sweep_slope = bw/tm;

% Note this will increase the RD coupling
deltaR = rdcoupling(fd,sweep_slope,c)

% Note effect on max unambiguous speed: should decrease for increase in
% sweep duration
v_unambiguous = dop2speed(1/(2*tm),lambda)/2
%% FOR MOVING RADAR:
% Decimation to reduce hardware cost
% this can be done becaused sampling rate need only correspond to the 
% maximum beat frequency

% Dn = fix(fs/(2*fb_max));
% for m = size(xr,2):-1:1
%     xr_d(:,m) = decimate(xr(:,m),Dn,'FIR');
% end
% fs_d = fs/Dn;
% 
% 
% fb_rng = rootmusic(pulsint(xr_d,'coherent'),1,fs_d);
% rng_est = beat2range(fb_rng,sweep_slope,c);
% 
% peak_loc = val2ind(rng_est,c/(fs_d*2));
% fd = -rootmusic(xr_d(peak_loc,:),1,1/tm);
% v_est = dop2speed(fd,lambda)/2


%% Triangle waveform
% This increases sweep time, so fewer sweeps are collected before
% processing
waveform_tr.SweepDirection = 'Triangle';

% Simulate
Nsweep = 16;
xr = helperFMCWSimulate(Nsweep,waveform_tr,radarmotion,carmotion,...
    transmitter,channel,cartarget,receiver);

% Separate processing for up and down sweeps
fbu_rng = rootmusic(pulsint(xr(:,1:2:end),'coherent'),1,fs);
fbd_rng = rootmusic(pulsint(xr(:,2:2:end),'coherent'),1,fs);

% Range and Doppler estimation
rng_est = beat2range([fbu_rng fbd_rng],sweep_slope,c)

fd = -(fbu_rng+fbd_rng)/2;
v_est = dop2speed(fd,lambda)/2

%% Two-ray propagation
% More accurate model: radar receives reflections from target adn road etc
% better to use multi path model
% Can be modelled as Two-ray: One directly from car, other from road
% reflection to target back to road back to host
% Affects the phase of the returned signal - effects coherent integration
% of signals
% Can interfere constructively or destructively causing signal fluctuation
% See image presented in RADAR LECTURES

txchannel = phased.TwoRayChannel('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs);
rxchannel = phased.TwoRayChannel('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs);
Nsweep = 64;
xr = helperFMCWTwoRaySimulate(Nsweep,waveform,radarmotion,carmotion,...
    transmitter,txchannel,rxchannel,cartarget,receiver);
plotResponse(rngdopresp,xr);                     % Plot range Doppler map
axis([-v_max v_max 0 range_max]);
caxis(clim);


