function [rhs_sig, lhs_sig] = sim_sweeps_dual_v2(Nsweep,waveform,...
    carmotion, transmitter, channel,lhs_cartarget, rhs_cartarget, ...
    receiver, Dn, Ns, ...
    radar_pos, radar_vel, lhs_ntarg, rhs_ntarg)

sweeptime = waveform.SweepTime;

Nsamp = round(waveform.SampleRate*sweeptime);

l_xr = complex(zeros(Nsamp,Nsweep));
r_xr = complex(zeros(Nsamp,Nsweep));

lhs_sig = complex(zeros(Ns,Nsweep));
rhs_sig = complex(zeros(Ns,Nsweep));

% Transmit FMCW waveform
sig = waveform();
txsig = transmitter(sig);

for m = 1:Nsweep
    % Update target positions
    [tgt_pos,tgt_vel] = carmotion(sweeptime);
    % Propagate the signal and reflect off each target
    l_rxsig = complex(zeros(Nsamp,lhs_ntarg));
    for n = 1:lhs_ntarg
        l_rxsig(:,n) = channel(txsig,radar_pos(:,1),tgt_pos(:,n), ...
            radar_vel(:,1),tgt_vel(:,n));
    end
    l_rxsig(:,n) = lhs_cartarget(l_rxsig(:,n));

    r_rxsig = complex(zeros(Nsamp,rhs_ntarg));
    % Sum rows - received sum of returns from each target
    l_rxsig = receiver(sum(l_rxsig,2));
    % Get intermediate frequency
    l_xr(:,m) = dechirp(l_rxsig,sig);
    % Sample at ADC sampling rate
    lhs_sig(:,m) = decimate(l_xr(:,m),Dn);

        % Sum rows - received sum of returns from each target
    r_rxsig = receiver(sum(r_rxsig,2));
    % Get intermediate frequency
    r_xr(:,m) = dechirp(r_rxsig,sig);
    % Sample at ADC sampling rate
    lhs_sig(:,m) = decimate(r_xr(:,m),Dn);

    
end