% addpath(['..\..\..\..\OneDrive - University of Cape Town' ...
%     '\RCWS_DATA\road_data_05_11_2022\gps_data\']);
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_23_03_2023\gps_data\']);

% gps_data30 = readtable('20221105-111150 - 3030.txt','Delimiter' ,',');
% gps_data50 = readtable('20221105-111817 - 5050.txt','Delimiter' ,',');
% gps_data40 = readtable('20221105-110129 - 40ane60.txt','Delimiter' ,',');


% gps_data = readtable('20230323-121458 - 45.txt','Delimiter' ,',');
gps_data = readtable('20230323-121730 - 60.txt','Delimiter' ,',');
% gps_data = readtable('20230323-122237 - 70_2.txt','Delimiter' ,',');


%% Load offline processed speed data 
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_23_03_2023\offlineProc\']);
spMeasTbl = readtable('speed_results_ct60.txt','Delimiter' ,' ');
% spMeasTbl = readtable('speed_results_ct70.txt','Delimiter' ,' ');
spMtx = table2array(spMeasTbl);

%% Organise data
% subset_start = 1700;
subset_start = 1520;
subset_end = 2753;
gpsSpd = gps_data.speed_m_s_*3.6;
t_ax_rdr = linspace(0,30,subset_end);
t_ax_rdr = t_ax_rdr(subset_start+1:subset_start+length(spMtx));
t_ax_gps = gps_data.dateTime.Second - gps_data.dateTime.Second(1);


% 70 km/h
timeAlign = 11;
tIdxStart = find(t_ax_gps==16);
tIdxEnd = find(t_ax_gps==21);
t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);
gpsSpd = gpsSpd(tIdxStart:tIdxEnd);
% t_ax_gps = 
%% Plot
spMtx(spMtx==0)=nan;
spMtxVector = max(spMtx,[], 2);

%%
close all
figure
hold on
% % scatter(,gpsSpd)
numAx = linspace(1,370,370);
plot(t_ax_gps, gpsSpd, LineWidth=1.5)
% plot(t_ax_rdr,spMtxVector)
scatter(t_ax_rdr, spMtxVector.',200, Marker=".")

ylabel('Speed (km/h)')

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

