% addpath(['..\..\..\..\OneDrive - University of Cape Town' ...
%     '\RCWS_DATA\road_data_05_11_2022\gps_data\']);
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_03_04_2023\gps_data\']);

% gps_data30 = readtable('20221105-111150 - 3030.txt','Delimiter' ,',');
% gps_data50 = readtable('20221105-111817 - 5050.txt','Delimiter' ,',');
% gps_data40 = readtable('20221105-110129 - 40ane60.txt','Delimiter' ,',');


% gps_data = readtable('20230323-121458 - 45.txt','Delimiter' ,',');
% gps_data = readtable('20230323-121730 - 60.txt','Delimiter' ,',');
gps_data = gpxread('20230403-121955 - 45.gpx');


%% Load offline processed speed data 
addpath(['..\..\..\..\..\OneDrive - University of Cape Town\' ...
    'RCWS_DATA\controlled_test_23_03_2023\offlineProc\']);
% spMeasTbl = readtable('speed_results_ct45.txt','Delimiter' ,' ');
% spMeasTbl = readtable('speed_results_ct60.txt','Delimiter' ,' ');
spMeasTbl = readtable('speed_results_ct70.txt','Delimiter' ,' ');
spMtx = table2array(spMeasTbl);

%% Organise data
% subset_start = 1700;

% 70 km/h
subset_length= 2752;
subset_start = 1700;
subset_end = 2060;

% 60 km/h
% subset_length= 2753;
% subset_start = 1520;
% subset_end = 1890;

% 45 km/h
% subset_length= 2744; % 45 km/h
% subset_start = 490;
% subset_end = 1050;

gpsSpd = gps_data.speed_m_s_*3.6;
t_ax_rdr = linspace(0,30,subset_length);
t_ax_rdr = t_ax_rdr(subset_start+1:subset_end);
hms_clean = gps_data.dateTime - gps_data.dateTime(1);
t_ax_gps = seconds(hms_clean);


% 70 km/h
t_min_rdr = round(min(t_ax_rdr))-1;
t_max_rdr = round(max(t_ax_rdr))-1;
tIdxStart = find(t_ax_gps==t_min_rdr);
tIdxEnd = find(t_ax_gps==t_max_rdr);
t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);

% % 60 km/h
% t_min_rdr = round(min(t_ax_rdr));
% t_max_rdr = round(max(t_ax_rdr));
% tIdxStart = find(t_ax_gps==t_min_rdr);
% tIdxEnd = find(t_ax_gps==t_max_rdr);
% t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);

% 45 km/h
% tIdxStart = find(t_ax_gps==9);
% tIdxEnd = find(t_ax_gps==17);
% t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd)-5.5;



gpsSpd = gpsSpd(tIdxStart:tIdxEnd);





% t_ax_gps = 
%% Plot
spMtx(spMtx==0)=nan;
% spMtx(spMtx<50)=nan;
% spMtx(spMtx>60)=nan;
spMtxVector = max(spMtx,[], 2);

%%
close all
figure
hold on
% % scatter(,gpsSpd)
numAx = linspace(1,370,370);
plot(t_ax_gps, gpsSpd, LineWidth=1.5)
% plot(t_ax_rdr,spMtxVector)
scatter(t_ax_rdr, spMtx.', 200, Marker=".")
% surf(spMtx)
% plot(t_ax_rdr, spMtx(:, :).')
% p1 = plot(t_ax_rdr, spMtx(:, 5).');

% for i=1:370
%   plot(t_ax_rdr, flip(spMtx(:, i).'));
%   drawnow;
%   pause(0.1);
% end
% scatter(spMtx)
% imagesc(spMtx)
% plot(spMtx.')
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

