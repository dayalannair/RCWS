uRAD_model;
% Create driving scenario
% [scenario,egoCar,radarParams] = helperAutoDrivingRadarSigProc('Setup Scenario',c,fc);

%% Targets
d_car1 = 200; % distance in meters
v_car1 = -1; % speed in m/s
d_car2 = -100; % distance in meters
v_car2 = 1; % speed in m/s

car_rcs = db2pow(min(10*log10(car_dist)+5,20)); % check calculation

car1 = phased.RadarTarget('MeanRCS',car_rcs,...
    'PropagationSpeed',c,...
    'OperatingFrequency',fc);
car2 = phased.RadarTarget('MeanRCS',car_rcs,...
    'PropagationSpeed',c,...
    'OperatingFrequency',fc);

cars = phased.Platform('InitialPosition',[d_car1 d_car2;0 0;0.5 0.5],...
    'Velocity',[v_car1 v_car2;0 0;0 0]);

channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,...
    'SampleRate',fs,'TwoWayPropagation',true);

%% Radar platform
orientation  = cat(3, eye(3), [-1 0 0; 0 1 0; 0 0 1]);
% Radar parameters defined in uRAD_sim.m
% radar height = 0.5m above ground level
radars = phased.Platform('InitialPosition',[0 0;0 0;0.5 0.5], ...
    'Velocity', [0 0; 0 0; 0 0],...
    'InitialOrientationAxes', orientation);
%radar2 = phased.Platform('InitialPosition',[0;0;0.5]);
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

size(rxsig);
%T = 1/waveform.PRF;
tau = 0.01;

% number of simulation steps    
num_steps = 400;
t_step = 1; % 1 second step duration
% number of pulses integrated per step
num_pulse_int = 1; 

% Generate visuals
sceneview = phased.ScenarioViewer('BeamRange',[75 75],...
    'BeamWidth',[30 30; 30 30], ...
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

% could combine received signals into one matrix
rxsig1 = complex(zeros(waveform.SampleRate*waveform.SweepTime, Nsweep));
rxsig2 = complex(zeros(waveform.SampleRate*waveform.SweepTime, Nsweep));
%for i = 1:num_steps
% current radar position and velocity
[radar_pos, rad_v] = radars(t_step); % will remain constant. determine if array
v_rad = [0 0 0; 0 0 0];
for m = 1:num_steps
    
    % current target position and velocity
    [tgt_pos,tgt_vel] = carmotion(t_step);
    %[tgt_pos,tgt_vel] = step(carmotion, Nsweep);
    % create FMCW waveform
    sig = waveform();
    % pass generated waveform to transmitter
    txsig = transmitter(sig);

    if (tgt_pos(1) ~= 0)

        % propagate signal in free space when radar and car are at a given position with a certain velocity
        txsig1 = channel(txsig,radar_pos(:,1),tgt_pos(:,1),rad_v(:,1),tgt_vel(:,1)); 
        % signal reflected off of target car
        echo_sig1 = car1(txsig(1)); 
        echo_sig2 = car2(txsig(2)); 
        % Store received complex signal
        % size(receiver(txsig))
        
        % obtain actual range for comparison
        %[tgtrng,tgtang] = rangeangle(targetplatform.InitialPosition, ...
        %antennaplatform.InitialPosition);
    
        % amplify reflected signal using receiver pre-amp
        rxsig1(:,m) = receiver(echo_sig1); 
        rxsig2(:,m) = receiver(echo_sig2); 
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