function [fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(sweeps)
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
    addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/trig_fmcw_data/');
    iq_tbl=readtable('IQ_0_8192_sweeps.txt','Delimiter' ,' ');
    t_stamps = iq_tbl.Var801;
    i_up = table2array(iq_tbl(sweeps,1:200));
    i_down = table2array(iq_tbl(sweeps,201:400));
    q_up = table2array(iq_tbl(sweeps,401:600));
    q_down = table2array(iq_tbl(sweeps,601:800));
    
    % Square Law detector
    iq_u= i_up.^2 + q_up.^2;
    iq_d = i_down.^2 + q_down.^2;

    % Normal
%     iq_u= i_up + 1i*q_up;
%     iq_d = i_down + 1i*q_down;
   return