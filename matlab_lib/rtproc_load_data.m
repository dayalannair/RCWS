% 1) Add paths to data directories here - include date in directory name
addpath(['..\..\..\..\OneDrive - University of Cape Town\RCWS_DATA\' ...
    'road_data_05_11_2022\rt_proc_data\']);

% 2) Change the time stamp to desired data set
time = '_11_12_09';
% time = '_11_30_27';
% time = '_11_33_17';

% 3) The following will automatically load the data from both radars

% Read in range, speed, and safety from LHS radar
l_rng_t = readtable(strcat('lhs_range_results',time,'.txt'), ...
    'Delimiter' ,' ');
l_spd_t = readtable(strcat('lhs_speed_results',time,'.txt'), ...
    'Delimiter' ,' ');
l_sft_t = readtable(strcat('lhs_safety_results',time,'.txt'), ...
    'Delimiter' ,' ');
% Read in range, speed, and safety of RHS radar
r_rng_t = readtable(strcat('rhs_range_results',time,'.txt'), ...
    'Delimiter' ,' ');
r_spd_t = readtable(strcat('rhs_speed_results',time,'.txt'), ...
    'Delimiter' ,' ');
r_sft_t = readtable(strcat('rhs_safety_results',time,'.txt'), ...
    'Delimiter' ,' ');