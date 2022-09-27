function xr_d = simulate_sweeps(Nsweep,waveform,...
    radarmotion,carmotion,transmitter,channel,cartarget,receiver, Dn, Ns)

sweeptime = waveform.SweepTime;

Nsamp = round(waveform.SampleRate*sweeptime);

xr = complex(zeros(Nsamp,Nsweep));
xr_d = complex(zeros(Ns,Nsweep));

Ntgt = numel(cartarget.MeanRCS);

for m = 1:Nsweep
    % Update radar and target positions
    [radar_pos,radar_vel] = radarmotion(sweeptime);
    [tgt_pos,tgt_vel] = carmotion(sweeptime);

    % Transmit FMCW waveform
    sig = waveform();
    txsig = transmitter(sig);
    
    % Propagate the signal and reflect off each target
    rxsig = complex(zeros(Nsamp,Ntgt));
    for n = 1:Ntgt
        rxsig(:,n) = channel(txsig,radar_pos,tgt_pos(:,n), ...
            radar_vel,tgt_vel(:,n));
    end
    rxsig = cartarget(rxsig);
    % Sum rows - received sum of returns from each target
    rxsig = receiver(sum(rxsig,2));

    % Get intermediate frequency
    xd = dechirp(rxsig,sig);
    xr(:,m) = xd;
    % Sample at ADC sampling rate
    xr_d(:,m) = decimate(xr(:,m),Dn);
end