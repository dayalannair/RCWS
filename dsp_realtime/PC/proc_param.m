% Get radar parameters
% Deprecated:
% can set these in python and add to workspace
function [c, lda, k, Ns] = proc_param() 
    fc = 24.005e9;
    c = physconst('LightSpeed');
    lda = c/fc;
    tm = 1e-3;                      % Ramp duration
    bw = 240e6;                     % Bandwidth
    k = bw/tm;                      % Sweep slope
    Ns = 200;
end