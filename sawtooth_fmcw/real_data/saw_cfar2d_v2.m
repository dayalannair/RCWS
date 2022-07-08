% Parameters
close all
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;                   
bw = 75e6;         
fs = 200e3;
n = 40;
t_sweep = n/fs; 
sweep_slope = bw/t_sweep;
r_max = c*n/(4*bw);
v_max = lambda/(4*t_sweep);
addpath('../../library/');

n_sweeps_per_frame = 128;
[iq, fft_frames, iq_frames, n_frames] = import_frames(n_sweeps_per_frame, n);

% Range Doppler Map
Nft = size(iq,1); % Number of fast-time samples
Nst = n_sweeps_per_frame; % Number of slow-time samples
Nr = 2^nextpow2(Nft); % Number of range samples 
Nd = 2^nextpow2(Nst); % Number of Doppler samples 
rdresp = phased.RangeDopplerResponse('RangeMethod','FFT',...
    'DopplerOutput','Speed','SweepSlope',sweep_slope,...
    'RangeFFTLengthSource','Property','RangeFFTLength',Nr,...
    'RangeWindow','Hann',...
    'DopplerFFTLengthSource','Property','DopplerFFTLength',Nd,...
    'DopplerWindow','Hann',...
    'PropagationSpeed',c,'OperatingFrequency',fc,'SampleRate',fs);

% CFAR 2D
nGuardRng = 4;
nTrainRng = 4;
nCUTRng = 1+nGuardRng+nTrainRng;

dopOver = round(Nd/n_sweeps_per_frame);
nGuardDop = 4*dopOver;
nTrainDop = 4*dopOver;
nCUTDop = 1+nGuardDop+nTrainDop;
F = 0.011;
% NOTE: had to use false alarm instead of threshold

% cfar = phased.CFARDetector2D('GuardBandSize',[nGuardRng nGuardDop],...
%     'TrainingBandSize',[nTrainRng nTrainDop],...
%     'ThresholdFactor','Custom','CustomThresholdFactor',db2pow(13),...
%     'NoisePowerOutputPort',true,'OutputFormat','Detection index');
cfar = phased.CFARDetector2D('GuardBandSize',[nGuardRng nGuardDop],...
    'TrainingBandSize',[nTrainRng nTrainDop],...
    'ProbabilityFalseAlarm', F ,'ThresholdFactor','Auto',...
    'NoisePowerOutputPort',true,'OutputFormat','Detection index');
% Perform CFAR processing over all of the range and Doppler cells
freqs = ((0:Nr-1)'/Nr-0.5)*fs;
rnggrid = beat2range(freqs,sweep_slope);
iRngCUT = find(rnggrid>0);
iRngCUT = iRngCUT((iRngCUT>=nCUTRng)&(iRngCUT<=Nr-nCUTRng+1));
iDopCUT = nCUTDop:(Nd-nCUTDop+1);
[iRng,iDop] = meshgrid(iRngCUT,iDopCUT);
idxCFAR = [iRng(:) iDop(:)]';

% Perform clustering algorithm to group detections
clusterer = clusterDBSCAN('Epsilon',2);

rangeRes = bw2rangeres(bw,c);
rmsRng = sqrt(12)*rangeRes;
rngestimator = phased.RangeEstimator('ClusterInputPort',true,...
    'VarianceOutputPort',true,'NoisePowerSource','Input port',...
    'RMSResolution',rmsRng);

dopestimator = phased.DopplerEstimator('ClusterInputPort',true,...
    'VarianceOutputPort',true,'NoisePowerSource','Input port',...
    'NumPulses',n_sweeps_per_frame);

tracker = radarTracker('FilterInitializationFcn',@initcvekf,...
    'AssignmentThreshold',50);

% figure('WindowState','maximized');
% movegui('east')

% clf;
% plotResponse(rdresp,iq_frames);    
% axis([-v_max v_max 0 r_max])
% clim = caxis;
radarParams = struct( ...
    'Frame', 'rectangular', ...
    'OriginPosition',zeros(3,1), ...
    'OriginVelocity',zeros(3,1), ...
    'Orientation', [1 0 0; 0 1 0; 0 0 1], ...
    'HasElevation', false, ...
    'HasAzimuth', false, ...
    'HasRange', true, ...
    'HasVelocity', true);%, ...
    %'RMSBias',[0 0.25 0.05]);

rng_array = zeros(38,1);
vel_array = zeros(38,1);

for frame = 1:n_frames
%     clf;
%     plotResponse(rdresp,iq_frames(:,:,frame));    
%     axis([-v_max v_max 0 r_max])
%     clim = caxis;
%     pause(0.2)

    % Calculate the range-Doppler response
    [Xrngdop,rnggrid,dopgrid] = rdresp(iq_frames(:,:,frame));
    % Detect targets
    [detidx,noisepwr] = cfar(abs(Xrngdop),idxCFAR);
    % Cluster detections
    [~,clusterIDs] = clusterer(detidx.'); 
    [rngest,rngvar] = rngestimator(Xrngdop,rnggrid,detidx,noisepwr,clusterIDs);
    % NOTE: below is from helper scenario gen
    %     rngvar = rngvar+radarParams.RMSBias(2)^2;
    
    [rsest,rsvar] = dopestimator(Xrngdop,dopgrid,detidx,noisepwr,clusterIDs);
    
    % Convert radial speed to range rate for use by the tracker
    rrest = -rsest;
    rrvar = rsvar;
%     rrvar = rrvar+radarParams.RMSBias(3)^2;
    
    % Assemble object detections for use by tracker
    numDets = numel(rngest);
    dets = cell(numDets,1);
    for iDet = 1:numDets
        time = t_sweep*frame*n_sweeps_per_frame;
        % NOTE: see how time was added
        % STORE DATA IN RANGE AND VEL ARRAYS
        dets{iDet} = objectDetection(time,...
            [rngest(iDet) rrest(iDet)]',...
            'MeasurementNoise',diag([rngvar(iDet) rrvar(iDet)]),...
            'MeasurementParameters',{radarParams});%,...
            %'ObjectAttributes',{struct('SNR',snrdB(iDet))});
    end
    
    % Track detections
%     tracks = tracker(dets,time);
    
% STORE DATA IN RANGE AND VEL ARRAYS

end
return;







