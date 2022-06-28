function [fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(sweeps)
    % Parameters
    fc = 24.005e9;
    c = physconst('LightSpeed');
    lambda = c/fc;
    tm = 1e-3;                      % Ramp duration
    bw = 240e6;                     % Bandwidth
    k = bw/tm;                      % Sweep slope
    
    % Data
    iq_tbl=readtable('trig_fmcw_data\IQ_0_1024_sweeps.txt','Delimiter' ,' ');
    t_stamps = iq_tbl.Var801;
    i_up = table2array(iq_tbl(sweeps,1:200));
    i_down = table2array(iq_tbl(sweeps,201:400));
    q_up = table2array(iq_tbl(sweeps,401:600));
    q_down = table2array(iq_tbl(sweeps,601:800));
    
    iq_u= i_up + 1i*q_up;
    iq_d = i_down + 1i*q_down;
   return