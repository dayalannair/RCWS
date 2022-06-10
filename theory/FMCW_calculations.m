%% Triangle FMCW - parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
t_sweep = 1e-3;                    
bw = 240e6;
sweep_slope = bw/t_sweep;
n_samples = 200;
v_max = 80/3.6;
% Resolutions
% note: targets must be separated in one of the two domains i.e. by 1.5m or
% by 3 m/s
rng_res = 1.5; % or different velocity
vel_res = 3; % or different distance
% note: factor in accuracy
% +/-
rng_acc = 0.04; % figure out the 0.3%
vel_acc = 0.25;

az_beam = 30;
el_beam = 30;
r_max = 50; % safe. Should be 62.5m (VERIFY)
%% Theoretical calculations

th_rng_res = c/2*bw
max_distance_per_sweep = v_max*t_sweep
az_res_50m = az_beam*r_max*pi/180

% VERIFY below
t_targ_in_range_bin = rng_res/v_max
% should allow this many sweeps per cell
% realistically far less

%% Optimised parameters
% This section calculates the optimised wave based on required distance and
% velocity

v_max = 60/3.6;
r_targ = 50;

% max time required to turn and match oncoming car speed
% reducing this parameter increases the required turn speed
t_turn_accel_max = 3;

t = r_targ/v_max
% reduced number of samples improves the update rate

n_samples = 160; 

% will be less in real scenario
r_max = 75*(n_samples/bw)*1e6

n_samples_50m = r_targ*bw/75e6

%% Resolution

f_res = 1/t_sweep

% may not be correct TBWP
TBWP = t_sweep*bw

%delta_r =

v_res = f_res*lambda/2
% ORRR
v_res = f_res/2 * lambda/2

%% Other
% Doppler shift due to vehicle traveling at maximum required speed
% 1.3 kHz
fd = speed2dop(v_max, lambda)*2
v = dop2speed(1e3, lambda)*3.6/2


