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
spMeasTbl = readtable('rhs_speed_results_ct45.txt','Delimiter' ,' ');
spMeasTbl = readtable('rhs_speed_results_ct60.txt','Delimiter' ,' ');
% spMeasTbl = readtable('rhs_speed_results_ct70.txt','Delimiter' ,' ');
spMtx = table2array(spMeasTbl);

%% Organise data
% subset_start = 1700;

% 70-2 km/h
% subset_length= 2752;
% subset_start = 1700;
% subset_end = 2060;

% 70 km/h
% subset_length= 2752;
% subset_start = 1700;
% subset_end = 2060;

% 60 km/h
subset_length= 2753;
subset_start = 1520;
subset_end = 1890;

% 45 km/h
% subset_length= 2744;
% subset_start = 490;
% subset_end = 1050;

gpsSpd = gps_data.speed_m_s_*3.6;
t_ax_rdr = linspace(0,30,subset_length);
t_ax_rdr = t_ax_rdr(subset_start+1:subset_end);
hms_clean = gps_data.dateTime - gps_data.dateTime(1);
t_ax_gps = seconds(hms_clean);

% 70-2 km/h
% tIdxStart = 16;
% tIdxEnd = 20;

% % 60 km/h
tIdxStart = 21;
tIdxEnd = 26;
t_offset = -1;
% 45 km/h
% tIdxStart = 20;
% tIdxEnd = 26;

t_ax_gps = t_ax_gps(tIdxStart:tIdxEnd);

gpsSpdFull = gpsSpd;
gpsSpd = gpsSpd(tIdxStart:tIdxEnd);
err = gps_data.accuracy_m_(tIdxStart:tIdxEnd);
% t_offset = -abs(min(t_ax_rdr)-min(t_ax_gps))-0.425;

% t_offset = -abs(min(t_ax_rdr)-min(t_ax_gps))-0.85;
% t_ax_gps = 
%% Plot
spMtx(spMtx==0)=nan;
% spMtx(spMtx<30)=nan;
% spMtx(spMtx>50)=nan;
% spMtx(spMtx<50)=nan;
% spMtx(spMtx>60)=nan;
spMtxVector = max(spMtx,[], 2);
colours = winter(16);
%%
close all
figure
hold on
for i =1:size(spMtx,2)
    plot(t_ax_rdr - min(t_ax_rdr)+1,spMtx(:,i).', '-o', 'MarkerSize', 3.5, ...
        'MarkerFaceColor',colours(i,:),'Color',colours(i,:))
%     axis([0 5 0 75])
end
colormap(colours);
a = colorbar;
a.Label.String = 'Range (m)';
a.FontSize  = 13;
caxis([0, 62.5]);
errorbar(t_ax_gps - min(t_ax_gps)+t_offset+1, gpsSpd, err,'Color','r','LineWidth',1.1)
% scatter(t_ax_rdr, spMtx.',5, [0 0.5 0], Marker="o")
ylabel('Speed (km/h)', FontSize=13)
xlabel('Time (s)', FontSize=13)
% mean(spMtx,2, "omitnan").'
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

