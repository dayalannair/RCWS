subset = 900:1100;
addpath('../../../matlab_lib/');
addpath(['../../../../../OneDrive - ' ...
    'University of Cape Town/RCWS_DATA/car_driveby/']);
[fc, c, lambda, tm, bw, k, i_up, i_dn, q_up, q_dn, ...
    i_up_mc, i_dn_mc, q_up_mc, q_dn_mc, t_stamps] = import_iq(subset);


iq_u = abs(i_up + 1i.*q_up);
iq_d = abs(i_dn + 1i.*q_dn);

iq_u_mc = abs(i_up_mc + 1i.*q_up_mc);
iq_d_mc = abs(i_dn_mc + 1i.*q_dn_mc);

close all
figure()
tiledlayout(2,2)
nexttile
p1 = plot(iq_u(1, :));
title("IQ UP");
nexttile
p2 = plot(iq_u_mc(1, :));
title("IQ UP MC");

nexttile
p3 = plot(iq_d(1, :));
title("IQ DN");
nexttile
p4 = plot(iq_d_mc(1, :));
title("IQ DN MC")

n_sweeps = size(iq_u,1);
for i = 1: n_sweeps

    set(p1, 'YData',iq_u(i, :))
    set(p2, 'YData',iq_d(i, :))
    set(p3, 'YData',iq_u_mc(i, :))
    set(p4, 'YData',iq_d_mc(i, :))
    drawnow;

end

