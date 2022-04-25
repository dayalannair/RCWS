function [xr,xr_unmixed] = simulate_sweeps(Nsweep,waveform,...
    radarmotion,carmotion,transmitter,channel,cartarget,receiver)

%   The rows of RSWEEP represent fast time and its columns represent slow
%   time (pulses). When the pulse transmitter uses staggered PRFs, the
%   length of the fast time sequences is determined by the highest PRF.

sweeptime = waveform.SweepTime;

Nsamp = round(waveform.SampleRate*sweeptime);

xr = complex(zeros(Nsamp,Nsweep));
xr_unmixed = xr;

Ntgt = numel(cartarget.MeanRCS);
for m = 1:Nsweep
    % Update radar and target positions
    [radar_pos,radar_vel] = radarmotion(sweeptime);
    [tgt_pos,tgt_vel] = carmotion(sweeptime);

    % Transmit FMCW waveform
    sig = waveform();
    txsig = transmitter(sig);

    % Propagate the signal and reflect off the target
    rxsig = complex(zeros(Nsamp,Ntgt));
    for n = 1:Ntgt
        rxsig(:,n) = channel(txsig,radar_pos,tgt_pos(:,n),radar_vel,tgt_vel(:,n));
    end
    rxsig = cartarget(rxsig);
    
    % Dechirp the received radar return
    rxsig = receiver(sum(rxsig,2));
    xd = dechirp(rxsig,sig);
    xr_unmixed(:,m) = rxsig;
    xr(:,m) = xd;
end
