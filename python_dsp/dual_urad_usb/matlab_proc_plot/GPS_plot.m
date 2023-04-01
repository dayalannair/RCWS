% addpath(['..\..\..\..\OneDrive - University of Cape Town' ...
%     '\RCWS_DATA\road_data_05_11_2022\gps_data\']);
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_23_03_2023\gps_data\']);

% gps_data30 = readtable('20221105-111150 - 3030.txt','Delimiter' ,',');
% gps_data50 = readtable('20221105-111817 - 5050.txt','Delimiter' ,',');
% gps_data40 = readtable('20221105-110129 - 40ane60.txt','Delimiter' ,',');


% gps_data = readtable('20230323-121458 - 45.txt','Delimiter' ,',');
gps_data = readtable('20230323-121730 - 60.txt','Delimiter' ,',');
% gps_data = readtable('20230323-122005 - 70.txt','Delimiter' ,',');
% gps_data = readtable('20230323-122237 - 70_2.txt','Delimiter' ,',');
spdKmh = gps_data.speed_m_s_*3.6;

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

% for i = 1:29
%     rng(i) = lldistkm([gps_data.latitude(i), gps_data.longitude(i)], [lat, lon]);
% end
origin = [lat,lon,50];
origin = [-34.0528450000000	18.4564700000000,50];
origin = [-34.05418024521243, 18.457971132886712,50];
[xEast,yNorth,zUp] = latlon2local(gps_data.latitude,gps_data.longitude,50,origin);
% rng = distance(gps_data.latitude, gps_data.longitude, lat, lon)
rng = sqrt(xEast.^2 + yNorth.^2);
% dist = rng(29)-rng(1)
% speed = dist/30
% rng = lldistkm([gps_data.latitude, gps_data.longitude], [lat, lon]);
t_ax  = gps_data.dateTime.Second- gps_data.dateTime.Second(1);
%% Plot
close all
figure
tiledlayout(2, 1)
nexttile
scatter(t_ax,spdKmh)
ylabel('Speed (km/h)')
nexttile
% scatter(gps_data.latitude, gps_data.longitude)
scatter(t_ax, rng)
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

