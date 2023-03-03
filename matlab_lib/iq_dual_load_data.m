% 1) Add paths to data directories here - include date in directory name
addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_05_11_2022/iq_data/']);
addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_05_11_2022/iq_vid/']);


addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_03_11_2022/iq_data/']);
addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_03_11_2022/iq_vid/']);


addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_31_01_2023/iq_data/']);
addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_31_01_2023/iq_vid/']);


addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_10_02_2023/iq_data/']);
addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_10_02_2023/iq_vid/']);


addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_03_03_2023/iq_data/']);
addpath(['../../../../../OneDrive - University of Cape Town/' ...
    'RCWS_DATA/road_data_03_03_2023/iq_vid/']);




% 2) Change the time stamp to desired data set
% Time stamps for 3 November 2022

% time = '_12_18_12';

% Time stamps for 5 November 2022
% time = '_10_25_12';
% time = '_10_29_56';
% time = '_10_44_35';
% time = '_10_53_21';
% time = '_11_01_36';

% Time stamps for 31 January 2023
% time = '_14_09_08';
% time = '_14_12_57';
time = '_14_16_22';

% Timestamps for 10 February 2023

time = '_14_51_49';
% time = '_14_52_54';
% time = '_14_53_36';
% time = '_14_54_19';

% Timestamps for 3 March 2023

time = '_12_57_07';





% 3) The following will automatically load the data from both radars

% Read in IQ data from left and right uRAD radar
f_urad1 = strcat('lhs_iq',time,'.txt');
f_urad2 = strcat('rhs_iq',time,'.txt');