%% Triangle FMCW - parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
t_sweep = 1e-3;                    
bw = 240e6;
sweep_slope = bw/t_sweep;
n_samples_max = 200;
v_max = 60/3.6;
% Resolutions
% note: targets must be separated in one of the two domains i.e. by 1.5m or
% by 3 m/s
rng_res_datasheet = 1.5; % or different velocity

% FMCW range resolution = t_sweep/t_data * c/2B
fs = 200e3;
t_data = n_samples_max/fs;
rng_res_calc = t_sweep/t_data * (c/(2*bw))
% not equal to datasheet!

% same as above, as tdata = tsweep
rng_res_basic = c/(2*bw)

vel_res = 3; % or different distance
% note: factor in accuracy
% +/-
rng_acc = 0.04; % figure out the 0.3%
vel_acc = 0.25;

az_beam = 30;
el_beam = 30;
%r_max = 50; % safe. Should be 62.5m (VERIFY)
%% Theoretical calculations
r_max = 50;
th_rng_res = c/2*bw
% Max distance moved during a sweep
max_elta_per_sweep = v_max*t_sweep
% Extra/ not NB:
az_res_50m = az_beam*r_max*pi/180

% VERIFY below
v_max = 60/3.6
t_targ_in_range_bin = rng_res_datasheet/v_max

%% Optimised parameters
% This section calculates the optimised wave based on required distance and
% velocity

v_max = 70/3.6;
% Time taken to turn
t_turn = 3;
%Any targets travelling at <= v_max that are further than r_max
% will result in a safe turn and so do not need to be detected
% reduce by either reducing v_max or t_turn
r_max_required = v_max*t_turn
% Need to factor in distance moved while turning

%% Safety map

% target must be this far away in time
% equal to turn time
t_min = 3;
v_max = 60/3.6;

t_trig = 2*t_sweep;
t_proc = 1e-3
t_tot = t_trig + t_min + t_proc; 

speeds = linspace(1,v_max, 60);

% therefore d/v = const. Use this to determine safety
distances = speeds.*t_tot;

% close all
% figure
% tiledlayout(2,1)
% nexttile
% plot(distances,speeds.*3.6)
% xlabel("Distance to target (m)")
% ylabel("Target speed (km/h)")
% nexttile
% plot(distances,speeds)
% xlabel("Distance to target (m)")
% ylabel("Target speed (m/s)")

% Convert radial velocity into speed

rad_vel = 30;
rad_rng = 100;
lane_width = 4;

par_rng = sqrt(rad_rng^2 - lane_width^2);

theta = tan(lane_width/par_rng)
% Dont need to compute unknown distance - may be good for range est though
theta2 = sin(lane_width/rad_rng)

spd_reduction_factor = 1/cos(theta2)

spd = rad_vel/cos(theta2)

disp("It is clear that the radial speed and range are very close to the actual" + ...
    " values. We can assume radial parameters = true parameters")
