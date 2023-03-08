function xr_d = simulate_sweeps(Nsweep,waveform,...
    radarmotion,carmotion,transmitter,channel,cartarget,receiver, Dn, Ns, tm)

sweeptime = waveform.SweepTime;

Nsamp = round(waveform.SampleRate*sweeptime);

% xr = complex(zeros(Nsamp,Nsweep));
xr_d = complex(zeros(Ns,Nsweep));

Ntgt = numel(cartarget.MeanRCS);

% Transmit FMCW waveform
sig = waveform();
txsig = transmitter(sig);
updateRcs = true;
for m = 1:Nsweep
    % Update radar and target positions
    [radar_pos,radar_vel] = radarmotion(sweeptime + tm);
    [tgt_pos,tgt_vel] = carmotion(sweeptime + tm);
    
    % Propagate the signal and reflect off each target
    rxsig = complex(zeros(Nsamp,Ntgt));
    for n = 1:Ntgt
        rxsig(:,n) = channel(txsig,radar_pos(:,1),tgt_pos(:,n), ...
            radar_vel(:,1),tgt_vel(:,n));
    end
    rxsig = cartarget(rxsig, updateRcs);
    % Sum rows - received sum of returns from each target
    rxsig = receiver(sum(rxsig,2));

    % Get intermediate frequency
    xd = dechirp(rxsig,sig);
%     xr(:,m) = xd;
    % Sample at ADC sampling rate
    xr_d(:,m) = decimate(xd,Dn);
end