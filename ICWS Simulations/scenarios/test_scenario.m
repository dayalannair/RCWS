uRAD_sim;

% Create driving scenario
[scenario,egoCar,radarParams] = ...
    helperAutoDrivingRadarSigProc('Setup Scenario',c,fc);


% Initialize display for driving scenario example
helperAutoDrivingRadarSigProc('Initialize Display',egoCar,radarParams,...
    rxArray,fc,vMax,rangeMax);

tgtProfiles = actorProfiles(scenario);
tgtProfiles = tgtProfiles(2:end);
tgtHeight = [tgtProfiles.Height];

% Run the simulation loop
sweepTime = waveform.SweepTime;
while advance(scenario)
    
    % Get the current scenario time
    time = scenario.SimulationTime;
    
    % Get current target poses in ego vehicle's reference frame
    tgtPoses = targetPoses(egoCar);
    tgtPos = reshape([tgtPoses.Position],3,[]);
    % Position point targets at half of each target's height
    tgtPos(3,:) = tgtPos(3,:)+0.5*tgtHeight; 
    tgtVel = reshape([tgtPoses.Velocity],3,[]);
    
    % Assemble data cube at current scenario time
    Xcube = zeros(Nft,Ne,Nsweep);
    for m = 1:Nsweep
        
        ntgt = size(tgtPos,2);
        tgtStruct = struct('Position',mat2cell(tgtPos(:).',1,repmat(3,1,ntgt)),...
            'Velocity',mat2cell(tgtVel(:).',1,repmat(3,1,ntgt)),...
            'Signature',{rcsSignature,rcsSignature,rcsSignature});
        rxsig = radar(tgtStruct,time+(m-1)*sweepTime);
        % Dechirp the received signal
        rxsig = dechirp(rxsig,sig);
        
        % Save sweep to data cube
        Xcube(:,:,m) = rxsig;
        
        % Move targets forward in time for next sweep
        tgtPos = tgtPos+tgtVel*sweepTime;
    end
    
    % Calculate the range-Doppler response
    [Xrngdop,rnggrid,dopgrid] = rngdopresp(Xcube);
    
    % Beamform received data
    Xbf = permute(Xrngdop,[1 3 2]);
    Xbf = reshape(Xbf,Nr*Nd,Ne);
    Xbf = beamformer(Xbf);
    Xbf = reshape(Xbf,Nr,Nd);
    
    % Detect targets
    Xpow = abs(Xbf).^2;
    [detidx,noisepwr] = cfar(Xpow,idxCFAR);
    
    % Cluster detections
    [~,clusterIDs] = clusterer(detidx.');  
    
    % Estimate azimuth, range, and radial speed measurements
    [azest,azvar,snrdB] = ...
        helperAutoDrivingRadarSigProc('Estimate Angle',doaest,...
        conj(Xrngdop),Xbf,detidx,noisepwr,clusterIDs);
    azvar = azvar+radarParams.RMSBias(1)^2;
    
    [rngest,rngvar] = rngestimator(Xbf,rnggrid,detidx,noisepwr,clusterIDs);
    rngvar = rngvar+radarParams.RMSBias(2)^2;
    
    [rsest,rsvar] = dopestimator(Xbf,dopgrid,detidx,noisepwr,clusterIDs);
    
    % Convert radial speed to range rate for use by the tracker
    rrest = -rsest;
    rrvar = rsvar;
    rrvar = rrvar+radarParams.RMSBias(3)^2;
    
    % Assemble object detections for use by tracker
    numDets = numel(rngest);
    dets = cell(numDets,1);
    for iDet = 1:numDets
        dets{iDet} = objectDetection(time,...
            [azest(iDet) rngest(iDet) rrest(iDet)]',...
            'MeasurementNoise',diag([azvar(iDet) rngvar(iDet) rrvar(iDet)]),...
            'MeasurementParameters',{radarParams},...
            'ObjectAttributes',{struct('SNR',snrdB(iDet))});
    end
    
    % Track detections
    tracks = tracker(dets,time);
    
    % Update displays
    helperAutoDrivingRadarSigProc('Update Display',egoCar,dets,tracks,...
        dopgrid,rnggrid,Xbf,beamscan,Xrngdop);
    
    % Collect free space channel metrics
    metricsFS = helperAutoDrivingRadarSigProc('Collect Metrics',...
        radarParams,tgtPos,tgtVel,dets);
end


% Multi path not added

