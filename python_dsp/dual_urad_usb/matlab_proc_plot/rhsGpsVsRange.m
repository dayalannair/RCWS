% addpath(['..\..\..\..\OneDrive - University of Cape Town' ...
%     '\RCWS_DATA\road_data_05_11_2022\gps_data\']);
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_23_03_2023\gps_data\']);

% gps_data30 = readtable('20221105-111150 - 3030.txt','Delimiter' ,',');
% gps_data50 = readtable('20221105-111817 - 5050.txt','Delimiter' ,',');
% gps_data40 = readtable('20221105-110129 - 40ane60.txt','Delimiter' ,',');


gps_data = readtable('20230323-121458 - 45.txt','Delimiter' ,',');
gps_data = readtable('20230323-121730 - 60.txt','Delimiter' ,',');
gps_data = readtable('20230323-122237 - 70_2.txt','Delimiter' ,',');
% gps_data = readtable('20230323-122005 - 70.txt','Delimiter' ,',');


%% Load offline processed speed data 
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_23_03_2023\offlineProc\']);
rgMeasTbl = readtable('rhs_range_results_ct45.txt','Delimiter' ,' ');
rgMeasTbl = readtable('rhs_range_results_ct60.txt','Delimiter' ,' ');
rgMeasTbl = readtable('rhs_range_results_ct70.txt','Delimiter' ,' ');
rgMtx = table2array(rgMeasTbl);

% Radar position
lon = 18.2728;
lat = -34.0315;
calib = 111.139;
lat_rng = (lat - gps_data.latitude);
lng_rng = (gps_data.longitude - lon);
lat2 = gps_data.latitude*calib;
lonCalib = 240075 * cos( lat2 ) / 360;
lon2 = gps_data.longitude.*lonCalib;
rng2 = sqrt(lat2.^2 + lon2.^2);
rng = sqrt(lat_rng.^2 + lng_rng.^2)*calib;

%% Organise

% 45 km/h
% subset_length= 2744;
% subset_start = 490;
% subset_end = 1050;

% 60 km/h
% subset_length= 2753;
% subset_start = 1520;
% subset_end = 1890;

% 70-2 km/h
subset_length= 2752;
subset_start = 1700;
subset_end = 2060;

gpsSpd = gps_data.speed_m_s_*3.6;
t_ax_rdr = linspace(0,30,subset_length);
t_ax_rdr = t_ax_rdr(subset_start+1:subset_end);
hms_clean = gps_data.dateTime - gps_data.dateTime(1);
t_ax_gps = seconds(hms_clean);

% % 60 km/h
% t_min_rdr = round(min(t_ax_rdr));
% t_max_rdr = round(max(t_ax_rdr));
% tIdxStart = find(t_ax_gps==t_min_rdr);
% tIdxEnd = find(t_ax_gps==t_max_rdr);
% t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);

% 70-2 km/h
t_min_rdr = round(min(t_ax_rdr))-1;
t_max_rdr = round(max(t_ax_rdr))-1;
tIdxStart = find(t_ax_gps==t_min_rdr);
tIdxEnd = find(t_ax_gps==t_max_rdr);
t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);


% t_min_rdr = round(min(t_ax_rdr));
% t_max_rdr = round(max(t_ax_rdr));
% tIdxStart = find(t_ax_gps==t_min_rdr);
% tIdxEnd = find(t_ax_gps==t_max_rdr);


% t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);



% tIdxStart = find(t_ax_gps==10);
% tIdxEnd = find(t_ax_gps==17);
% t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd)-5.5;


% for i = 1:29
%     rng(i) = lldistkm([gps_data.latitude(i), gps_data.longitude(i)], [lat, lon]);
% end

%% Coords
origin = [lat,lon,50];
origin = [-34.0528450000000	18.4564700000000,50];
origin = [-34.05418024521243, 18.457971132886712,50];
[xEast,yNorth,zUp] = latlon2local(gps_data.latitude,gps_data.longitude,50,origin);
% rng = distance(gps_data.latitude, gps_data.longitude, lat, lon)
rng = sqrt(xEast.^2 + yNorth.^2);


% 70-2 km/h
rng = rng(tIdxStart-4:tIdxEnd-4);

% 60 km/h
% rng = rng(tIdxStart+4:tIdxEnd+4);

% 45 km/h
% rng = rng(tIdxStart+9:tIdxEnd+9);
% dist = rng(29)-rng(1)
% speed = dist/30
% rng = lldistkm([gps_data.latitude, gps_data.longitude], [lat, lon]);
t_ax  = gps_data.dateTime.Second- gps_data.dateTime.Second(1);
rgMtx(rgMtx==0)=nan;
%% Plot
close all
figure
% tiledlayout(2, 1)
% nexttile
hold on
plot(t_ax_gps,rng)
ylabel('Range (m)')
scatter(t_ax_rdr,rgMtx)
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


