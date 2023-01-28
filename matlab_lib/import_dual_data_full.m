function [fc, c, lambda, tm, bw, k, rpi_iq_u, rpi_iq_d,...
    usb_iq_u, usb_iq_d, t_stamps] = import_dual_data_full(lhs_rad, ...
    rhs_rad, subset)
    % Parameters
    fc = 24.005e9;
    c = physconst('LightSpeed');
    lambda = c/fc;
    tm = 1e-3;                      % Ramp duration
    bw = 240e6;                     % Bandwidth
    k = bw/tm;                      % Sweep slope
    % Data
    % NOTE: Path must be added in the program calling this function
    % i.e. path is relative to the call function so may need more or less
    % ../
    lhs_rad_tbl=readtable(lhs_rad,'Delimiter' ,' ');
    rhs_rad_tbl=readtable(rhs_rad,'Delimiter' ,' ');
%     t_stamps = iq_tbl.Var801;
    t_stamps = [];
%     size(lhs_rad_tbl)
%     size(rhs_rad_tbl)
    lhs_i_up = table2array(lhs_rad_tbl(subset,1:200));
    lhs_i_dn = table2array(lhs_rad_tbl(subset,201:400));
    lhs_q_up = table2array(lhs_rad_tbl(subset,401:600));
    lhs_q_dn = table2array(lhs_rad_tbl(subset,601:800));

    usb_i_up = table2array(rhs_rad_tbl(subset,1:200));
    usb_i_dn = table2array(rhs_rad_tbl(subset,201:400));
    usb_q_up = table2array(rhs_rad_tbl(subset,401:600));
    usb_q_dn = table2array(rhs_rad_tbl(subset,601:800));

    
    % Square Law detector
    rpi_iq_u= lhs_i_up.^2 + lhs_i_dn.^2;
    rpi_iq_d = lhs_q_up.^2 + lhs_q_dn.^2;

    usb_iq_u= usb_i_up.^2 + usb_i_dn.^2;
    usb_iq_d = usb_q_up.^2 + usb_q_dn.^2;
   return