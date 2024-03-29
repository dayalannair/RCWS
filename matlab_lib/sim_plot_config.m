%% Simulation Loop
close all
% Generate visuals
% sceneview = phased.ScenarioViewer('BeamRange',[62.5 62.5],...
%     'BeamWidth',[30 30; 30 30], ...
%     'BeamSteering', [0 180;0 0], ...% [180; 0]
%     'ShowBeam', 'All', ...
%     'CameraPerspective', 'Custom', ...
%     'CameraPosition', [1464.92 -1515.03 1273.71], ...
%     'CameraOrientation', [-134.68 -30.87 0]', ...
%     'CameraViewAngle', 1.45, ...
%     'ShowName',false,...
%     'ShowPosition', true,...
%     'ShowSpeed', true,...
%     'ShowRadialSpeed',false,...
%     'ShowRange', false, ...
%     'UpdateRate',1/t_step, ...
%     'Position', [100 50 1000 700]);

% Dual radar
sceneview = phased.ScenarioViewer('PlatformNames', ...
    {'RHS Radar', 'LHS Radar', ...
    'Car 1', 'Car 2', 'Car 3', 'Car 4'},...
    'ShowLegend',true,...
    'BeamRange',[62.5 62.5],...
    'BeamWidth',[30 30; 30 30], ...
    'ShowBeam', 'All', ...
    'CameraPerspective', 'Custom', ...
    'CameraPosition', [1717.47 -1486.93 912.57], ...
    'CameraOrientation', [-138.99 -21.76 0]', ...
    'CameraViewAngle', 1.5, ...
    'ShowName',false,...
    'ShowPosition', false,...
    'ShowSpeed', false,...
    'UpdateRate',1/t_step, ...
    'ShowRadialSpeed', true,...
    'ShowRange', true, ...
    'BeamSteering', [0 180;0 0], ...
    'Position',   [2.0000   42.0000  638.0000  605.3333]);

[rdr_pos,rdr_vel] = radarmotion(0.00000000000000000000000000000001);
[tgt_pos,tgt_vel] = carmotion(0.00000000000000000000000000000001);

f1 = figure('WindowState','normal', 'Position',[0 100 800 700], ...
    'DefaultAxesFontSize',14);
movegui(f1, "west")




fbu1   = zeros(nswp1, nbins);
fbd1   = zeros(nswp1, nbins);
fdMtx1 = zeros(nswp1, nbins);
rgMtx1 = zeros(nswp1, nbins);
spMtx1 = zeros(nswp1, nbins);
safety = zeros(nswp1, 1);
t_safe = 3.5;
spMtxCorr1 = zeros(nswp1, nbins);




tiledlayout(2,2, 'Padding', 'none', 'TileSpacing', 'compact'); 
nexttile
% subplot(2,2,1);
p1 = plot(rng_ax, absmagdb(IQ_UP(1:round(nfft/2))));
% p1 = plot(rng_ax, absmagdb(pkuClean1));
hold on
p1th = plot(rng_ax, absmagdb(upTh1(1:round(nfft/2))));
% p1th = plot(zeros(200,1));
x  =linspace(1, nbins, nbins);
colors = cat(2, 2*x, 2*x);
win1 = scatter(cat(1,fb_idx1, fb_idx_end1), ones(2*nbins, 1)*BIN_MAG, ...
    2000, colors, 'Marker', '|', 'LineWidth',1.5);
hold off
title("Up-chirp Positive Spectrum")
% axis([0 200 0 1.0e-04])
axis(ax_dims)
xlabel("Range (m)")
ylabel("Magnitude (dB)")
% xticks(ax_ticks)
grid on
nexttile
% subplot(2,2,2);
p2 = plot(rng_ax, absmagdb(IQ_DN(1:round(nfft/2))));
% p2 = plot(rng_ax, absmagdb(pkdClean1));
hold on
p2th = plot(rng_ax, absmagdb(dnTh1(1:round(nfft/2))));
win2 = scatter(cat(1,fb_idx1, fb_idx_end1), ones(2*nbins, 1)*BIN_MAG, ...
    2000, colors, 'Marker', '|', 'LineWidth',1.5);
hold off
title("Down-chirp Reflected Negative Spectrum")
xlabel("Range (m)")
ylabel("Magnitude (dB)")
axis(ax_dims)
% xticks(ax_ticks)
grid on
nexttile
% subplot(2,2,3)
% p3 = imagesc(rgMtx1);
p3 = plot(t_ax, safety);
title('Time of Arrival of Detected Target/s')
xlabel('Time (s)')
ylabel('Time of Arrival (s)')

rg_bin_lbl = strings(1,nbins);
% rax = linspace(0,62,32);
for bin = 0:(nbins-1)
    first = round(rng_ax(bin*bin_width+1));
    last = round(rng_ax((bin+1)*bin_width));
    rg_bin_lbl(bin+1) = strcat(num2str(first), " - ", num2str(last));
end
nexttile
% subplot(2,2,4)
% p4 = imagesc([], t_ax, spMtx1*3.6);
p4 = imagesc([], t_ax, spMtxCorr1*3.6);
set(gca, 'XTick', 1:1:nbins, 'XTickLabel', rg_bin_lbl, 'CLim', [0 80], ...
    'YDir','normal')
cb = colorbar;
ylabel(cb, "Speed (km/h)")
title('Time vs. Range vs. Speed')
xlabel("Range bin (meters)")
ylabel("Time (s)")