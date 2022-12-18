function xr_d = sim_transceiver(transceiver, Dn, simTime, tgt1, tgt2)
% function xr_d = sim_transceiver(transceiver, Dn, simTime, cartarget)

% Transceiver has the waveform and tx and rx antennas and HW baked in
% It likely performs dechirp internally
    rxsig = transceiver([tgt1 tgt2], simTime);
    % sum received signals from each antenna element
    rxsig = sum(rxsig,2);
    % Decimate and apply 200-tap anti-aliasing FIR filter
    xr_d = abs(decimate(rxsig,Dn, 200, "fir"));
%     xr_d = rxsig;
end