addpath('../../matlab_lib/');
addpath( ...
    ['../../../../OneDrive - University of Cape Town' ...
    '/RCWS_DATA/urad_calibration_data']);

data_tbl = readtable('calibration_290mm_hann.txt','Delimiter' ,' ');
hann1 = table2array(data_tbl);
data_tbl = readtable('calibration_290mm_hann_2.txt','Delimiter' ,' ');
hann2 = table2array(data_tbl);
data_tbl = readtable('calibration_290mm_taylor_sll50.txt', ...
    'Delimiter' ,' ');
tayl1 = table2array(data_tbl);
data_tbl = readtable('calibration_290mm_blackman.txt','Delimiter' ,' ');
blac1 = table2array(data_tbl);
data_tbl = readtable('calibration_290mm_hamming.txt','Delimiter' ,' ');
hamm1 = table2array(data_tbl);

close all
figure
tiledlayout(1, 5)
nexttile
plot(hann1)
nexttile
plot(hann2)
nexttile
plot(tayl1)
nexttile
plot(blac1)
nexttile
plot(hamm1)

disp(mode(hann1))
disp(mode(hann2))
disp(mode(tayl1))
disp(mode(blac1))
disp(mode(hamm1))

% for i = 1:5
% 
%     disp(mode(hann1))
% 
% end

radar_est = mode(hann1);

meas_dist = 2.9;

ratio = meas_dist/radar_est;




