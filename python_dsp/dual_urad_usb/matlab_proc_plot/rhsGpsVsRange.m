% addpath(['..\..\..\..\OneDrive - University of Cape Town' ...
%     '\RCWS_DATA\road_data_05_11_2022\gps_data\']);
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_23_03_2023\gps_data\']);

% gps_data30 = readtable('20221105-111150 - 3030.txt','Delimiter' ,',');
% gps_data50 = readtable('20221105-111817 - 5050.txt','Delimiter' ,',');
% gps_data40 = readtable('20221105-110129 - 40ane60.txt','Delimiter' ,',');


gps_data = readtable('20230323-121458 - 45.txt','Delimiter' ,',');
gps_data = readtable('20230323-121730 - 60.txt','Delimiter' ,',');
% gps_data = readtable('20230323-122237 - 70_2.txt','Delimiter' ,',');
% gps_data = readtable('20230323-122005 - 70.txt','Delimiter' ,',');


%% Load offline processed speed data 
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_23_03_2023\offlineProc\']);
rgMeasTbl = readtable('rhs_range_results_ct45.txt','Delimiter' ,' ');
rgMeasTbl = readtable('rhs_range_results_ct60.txt','Delimiter' ,' ');
% rgMeasTbl = readtable('rhs_range_results_ct70.txt','Delimiter' ,' ');
rgMtx = table2array(rgMeasTbl);


%% Organise data

% 45 km/h
subset_length= 2744;
subset_start = 490;
subset_end = 1050;

% 60 km/h
subset_length= 2753;
subset_start = 1520;
subset_end = 1890;

% 70-2 km/h
% subset_length= 2752;
% subset_start = 1700;
% subset_end = 2060;

gpsSpd = gps_data.speed_m_s_*3.6;
t_ax_rdr = linspace(0,30,subset_length);
t_ax_rdr = t_ax_rdr(subset_start+1:subset_end);
hms_clean = gps_data.dateTime - gps_data.dateTime(1);
t_ax_gps = seconds(hms_clean);

% % 60 km/h
tIdxStart = 21;
tIdxEnd = 26;
t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);

% 70-2 km/h
% t_min_rdr = round(min(t_ax_rdr))-1;
% t_max_rdr = round(max(t_ax_rdr))-1;
% tIdxStart = find(t_ax_gps==t_min_rdr);
% tIdxEnd = find(t_ax_gps==t_max_rdr);
% t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);


% 45 km/h
% tIdxStart = find(t_ax_gps==20);
% tIdxEnd = find(t_ax_gps==26);
% t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);


% for i = 1:29
%     rng(i) = lldistkm([gps_data.latitude(i), gps_data.longitude(i)], [lat, lon]);
% end

%% Coords
% RHS start point from GPS measurement
origin = [-34.05417909,18.45800825,50];
[xEast,yNorth,zUp] = latlon2local(gps_data.latitude,gps_data.longitude,50,origin);
% rng = distance(gps_data.latitude, gps_data.longitude, lat, lon)
rng = sqrt(xEast.^2 + yNorth.^2);
rng_full = rng;

% 70-2 km/h
% rng = rng(tIdxStart-3:tIdxEnd-3);
% err = gps_data.accuracy_m_(tIdxStart-3:tIdxEnd-3);

% 60 km/h
rng = rng(tIdxStart:tIdxEnd);
err = gps_data.accuracy_m_(tIdxStart:tIdxEnd);

% 45 km/h
% rng = rng(tIdxStart:tIdxEnd);
% err = gps_data.accuracy_m_(tIdxStart:tIdxEnd);

% rng = lldistkm([gps_data.latitude, gps_data.longitude], [lat, lon]);
t_ax  = gps_data.dateTime.Second- gps_data.dateTime.Second(1);
rgMtx(rgMtx==0)=nan;

% 70-2 km/h
% t_offset = abs(min(t_ax_rdr)-min(t_ax_gps))+0.1;

% 60 km/h
% t_offset = abs(min(t_ax_rdr)-min(t_ax_gps))-0.85;
t_offset = -1;
% 45 km/h
% t_offset = -abs(min(t_ax_rdr)-min(t_ax_gps))-0.425;
a = round(mean(rgMtx, "all", 'omitnan'), 2) ;
b = round(median(rgMtx, "all", 'omitnan'),2);
c = round(mode(rgMtx,"all"),2);
d = round(std(rgMtx(:), 'omitnan'),2);
statVector = [a;b;c;d]

a = round(mean(rng, "all", 'omitnan'), 2) ;
b = round(median(rng, "all", 'omitnan'),2);
c = round(mode(rng,"all"),2);
d = round(std(rng(:), 'omitnan'),2);
statVector = [a;b;c;d]
%% Plot
close all
figure
% tiledlayout(2, 1)
% nexttile
hold on
scatter(t_ax_rdr - min(t_ax_rdr),rgMtx,5,'b',MarkerFaceColor='flat', Marker="o")
errorbar(t_ax_gps+t_offset - min(t_ax_gps),rng, err, 'LineWidth',1.1, 'Color','r')
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


