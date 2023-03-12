%{
%% IMPORT RECORDED DATA
Imports recorded data, removes DC offset by subtracting the mean, and
applies a window function after converting data to complex samples

NOTE: Path must be added in the program calling this function
i.e. path relative to the call script so may need more or less../
addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/trig_fmcw_data/');
addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/trolley_test/');
addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/m4_rustenberg/');
addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/office/');

%}
function [fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = ...
import_data(sweeps, windowCoeffs)
    % Parameters
    fc = 24.005e9;
    c = physconst('LightSpeed');
    lambda = c/fc;
    tm = 1e-3;                      % Ramp duration
    bw = 240e6;                     % Bandwidth
    k = bw/tm;                      % Sweep slope
    % Data

% iq_tbl=readtable('rhs_iq_12_57_07.txt','Delimiter' ,' ');
% iq_tbl=readtable('rhs_iq_12_57_50.txt','Delimiter' ,' ');

% iq_tbl=readtable('IQ_tri_20kmh.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_30kmh.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_40kmh.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_50kmh.txt','Delimiter' ,' ');
iq_tbl=readtable('IQ_tri_60kmh.txt','Delimiter' ,' ');
% iq_tbl=readtable('IQ_tri_70kmh.txt','Delimiter' ,' ');

    % Split data
    t_stamps = [];
    i_up = table2array(iq_tbl(sweeps,1:200));
    i_dn = table2array(iq_tbl(sweeps,201:400));
    q_up = table2array(iq_tbl(sweeps,401:600));
    q_dn = table2array(iq_tbl(sweeps,601:800));
    
    % Compute voltage intervals
    max_voltage = 3.3;
	ADC_bits = 12;
	ADC_intervals = 2^ADC_bits;
    vinv = max_voltage/ADC_intervals;
    
    % Subtract the DC offset
    i_up = i_up*vinv - mean(i_up*vinv, 2);
    i_dn = i_dn*vinv - mean(i_dn*vinv, 2);
    q_up = q_up*vinv - mean(q_up*vinv, 2);
    q_dn = q_dn*vinv - mean(q_dn*vinv, 2);

    % Create complex number and apply window coefficients
    iq_u = (i_up + 1i*q_up).*windowCoeffs;
    iq_d = (i_dn + 1i*q_dn).*windowCoeffs;

   return