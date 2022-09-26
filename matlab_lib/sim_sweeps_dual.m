function [rhs_sig, lhs_sig] = sim_sweeps_dual(Nsweep,waveform,...
    radarmotion,lhs_carmotion, rhs_carmotion,transmitter, ...
    channel,cartarget, receiver, Dn, Ns, lhs_ntarg, rhs_ntarg, ...
    lhs_radar_pos, lhs_radar_vel)

sweeptime = waveform.SweepTime;

Nsamp = round(waveform.SampleRate*sweeptime);

xr = complex(zeros(Nsamp,Nsweep));
lhs_sig = complex(zeros(Ns,Nsweep));
rhs_sig = complex(zeros(Ns,Nsweep));

Ntgt = numel(cartarget.MeanRCS);

rxsig = complex(zeros(Nsamp,Ntgt));

% Transmit FMCW waveform
sig = waveform();
txsig = transmitter(sig);

for m = 1:Nsweep
    % =====================================================================
    % Simulate LHS Radar
    % =====================================================================
    % Update target positions
    [tgt_pos,tgt_vel] = lhs_carmotion(sweeptime);
    % Propagate the signal and reflect off each target
    for n = 1:lhs_ntarg
        rxsig(:,n) = channel(txsig,radar_pos,tgt_pos(:,n), ...
            radar_vel,tgt_vel(:,n));
        rxsig(:,n) = cartarget(rxsig(:,n));
    end
    % Sum rows - received sum of returns from each target
    rxsig = receiver(sum(rxsig,2));
    % Get intermediate frequency
    xr(:,m) = dechirp(rxsig,sig);
    % Sample at ADC sampling rate
    lhs_sig(:,m) = decimate(xr(:,m),Dn);
    % =====================================================================
    % Simulate RHS Radar
    % =====================================================================
end