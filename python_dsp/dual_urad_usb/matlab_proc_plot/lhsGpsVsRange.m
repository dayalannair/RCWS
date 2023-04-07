% addpath(['..\..\..\..\OneDrive - University of Cape Town' ...

addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_03_04_2023\gps_data\']);
gps_data = readtable('20230403-121955 - 45.txt','Delimiter' ,',');
gps_data = readtable('20230403-122706 - 60.txt','Delimiter' ,',');
% gps_data = readtable('20230403-122941 - 70.txt','Delimiter' ,',');

%% Load offline processed range data 
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_03_04_2023\offline_proc\']);
rgMeasTbl = readtable('lhs_range_results_ct45.txt','Delimiter' ,' ');
rgMeasTbl = readtable('lhs_range_results_ct60.txt','Delimiter' ,' ');
% rgMeasTbl = readtable('lhs_range_results_ct70.txt','Delimiter' ,' ');
rgMtx = table2array(rgMeasTbl);


%% Organise data

% 70 km/h
subset_length= 2749;
subset_start = 1100;
subset_end = 1360;

% 60 km/h
subset_length= 2753;
subset_start = 1060;
subset_end = 1320;

% 45 km/h
% subset_length= 2750;
% subset_start = 1030;
% subset_end = 1390;

gpsSpd = gps_data.speed_m_s_*3.6;
t_ax_rdr = linspace(0,30,subset_length);
t_ax_rdr = t_ax_rdr(subset_start+1:subset_end);
hms_clean = gps_data.dateTime - gps_data.dateTime(1);
t_ax_gps = seconds(hms_clean);

% 70 km/h
% tIdxStart = 16;
% tIdxEnd = 20;

% 60 km/h
tIdxStart = 18;
tIdxEnd = 22;

% 45 km/h


t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);

%% Coords
% RHS start point from GPS measurement
origin = [-34.05417909,18.45800825,50];
[xEast,yNorth,zUp] = latlon2local(gps_data.latitude,gps_data.longitude,50,origin);
% rng = distance(gps_data.latitude, gps_data.longitude, lat, lon)
rng = sqrt(xEast.^2 + yNorth.^2);
rng_full = rng;


rng = rng(tIdxStart:tIdxEnd);
err = gps_data.accuracy_m_(tIdxStart:tIdxEnd);

% rng = lldistkm([gps_data.latitude, gps_data.longitude], [lat, lon]);
t_ax  = gps_data.dateTime.Second- gps_data.dateTime.Second(1);
rgMtx(rgMtx==0)=nan;

% 70-2 km/h
% t_offset = -1;

% 60 km/h
t_offset = -1.65;

% 45 km/h
% t_offset = -abs(min(t_ax_rdr)-min(t_ax_gps))-0.425;

%% Plot
close all
figure
% tiledlayout(2, 1)
% nexttile
hold on
scatter(t_ax_rdr - min(t_ax_rdr)+2,rgMtx,5,'b',MarkerFaceColor='flat', Marker="o")
errorbar(t_ax_gps+t_offset - min(t_ax_gps)+2,rng, err, 'LineWidth',1.1, 'Color','r')
ylabel('Range (m)', FontSize=13)
xlabel('Time (s)', FontSize=13)
% nexttile
% % scatter(gps_data.latitude, gps_data.longitude)
% scatter(t_ax, rng)
% scatter(xEast,yNorth)
% gps_dataTest1 = readtable('20221105-105303 - Test1.txt','Delimiter' ,',');
%%
% close all
% figure
% plot(gps_data30.speed_m_s_*3.6)
% ylabel('Speed (km/h)')
%%
% close all
% figure
% plot(gps_data50.speed_m_s_*3.6)
% ylabel('Speed (km/h)')
% 
% %%
% close all
% figure
% plot(gps_data40.speed_m_s_*3.6)
% ylabel('Speed (km/h)')
% 
% %%
% close all
% figure
% plot(gps_dataTest1.speed_m_s_*3.6)
% ylabel('Speed (km/h)')


