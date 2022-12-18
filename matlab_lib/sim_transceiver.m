function xr_d = sim_transceiver(transceiver, Dn, simTime, tgt1, tgt2)
% function xr_d = sim_transceiver(transceiver, Dn, simTime, cartarget)
    disp(tgt2)
    disp(simTime)
% Transceiver has the waveform and tx and rx antennas and HW baked in
% It likely performs dechirp internally
%     rxsig = transceiver([tgt1 tgt2], simTime);
    rxsig = transceiver(tgt2, simTime);
    
%     for o = 1:16
%         plot(abs(rxsig(:,o)))
%         pause(0.5)
%         disp(o)
%     end

    % sum received signals from each antenna element
    rxsig = sum(rxsig,2);

    % Decimate and apply 200-tap anti-aliasing FIR filter
    xr_d = abs(decimate(rxsig,Dn, 200, "fir"));
%     xr_d = rxsig;
end