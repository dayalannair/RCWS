%% Real time results visualisation
% This script reads in real time processed data stored in a shared OneDrive
% repository and plots these as colour maps. 
% Also can plot range/speed/safety vs. time
addpath(['../../../../../OneDrive - University of Cape' ...
    ' Town/RCWS_DATA/road_data_03_11_2022/']);

l_rng_t = readtable('lhs_range_results_12_19_55.txt','Delimiter' ,' ');
l_spd_t = readtable('lhs_speed_results_12_19_55.txt','Delimiter' ,' ');
l_sft_t = readtable('lhs_safety_results_12_19_55.txt','Delimiter' ,' ');

r_rng_t = readtable('rhs_range_results_12_19_55.txt','Delimiter' ,' ');
r_spd_t = readtable('rhs_speed_results_12_19_55.txt','Delimiter' ,' ');
r_sft_t = readtable('rhs_safety_results_12_19_55.txt','Delimiter' ,' ');

l_rng = table2array(l_rng_t);
l_spd = table2array(l_spd_t);

r_rng = table2array(r_rng_t);
r_spd = table2array(r_spd_t);


close all
figure
% imagesc(l_spd);
imagesc(r_spd);
% imagesc(r_rng);
imagesc(r_rng);