
function [rhs_xr,lhs_xr] = sim_sweeps_2rdr(Nsweep,waveform,...
    radarmotion,carmotion,transmitter,channel,cartarget,receiver, Dn, Ns)

sweeptime = waveform.SweepTime;

Nsamp = round(waveform.SampleRate*sweeptime);

rhs_xr = complex(zeros(Nsamp,Nsweep));
lhs_xr = complex(zeros(Nsamp,Nsweep));

rhs_xr_dec = complex(zeros(Ns,Nsweep));
lhs_xr_dec = complex(zeros(Ns,Nsweep));

Ntgt = numel(cartarget.MeanRCS);

rhs_rxsig = complex(zeros(Nsamp,Ntgt));
lhs_rxsig = complex(zeros(Nsamp,Ntgt));
sig = waveform();

for m = 1:Nsweep
    % Update radar and target positions
    [radar_pos,radar_vel] = radarmotion(sweeptime);
    [tgt_pos,tgt_vel] = carmotion(sweeptime);

    % Transmit FMCW waveform
    txsig = transmitter(sig);
    
    % Propagate tx sig to each target
    for n = 1:Ntgt
        rhs_rxsig(:,n) = channel(txsig,radar_pos(:,1),tgt_pos(:,n), ...
            radar_vel(:,1),tgt_vel(:,n));
 
        lhs_rxsig(:,n) = channel(txsig,radar_pos(:,2),tgt_pos(:,n), ...
            radar_vel(:,2),tgt_vel(:,n));
    end


    rxsig = cartarget(rhs_rxsig);
    
    % Sum returns from each target
    rxsig_r = receiver(sum(rxsig(:,1),2));
    rxsig_l = receiver(sum(rxsig(:,2),2));

    xd = dechirp(rxsig_r,sig);
    rhs_xr(:,m) = xd;
    xd = dechirp(rxsig_l,sig);
    lhs_xr(:,m) = xd;

    rhs_xr_dec(:,m) = decimate(rhs_xr(:,m),Dn);
    lhs_xr_dec(:,m) = decimate(lhs_xr(:,m),Dn);
end