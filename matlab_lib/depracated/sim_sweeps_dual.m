function [rhs_sig, lhs_sig] = sim_sweeps_dual(Nsweep,waveform,...
    lhs_carmotion, rhs_carmotion,transmitter, ...
    channel,lhs_cartarget, rhs_cartarget, receiver, Dn, Ns, ...
    lhs_ntarg, rhs_ntarg, ...
    radar_pos, radar_vel)

sweeptime = waveform.SweepTime;

Nsamp = round(waveform.SampleRate*sweeptime);

xr = complex(zeros(Nsamp,Nsweep));
lhs_sig = complex(zeros(Ns,Nsweep));
rhs_sig = complex(zeros(Ns,Nsweep));

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
    rxsig = complex(zeros(Nsamp, lhs_ntarg));
    for n = 1:lhs_ntarg
        rxsig(:,n) = channel(txsig,radar_pos,tgt_pos(:,n), ...
            radar_vel,tgt_vel(:,n));
        
    end
    rxsig = lhs_cartarget(rxsig);
    % Sum rows - received sum of returns from each target
    rxsig = receiver(sum(rxsig,2));
    % Get intermediate frequency
    xr(:,m) = dechirp(rxsig,sig);
    % Sample at ADC sampling rate
    lhs_sig(:,m) = decimate(xr(:,m),Dn);
    lhs_sig = lhs_sig.';
    % =====================================================================
    % Simulate RHS Radar
    % =====================================================================
    % Update target positions
    [tgt_pos,tgt_vel] = rhs_carmotion(sweeptime);
    % Propagate the signal and reflect off each target
    rxsig = complex(zeros(Nsamp,rhs_ntarg));
    for n = (lhs_ntarg+1):rhs_ntarg
        rxsig(:,n) = channel(txsig,radar_pos,tgt_pos(:, n), ...
            radar_vel,tgt_vel(:, n));
    end
    rxsig = rhs_cartarget(rxsig);
    % Sum rows - received sum of returns from each target
    rxsig = receiver(sum(rxsig,2));
    % Get intermediate frequency
    xr(:,m) = dechirp(rxsig,sig);
    % Sample at ADC sampling rate
    rhs_sig(:,m) = decimate(xr(:,m),Dn);
    rhs_sig = rhs_sig.';
end