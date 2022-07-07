% Interesting points
% - The uRAD seems borderline suitable for the task and so a design project
% will put it to its limits
% Will be good to then say it is not over designed for the task
% NB: Need to add a padding time between switching from unsafe to safe when
% a car is moving through frontal blind spot. This assumes the car does not
% stop in front of the host. In this event, short range front radar needs
% to determine safety if autonomous, else driver will see car in front
% Need to confirm phase noise is less than thermal noise. Phase noise
% generally due to coupling and can cause decorrelation after the mixing
% process (downconversion)
% Objective: Obtain better speed resolution
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
max_distance_per_sweep = v_max*t_sweep
% Extra/ not NB:
az_res_50m = az_beam*r_max*pi/180

% VERIFY below
v_max = 60/3.6
t_targ_in_range_bin = rng_res_datasheet/v_max

% should allow this many sweeps per cell
% realistically far less
% From real data, seems like 2 sweeps per range bin if sweep time is 1ms
% for TRIANGLE modulation (tsweep+tproc = 0.04). Need to investigate
% Need to investigate shorter sweep time
%% Optimised parameters
% This section calculates the optimised wave based on required distance and
% velocity

v_max = 60/3.6;
r_targ = 40;

% max time required to turn and match oncoming car speed
% reducing this parameter increases the required turn speed
% Initially, set low - means host can turn and accelerate relatively
% quickly
% NB: Use MATLAB Simscape automated driving to simulate with realistic
% physics
t_turn_accel_max = 3;

% OPTION 1
% given that a target is travelling at max speed, for a given distance what
% is the time taken for target to reach the host
t_given_v_r = r_targ/v_max
% reduced number of samples improves the update rate
n_samples = 160; 

% Max range for the calculated number of samples per sweep
% will be less in real scenario
r_max = 75*(n_samples/bw)*1e6

n_samples_50m = r_targ*bw/75e6
%% OPTION 2 - Better
% Given that a target travels at max speed, and it takes t_turn_accel_max
% seconds for us to turn and match that speed, what is our maximum required
% range? Any targets travelling at <= v_max that are further than r_max
% will result in a safe turn and so do not need to be detected

% reduce by either reducing v_max or t_turn accel max
r_max_required = v_max*t_turn_accel_max


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
fd_max = speed2dop(v_max, lambda)*2
% Doppler shift from 1 kHz Doppler shift
v_1kHz = dop2speed(1e3, lambda)*3.6/2

%% Range Doppler Coupling
% Determine range offset (meters) at the maximum Doppler shift i.e. when the target
% is travelling at vmax
% Equation: -c*fd/2*slope

% at 60km/h -> rd = 1.7 m
rng_offset = rdcoupling(fd_max, sweep_slope,c)
% perform calculation on each range est and subtract
% find out if above method is acceptable

%% Noise Errors
% Assume SNR = 10 dB = 10
SNR=10;
K = 1.6
% phased array
%d = lambda/2
d = 0.003;
%rng_error = rng_res*1/sqrt(2*SNR)
vel_error = vel_res*1/sqrt(2*SNR)
% not sure if necessary
az_error = d/K/sqrt(2*SNR)
el_error = d/K*1/sqrt(2*SNR)
%% Minimum distance
% let minimum distance be 1 meter. Could increase and leave this to close
% range sensors
rmin = 1.5;
fbmin = range2beat(rmin,sweep_slope,c)

% getting rmin from a beat freq min
fbmin = 5e3;

rmin = beat2range(fbmin,sweep_slope,c)





