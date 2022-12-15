% function xr_d = sim_transceiver(transceiver, Dn, simTime, tgt1, tgt2)
function xr_d = sim_transceiver(transceiver, Dn, simTime, cartarget)
    
    [sig, ] = transceiver(cartarget, simTime);
    xr_d = abs(decimate(sig,Dn));

end