
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

% 70 km/h
tIdxStart = 16;
tIdxEnd = 20;
t_offset = -1;
% 60 km/h
% tIdxStart = 18;
% tIdxEnd = 22;


% 45 km/h


t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd)+t_offset;
gpsSpd = gpsSpd(tIdxStart:tIdxEnd);


% t_ax_gps = 
%% Plot
spMtx(spMtx==0)=nan;
% t_ax_rdr = t_ax_rdr.';
% % spMtx(spMtx<50)=nan;
% % spMtx(spMtx>60)=nan;
% spMtxVector = mean(spMtx, 2, "omitnan");
% close all
% scatter(t_ax_rdr,spMtxVector)
% hold on
% plot(t_ax_gps, gpsSpd, LineWidth=1.5)
colours = winter(16);
% return
%%
close all
figure
hold on
for i =1:size(spMtx,2)
    plot(t_ax_rdr - min(t_ax_rdr),spMtx(:,i).', '-o', 'MarkerSize', 3.5, ...
        'MarkerFaceColor',colours(i,:),'Color',colours(i,:))
%     axis([0 5 0 75])
end
errorbar(t_ax_gps - min(t_ax_gps), gpsSpd, err,'Color','r','LineWidth',1.1)
% scatter(t_ax_rdr, spMtx.',5, [0 0.5 0], Marker="o")
ylabel('Speed (km/h)', FontSize=13)
xlabel('Time (s)', FontSize=13)

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

