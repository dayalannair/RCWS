%% Real time results visualisation
% This script reads in real time processed data stored in a shared OneDrive
% repository and plots these as colour maps. 
% Also can plot range/speed/safety vs. time
% addpath(['../../../../../OneDrive - University of Cape' ...
%     ' Town/RCWS_DATA/road_data_03_11_2022/']);

addpath(['../../../../OneDrive - University of Cape' ...
    ' Town/RCWS_DATA/testing_05_11_2022']);

time = '_11_33_17';
l_rng_t = readtable(strcat('lhs_range_results',time,'.txt'),'Delimiter' ,' ');
l_spd_t = readtable(strcat('lhs_speed_results',time,'.txt'),'Delimiter' ,' ');
l_sft_t = readtable(strcat('lhs_safety_results',time,'.txt'),'Delimiter' ,' ');

r_rng_t = readtable(strcat('rhs_range_results',time,'.txt'),'Delimiter' ,' ');
r_spd_t = readtable(strcat('rhs_speed_results',time,'.txt'),'Delimiter' ,' ');
r_sft_t = readtable(strcat('rhs_safety_results',time,'.txt'),'Delimiter' ,' ');

fvid_lhs = strcat('lhs_vid',time,'_rtproc.avi');
fvid_rhs = strcat('rhs_vid',time,'_rtproc.avi');
% flip names to flip video order
vid_lhs = VideoReader(fvid_lhs);
vid_rhs = VideoReader(fvid_rhs);

%% FOR ROTATING RHS VID
% vd = read(vid_lhs);
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


sweeps_processed = 553;
l_rng = l_rng(1:sweeps_processed,:);
l_spd = l_spd(1:sweeps_processed,:);

r_rng = r_rng(1:sweeps_processed,:);
r_spd = r_spd(1:sweeps_processed,:);
%%

% close all
% figure
% tiledlayout(1, 2)
% nexttile
% % imagesc(l_spd);
% % imagesc(l_spd);
% imagesc(l_rng);
% nexttile
% % imagesc(r_spd);
% imagesc(r_rng);

close all
figure
tiledlayout(2, 2)
nexttile
% imagesc(l_spd);
% imagesc(l_spd);
b1 = bar(l_rng(1,:));
nexttile
% imagesc(r_spd);
b2 = bar(r_rng(1,:));

vidFrame = readFrame(vid_rhs);
%     set(v1,'CData' ,vidFrame);
nexttile
v1 = imshow(vidFrame);
vidFrame = readFrame(vid_lhs);
%     set(v2, 'CData', vidFrame);
nexttile
v2 = imshow(vidFrame);
drawnow;
%     pause(0.01)

for i = 1:sweeps_processed
    vidFrame_l = readFrame(vid_lhs);
    vidFrame_r = readFrame(vid_rhs);
    

    set(b1, 'YData', l_rng(i,:))
    set(b2, 'YData', r_rng(i,:))
    set(v1, 'CData', vidFrame_l)
    set(v2, 'CData', vidFrame_r)
    pause(0.01)

end



