addpath('..\..\..\..\OneDrive - University of Cape Town\RCWS_DATA\road_data_05_11_2022\gps_data\');

gps_data30 = readtable('20221105-111150 - 3030.txt','Delimiter' ,',');
gps_data50 = readtable('20221105-111817 - 5050.txt','Delimiter' ,',');
gps_data40 = readtable('20221105-110129 - 40ane60.txt','Delimiter' ,',');


%%
close all
figure
plot(gps_data30.speed_m_s_*3.6)
ylabel('Speed (km/h)')
%%
close all
figure
plot(gps_data50.speed_m_s_*3.6)
ylabel('Speed (km/h)')

%%
close all
figure
plot(gps_data40.speed_m_s_*3.6)
ylabel('Speed (km/h)')
