%{
%% IMPORT RECORDED DATA
Imports recorded data, removes DC offset by subtracting the mean, and
applies a window function after converting data to complex samples
%}
function [fc, c, lambda, tm, bw, k, i_up, i_dn, q_up, q_dn, ...
    i_up_mc, i_dn_mc, q_up_mc, q_dn_mc, t_stamps] = ...
import_iq(sweeps)
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
% addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/trig_fmcw_data/');
% addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/trolley_test/');
% addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/m4_rustenberg/');
% addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/office/');
% iq_tbl=readtable('IQ_usb.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_20kmh.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_30kmh.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_40kmh.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_50kmh.txt','Delimiter' ,' ');
iq_tbl=readtable('IQ_tri_60kmh.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_70kmh.txt','Delimiter' ,' ');

% iq_tbl=readtable('IQ_tri_240_200_12-02-23.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_240_200_07-31-53.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_0_8192_sweeps.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_240_200_2022-07-08 11-16-07.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_240_200_2022-07-08 11-17-09.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_240_200_2022-07-08 11-18-14.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_240_200_2022-07-08 11-19-11.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_240_200_2022-07-08 11-20-05.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_240_200_2022-07-08 11-20-57.txt','Delimiter' ,' ');

%     t_stamps = iq_tbl.Var801;
    t_stamps = [];
    i_up = table2array(iq_tbl(sweeps,1:200));
    i_dn = table2array(iq_tbl(sweeps,201:400));
    q_up = table2array(iq_tbl(sweeps,401:600));
    q_dn = table2array(iq_tbl(sweeps,601:800));
    
    % Filter DC
    max_voltage = 3.3;
	ADC_bits = 12;
	ADC_intervals = 2^ADC_bits;
    vinv = max_voltage/ADC_intervals;

    i_up_mc = i_up*vinv - mean(i_up*vinv, 2);
    i_dn_mc = i_dn*vinv - mean(i_dn*vinv, 2);
    q_up_mc = q_up*vinv - mean(q_up*vinv, 2);
    q_dn_mc = q_dn*vinv - mean(q_dn*vinv, 2);

   return