%% Real time results visualisation
% This script reads in real time processed data stored in a shared OneDrive
% repository and plots these as colour maps. 
% Also can plot range/speed/safety vs. time


addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_31_01_2023/2thd_rtproc/']);
addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_31_01_2023/2thd_rtproc/']);


% fvid_lhs = strcat('lhs_vid',time,'_rtproc.avi');
% fvid_rhs = strcat('rhs_vid',time,'_rtproc.avi');
time = '_14_11_23';

% time = '_14_14_10';
% time = '_14_15_33';



l_rng_t = readtable(strcat('2thd_lhs_range_results', ...
    time, '.txt'), 'Delimiter', ' ');
l_spd_t = readtable(strcat('2thd_lhs_speed_results', ...
    time, '.txt'), 'Delimiter', ' ');
r_rng_t = readtable(strcat('2thd_rhs_range_results', ...
    time, '.txt'), 'Delimiter', ' ');
r_spd_t = readtable(strcat('2thd_rhs_speed_results', ...
    time, '.txt'), 'Delimiter', ' ');

% flip names to flip video order
% vid_lhs = VideoReader(fvid_lhs);
% vid_rhs = VideoReader(fvid_rhs);

l_rng = table2array(l_rng_t);
l_spd = table2array(l_spd_t);

r_rng = table2array(r_rng_t);
r_spd = table2array(r_spd_t);


sweeps_processed = 300;
l_rng = l_rng(1:sweeps_processed,:);
l_spd = l_spd(1:sweeps_processed,:);

r_rng = r_rng(1:sweeps_processed,:);
r_spd = r_spd(1:sweeps_processed,:);

%%
 fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
k = bw/tm;                      % Sweep slope
nbins = 16;
bin_width = 16;
fs = 200e3;
n_fft = 512;
f = f_ax(n_fft, fs);
f_neg = f(1:n_fft/2);
f_pos = f((n_fft/2 + 1):end);

rng_ax = beat2range(f_pos',k,c);
rg_bin_lbl = strings(1,nbins);
rax = linspace(0,62,32);
for bin = 0:(nbins-1)
    first = round(rng_ax(bin*bin_width+1));
    last = round(rng_ax((bin+1)*bin_width));
    rg_bin_lbl(bin+1) = strcat(num2str(first), " to ", num2str(last));
end
close all
figure
tiledlayout(1,2)
nexttile
imagesc(l_spd*3.6)
set(gca, 'XTick', 1:1:nbins, 'XTickLabel', rg_bin_lbl, 'CLim', [0 50])
xlabel("Range bin (m)")
a = colorbar;
a.Label.String = 'Radial velocity (km/h)';
% imagesc(l_spd);
nexttile
imagesc(r_spd*3.6);
set(gca, 'XTick', 1:1:nbins, 'XTickLabel', rg_bin_lbl, 'CLim', [0 50])
xlabel("Range bin (m)")
b = colorbar;
b.Label.String = 'Radial velocity (km/h)';
% imagesc(r_rng);
% imagesc(r_rng);