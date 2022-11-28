% 1) Add paths to data directories here - include date in directory name
addpath(['../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_05_11_2022/iq_data/']);
addpath(['../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_05_11_2022/iq_vid/']);


addpath(['../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_03_11_2022/iq_data/']);
addpath(['../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_03_11_2022/iq_vid/']);


% 2) Change the time stamp to desired data set
% Time stamps for 3 November 2022

% time = '_12_18_12';

% Time stamps for 5 November 2022
% time = '_10_25_12';
% time = '_10_29_56';
% time = '_10_44_35';
% time = '_10_53_21';
time = '_11_01_36';

% 3) The following will automatically load the data from both radars

% Read in IQ data from left and right uRAD radar
f_urad1 = strcat('lhs_iq',time,'.txt');
f_urad2 = strcat('rhs_iq',time,'.txt');