function [lhs_xr, rhs_xr] = sim_dual_radar(Nsweep,waveform,...
    radarmotion,carmotion,transmitter,channel,cartarget,receiver, Dn, Ns)

sweeptime = waveform.SweepTime;

Nsamp = round(waveform.SampleRate*sweeptime);

% xr = complex(zeros(Nsamp,Nsweep));

lhs_xr = complex(zeros(Ns,Nsweep));
rhs_xr = complex(zeros(Ns,Nsweep));

Ntgt = numel(cartarget.MeanRCS);

% Transmit FMCW waveform
sig = waveform();
txsig = transmitter(sig);
    
for m = 1:Nsweep

    % Update radar and target positions
    [radar_pos,radar_vel] = radarmotion(sweeptime);
    [tgt_pos,tgt_vel] = carmotion(sweeptime);

    % Propagate the signal and reflect off each target
    lhs_rx = complex(zeros(Nsamp,Ntgt));
    rhs_rx = complex(zeros(Nsamp,Ntgt));

    for tgt = 1:Ntgt
        lhs_rx(:,tgt) = channel(txsig,radar_pos(:,1), ...
            tgt_pos(:,tgt), radar_vel(:,1),tgt_vel(:,tgt));
        
        rhs_rx(:,tgt) = channel(txsig,radar_pos(:,2), ...
            tgt_pos(:,tgt), radar_vel(:,2),tgt_vel(:,tgt));
    end


    % Left side radar
    % --------------------------------------------------------
    lhs_rx = cartarget(lhs_rx);
    % Sum rows - received sum of returns from each target
    lhs_rx = receiver(sum(lhs_rx,2));
    % Get intermediate frequency
    xd = dechirp(lhs_rx,sig);
%     xr(:,m) = xd;
    % Sample at ADC sampling rate
    lhs_xr(:,m) = decimate(xd,Dn);
    
    % Right side radar
    % --------------------------------------------------------
    rhs_rx = cartarget(rhs_rx);
    % Sum rows - received sum of returns from each target
    rhs_rx = receiver(sum(rhs_rx,2));
    % Get intermediate frequency
    xd = dechirp(rhs_rx,sig);
%     xr(:,m) = xd;
    % Sample at ADC sampling rate
    rhs_xr(:,m) = decimate(xd,Dn);

end