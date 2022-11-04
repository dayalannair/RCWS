function [fc, c, lambda, tm, bw, k, rpi_iq_u, rpi_iq_d,...
    usb_iq_u, usb_iq_d, t_stamps] = import_dual_data_full(f_rad1, f_rad2)
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
    rpi_iq_tbl=readtable(f_rad1,'Delimiter' ,' ');
    usb_iq_tbl=readtable(f_rad2,'Delimiter' ,' ');
%     t_stamps = iq_tbl.Var801;
    t_stamps = [];
%     size(rpi_iq_tbl)
%     size(usb_iq_tbl)
    rpi_i_up = table2array(rpi_iq_tbl(:,1:200));
    rpi_i_dn = table2array(rpi_iq_tbl(:,201:400));
    rpi_q_up = table2array(rpi_iq_tbl(:,401:600));
    rpi_q_dn = table2array(rpi_iq_tbl(:,601:800));

    usb_i_up = table2array(usb_iq_tbl(:,1:200));
    usb_i_dn = table2array(usb_iq_tbl(:,201:400));
    usb_q_up = table2array(usb_iq_tbl(:,401:600));
    usb_q_dn = table2array(usb_iq_tbl(:,601:800));

    
    % Square Law detector
    rpi_iq_u= rpi_i_up.^2 + rpi_i_dn.^2;
    rpi_iq_d = rpi_q_up.^2 + rpi_q_dn.^2;

    usb_iq_u= usb_i_up.^2 + usb_i_dn.^2;
    usb_iq_d = usb_q_up.^2 + usb_q_dn.^2;
   return