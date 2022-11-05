%% Real time results visualisation
% This script reads in real time processed data stored in a shared OneDrive
% repository and plots these as colour maps. 
% Also can plot range/speed/safety vs. time
% addpath(['../../../../../OneDrive - University of Cape' ...
%     ' Town/RCWS_DATA/road_data_03_11_2022/']);

addpath(['../../../../OneDrive - University of Cape' ...
    ' Town/RCWS_DATA/testing_05_11_2022']);

date = '_07_57_29';
l_rng_t = readtable(strcat('lhs_range_results',date,'.txt'),'Delimiter' ,' ');
l_spd_t = readtable(strcat('lhs_speed_results',date,'.txt'),'Delimiter' ,' ');
l_sft_t = readtable(strcat('lhs_safety_results',date,'.txt'),'Delimiter' ,' ');

r_rng_t = readtable(strcat('rhs_range_results',date,'.txt'),'Delimiter' ,' ');
r_spd_t = readtable(strcat('rhs_speed_results',date,'.txt'),'Delimiter' ,' ');
r_sft_t = readtable(strcat('rhs_safety_results',date,'.txt'),'Delimiter' ,' ');

vid_urad1 = strcat('lhs_vid',date,'_rtproc.avi');
vid_urad2 = strcat('rhs_vid',date,'_rtproc.avi');
% flip names to flip video order
vid2 = VideoReader(vid_urad1);
vid1 = VideoReader(vid_urad2);

%% FOR ROTATING RHS VID
% vd = read(vid2);
% v2flip = rot90(vd, 2);
% V_flip = VideoWriter('rhs_vid_12_18_12_flipped.avi','Uncompressed AVI'); 
% open(V_flip)
% writeVideo(V_flip,v2flip)
% close(V_flip)
% return;


l_rng = table2array(l_rng_t);
l_spd = table2array(l_spd_t);

r_rng = table2array(r_rng_t);
r_spd = table2array(r_spd_t);


close all
figure
tiledlayout(1, 2)
nexttile
% imagesc(l_spd);
% imagesc(l_spd);
imagesc(l_rng);
nexttile
% imagesc(r_spd);
imagesc(r_rng);