uRAD_model;

% Create driving scenario
% [scenario,egoCar,radarParams] = helperAutoDrivingRadarSigProc('Setup Scenario',c,fc);


%% Target model and platform
car_dist = 200; % distance in meters
car_speed = -1; % speed in m/s
car_rcs = db2pow(min(10*log10(car_dist)+5,20)); % check calculation
cartarget = phased.RadarTarget('MeanRCS',car_rcs,...
    'PropagationSpeed',c,...
    'OperatingFrequency',fc);
carmotion = phased.Platform('InitialPosition',[car_dist;0;0.5],...
    'Velocity',[car_speed;0;0]);

channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,...
    'SampleRate',fs,'TwoWayPropagation',true);

%% Radar platform
% Radar parameters defined in uRAD_sim.m
radar_speed = 0; % Stationary
% radar height = 0.5m above ground level
radarmotion = phased.Platform('InitialPosition',[0;0;0.5], 'Velocity',[radar_speed;0;0]);

%% Spectrum Analyser
%  specanalyzer = dsp.SpectrumAnalyzer('SampleRate',fs,...
%      'PlotAsTwoSidedSpectrum',true,...
%      'Title','Spectrum for received and dechirped signal',...
%      'ShowLegend',true);

%% Simulation loop

% Seed for noise generation?
rng(2012);
% number of FMCW sweeps
Nsweep = 50;
rxsig = complex(zeros(waveform.SampleRate*waveform.SweepTime, Nsweep));
size(rxsig);
sweep_duration = waveform.SweepTime
%T = 1/waveform.PRF;
tau = 0.01;

% number of simulation steps    
num_steps = 400;
t_step = 1; % 1 second step duration
% number of pulses integrated per step
num_pulse_int = 1; 

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
    'UpdateRate',1/t_step);
%m = 0;
%tgt_pos = 200;
%while (tgt_pos(1)>0)
    %m = m + 1;
Nsamp = round(waveform.SampleRate*sweep_duration);
xr = complex(zeros(Nsamp,Nsweep));
xr_unmixed = xr;

%for i = 1:num_steps

for m = 1:num_steps
    % current radar position and velocity
    [radar_pos,radar_vel] = radarmotion(t_step); % will remain constant. determine if array
    % current target position and velocity
    [tgt_pos,tgt_vel] = carmotion(t_step);
    %[tgt_pos,tgt_vel] = step(carmotion, Nsweep);
    % create FMCW waveform
    ref_sig = waveform();
    % pass generated waveform to transmitter
    txsig = transmitter(ref_sig);

    if (tgt_pos(1) ~= 0)

        % propagate signal in free space when radar and car are at a given position with a certain velocity
        txsig = channel(txsig,radar_pos,tgt_pos,radar_vel,tgt_vel); 
        % signal reflected off of target car
        echo_sig = cartarget(txsig); 
    
        % Store received complex signal
        % size(receiver(txsig))
        
        % obtain actual range for comparison
        %[tgtrng,tgtang] = rangeangle(targetplatform.InitialPosition, ...
        %antennaplatform.InitialPosition);
    
        % amplify reflected signal using receiver pre-amp
        %rxsig(:,m) = receiver(echo_sig); 
        
        % Dechirp the received radar return
        rxsig = receiver(sum(rxsig,2));
        xd = dechirp(rxsig,sig);
        xr_unmixed(:,m) = rxsig;
        xr(:,m) = xd;

        % Visualize the spectrum
        % specanalyzer(rxsig(:,m));
        
        sceneview(radar_pos,radar_vel,tgt_pos,tgt_vel);
        drawnow;
    end
end

%end
% local oscillator frequency
f_lo = fifMax + fc;
%plot(real(rxsig))



