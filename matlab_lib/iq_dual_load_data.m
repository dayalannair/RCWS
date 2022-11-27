% 1) Add paths to data directories here - include date in directory name
addpath(['../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_05_11_2022/iq_data/']);
addpath(['../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_05_11_2022/iq_vid/']);
% 2) Change the time stamp to desired data set
time = '_11_01_36';

% 3) The following will automatically load the data from both radars

% Read in IQ data from left and right uRAD radar
f_urad1 = strcat('lhs_iq',time,'.txt');
f_urad2 = strcat('rhs_iq',time,'.txt');