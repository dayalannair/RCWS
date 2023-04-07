% addpath(['..\..\..\..\OneDrive - University of Cape Town' ...
%     '\RCWS_DATA\road_data_05_11_2022\gps_data\']);
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_03_04_2023\gps_data\']);
gps_data = readtable('20230403-121955 - 45.txt','Delimiter' ,',');
gps_data = readtable('20230403-122706 - 60.txt','Delimiter' ,',');
gps_data = readtable('20230403-122941 - 70.txt','Delimiter' ,',');

%% Load offline processed speed data 
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_03_04_2023\offline_proc\']);
spMeasTbl = readtable('lhs_speed_results_ct45.txt','Delimiter' ,' ');
spMeasTbl = readtable('lhs_speed_results_ct60.txt','Delimiter' ,' ');
spMeasTbl = readtable('lhs_speed_results_ct70.txt','Delimiter' ,' ');
spMtx = table2array(spMeasTbl);

rgMeasTbl = readtable('lhs_range_results_ct45.txt','Delimiter' ,' ');
rgMeasTbl = readtable('lhs_range_results_ct60.txt','Delimiter' ,' ');
rgMeasTbl = readtable('lhs_range_results_ct70.txt','Delimiter' ,' ');
rgMtx = table2array(rgMeasTbl);

toaTbl = readtable('lhs_safety_results_ct45.txt','Delimiter' ,' ');
toaTbl = readtable('lhs_safety_results_ct60.txt','Delimiter' ,' ');
toaTbl = readtable('lhs_safety_results_ct70.txt','Delimiter' ,' ');
toaMtx = table2array(toaTbl);
%%

% 70 km/h
subset_length= 2749;
subset_start = 1100;
subset_end = 1360;

% 60 km/h
% subset_length= 2753;
% subset_start = 1060;
% subset_end = 1320;

% 45 km/h
% subset_length= 2750;
% subset_start = 1030;
% subset_end = 1390;
t_ax_rdr = linspace(0,30,subset_length);
t_ax_rdr = t_ax_rdr(subset_start+1:subset_end);
hms_clean = gps_data.dateTime - gps_data.dateTime(1);
t_ax_gps = seconds(hms_clean);

% 70 km/h
tIdxStart = 16;
tIdxEnd = 20;

% 60 km/h
% tIdxStart = 18;
% tIdxEnd = 22;

t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);
gpsSpd = gps_data.speed_m_s_;
gpsSpdFull = gpsSpd;
gpsSpd = gpsSpd(tIdxStart:tIdxEnd);

% RHS start point from GPS measurement
origin = [-34.05417909,18.45800825,50];
[xEast,yNorth,zUp] = latlon2local(gps_data.latitude,gps_data.longitude,50,origin);
% gpsRng = distance(gps_data.latitude, gps_data.longitude, lat, lon)
gpsRng = sqrt(xEast.^2 + yNorth.^2);
rng_full = gpsRng;
gpsRng = gpsRng(tIdxStart:tIdxEnd);
toaGps = gpsRng./gpsSpd;
toaGpsFull = rng_full./gpsSpdFull;

toaMtx(toaMtx==0)=nan;
% toaMtx = rgMtx./spMtx;

% 70-2 km/h
t_offset = -1;
% 45 km/h
% t_offset = -0.425;

% 60 km/h
% t_offset = -0.85;


%%
close all 
hold on

scatter(t_ax_rdr- min(t_ax_rdr),toaMtx, 10, 'Marker','o')
plot(t_ax_gps- min(t_ax_gps)+t_offset,toaGps, 'LineWidth',1.1)
% axis([0 6 0 4])
ylabel("Time of arrival (s)", "FontSize",13)
xlabel("Time (s)", "FontSize",13)
