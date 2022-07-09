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


v_max_now = lambda/(4*t_sweep)
tc_min = lambda/(4*v_max) % 187 us

% ADC samples
N = t_sweep*fs
N_new = round(tc_min*fs)

tc_new = N_new/fs;
% new v max after rounding:
v_max_new = lambda/(4*tc_new)*3.6

% New range max
r_max_new = c*N_new/(4*bw)


% MUST BE able to get good range and good Doppler using Sawtooth
% Can kill bw/res --> Seeming like the best option
% cant improve lambda
%% Optimisation

rmax_array = zeros(200,1);
vmax_array = zeros(200,1);
bw = 100e6;
for n = 1:200
    rmax_array(n) = c*n/(4*bw);
    tc = n/fs;
    vmax_array(n) = lambda/(4*tc)*3.6;
end

% For now, est from plot = 85
%[tf, idx] = ismember(rmax_array,vmax_array)
%idx = intersect(rmax_array,vmax_array)

% minimum Ns = 50.
n = 50


% Reducing BW increases Max range
rmax = c*n/(4*bw)
tc = n/fs;

% Reducing Ns increases Max speed
% At minimum Ns, max speed is 45 km/h which is insufficient
vmax = lambda/(4*tc)*3.6
range_res = c/(2*bw) % ---> sim to data sheet?
% Terrible!
%%
% v_good_dbkmh = mag2db(60);
% close all
% figure
% plot(rmax_array, 'DisplayName','Max ranges')
% % axis([0 200 0 60])
% yline(50, '-', '50 m')
% yyaxis left
% % ylim([0, 60])
% ylabel("Range (m)")
% xlabel("Number of ADC samples")
% hold on
% yyaxis right
% plot(vmax_array, 'DisplayName','Max Velocities')
% % ylim([0, 60])
% % yline(60, '-', '60 km/h')
% % axis([0 200 0 60])
% ylabel("Velocity (km/h)")
% xlabel("Number of ADC samples")
% legend
% plot(rmax_array)
% yyaxis left
% ylabel("Range (dB meters)")
% hold on
% plot(vmax_array)
% yyaxis right
% ylabel("Velocity (kmdB/h)")

%% Separate plot for better axes
close all
figure
tiledlayout(2,1)
nexttile
plot(rmax_array, 'DisplayName','Max ranges')
axis([0 200 0 60])
yline(50, '-', '50 m')
ylabel("Range (m)")
xlabel("Number of ADC samples")
nexttile
plot(vmax_array, 'DisplayName','Max Velocities')
yline(60, '-', '60 km/h')
axis([0 200 0 70])
ylabel("Velocity (km/h)")
xlabel("Number of ADC samples")

