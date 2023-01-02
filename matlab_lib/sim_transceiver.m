function xr_d = sim_transceiver(transceiver, Dn, simTime, tgt1, tgt2)
% function xr_d = sim_transceiver(transceiver, Dn, simTime, cartarget)
%     disp(tgt2)
%     disp(simTime)
% Transceiver has the waveform and tx and rx antennas and HW baked in
% It likely performs dechirp internally
%     rxsig = transceiver([tgt1 tgt2], simTime);
    [rxsig, info] = transceiver(tgt2, simTime);
    disp(info.Orientation)
%     for o = 1:16
%         plot(abs(rxsig(:,o)))
%         pause(0.5)
%         disp(o)
%     end

    % sum received signals from each antenna element
    rxsig = sum(rxsig,2);

%     elmt1 = sum(rxsig(:,1:4:end),2);
%     elmt2 = sum(rxsig(:,2:4:end),2);
%     elmt3 = sum(rxsig(:,3:4:end),2);
%     elmt4 = sum(rxsig(:,4:4:end),2);
%     figure(2)
%     tiledlayout(2,2)
%     nexttile
%     plot(elmt1(1:100))
%     nexttile
%     plot(elmt2(1:100))
%     nexttile
%     plot(elmt3(1:100))
%     nexttile
%     plot(elmt4(1:100))
%     disp(size(elmt1))
    % Decimate and apply 200-tap anti-aliasing FIR filter
%     xr_d = abs(decimate(rxsig,Dn, 200, "fir"));
%     xr_d = abs(decimate(elmt1,Dn, 200, "fir"));

%     xr_d = elmt1(1:1200:end);
    xr_d = rxsig(1:1200:end);

end