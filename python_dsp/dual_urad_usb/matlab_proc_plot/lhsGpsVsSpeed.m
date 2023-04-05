
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

%% Organise data
% subset_start = 1700;

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

gpsSpd = gps_data.speed_m_s_*3.6;
% close all
% plot(gpsSpd)
% return;
%%
t_ax_rdr_full = linspace(0,30,subset_length);
t_ax_rdr = t_ax_rdr_full(subset_start+1:subset_end);
hms_clean = gps_data.dateTime - gps_data.dateTime(1);
t_ax_gps = seconds(hms_clean);


% 45 km/h
% t_min_rdr = round(min(t_ax_rdr))-1;
% t_max_rdr = round(max(t_ax_rdr))+1;
% tIdxStart = find(t_ax_gps==t_min_rdr);
% tIdxEnd = find(t_ax_gps==t_max_rdr);
% t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);

% % 60 km/h
t_min_rdr = round(min(t_ax_rdr));
t_max_rdr = round(max(t_ax_rdr));
tIdxStart = find(t_ax_gps==t_min_rdr);
tIdxEnd = find(t_ax_gps==t_max_rdr);
t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);

% 45 km/h
% tIdxStart = find(t_ax_gps==9);
% tIdxEnd = find(t_ax_gps==17);
% t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);

gpsSpd = gpsSpd(tIdxStart:tIdxEnd);


% t_ax_gps = 
%% Plot
spMtx(spMtx==0)=nan;
t_ax_rdr = t_ax_rdr.';
% spMtx(spMtx<50)=nan;
% spMtx(spMtx>60)=nan;
spMtxVector = mean(spMtx, 2, "omitnan");
close all
scatter(t_ax_rdr,spMtxVector)
hold on
plot(t_ax_gps, gpsSpd, LineWidth=1.5)
return
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

