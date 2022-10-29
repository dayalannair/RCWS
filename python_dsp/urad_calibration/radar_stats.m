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

meas_dist = 2.9;
axlims = [0,30,1.5,5.1];
close all
figure
tiledlayout(1, 5)
nexttile
plot(hann1,'LineStyle', 'none', 'DisplayName','Measured', ...
    'Marker','.', 'MarkerSize',8)
title("Hann Window")
ylabel("Range (m)")
xlabel("Detection number")
axis(axlims)
% yline()
yline(2.9,'DisplayName','Actual')
yline(mode(hann1), 'DisplayName','Mode', 'Color','Red')
% legend
nexttile
plot(hann2,'LineStyle', 'none', 'DisplayName','Measured', ...
    'Marker','.', 'MarkerSize',8)
title("Hann Window")
ylabel("Range (m)")
xlabel("Detection number")
yline(2.9,'DisplayName','Actual')
yline(mode(hann2), 'DisplayName','Mode', 'Color','Red')
axis(axlims)
% legend
nexttile
plot(tayl1,'LineStyle', 'none', 'DisplayName','Measured', ...
    'Marker','.', 'MarkerSize',8)
title("Taylor Window")
ylabel("Range (m)")
xlabel("Detection number")
yline(2.9,'DisplayName','Actual')
yline(mode(tayl1), 'DisplayName','Mode', 'Color','Red')
axis(axlims)
% legend
nexttile
plot(blac1,'LineStyle', 'none', 'DisplayName','Measured', ...
    'Marker','.', 'MarkerSize',8)
title("Blackman Window")
ylabel("Range (m)")
xlabel("Detection number")
yline(2.9,'DisplayName','Actual')
yline(mode(blac1), 'DisplayName','Mode', 'Color','Red')
axis(axlims)
% legend
nexttile
plot(hamm1,'LineStyle', 'none', 'DisplayName','Measured', ...
    'Marker','.', 'MarkerSize',8)
title("Hamming Window")
ylabel("Range (m)")
xlabel("Detection number")
yline(2.9,'DisplayName','Actual')
yline(mode(hamm1), 'DisplayName','Mode', 'Color','Red')
axis(axlims)
legend
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



ratio = meas_dist/radar_est;




