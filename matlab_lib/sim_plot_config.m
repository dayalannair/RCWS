%% Simulation Loop
close all
% Generate visuals
sceneview = phased.ScenarioViewer('BeamRange',62.5,...
    'BeamWidth',[30; 30], ...
    'ShowBeam', 'All', ...
    'CameraPerspective', 'Custom', ...
    'CameraPosition', [2101.04 -1094.5 644.77], ...
    'CameraOrientation', [-152 -15.48 0]', ...
    'CameraViewAngle', 1.45, ...
    'ShowName',false,...
    'ShowPosition', false,...
    'ShowSpeed', false,...
    'ShowRadialSpeed',true,...
    'ShowRange', true, ...
    'UpdateRate',1/t_step);%, ...
%     'Position',[1000 100 1000 900]);

[rdr_pos,rdr_vel] = radarmotion(1);
[tgt_pos,tgt_vel] = carmotion(1);

f1 = figure('WindowState','normal', 'Position',[0 100 800 700]);
movegui(f1, "west")

subplot(2,2,1);
p1 = plot(rng_ax, absmagdb(IQ_UP(1:256)));
% p1 = plot(rng_ax, absmagdb(pkuClean1));
hold on
p1th = plot(rng_ax, absmagdb(upTh1(1:256)));
% p1th = plot(zeros(200,1));
x  =linspace(1, nbins, nbins);
colors = cat(2, 2*x, 2*x);
win1 = scatter(cat(1,fb_idx1, fb_idx_end1), ones(2*nbins, 1)*BIN_MAG, ...
    2000, colors, 'Marker', '|', 'LineWidth',1.5);
hold off
title("LHS UP chirp positive half")
% axis([0 200 0 1.0e-04])
axis(ax_dims)
xlabel("Range (m)")
ylabel("Magnitude (dB)")
% xticks(ax_ticks)
grid on

subplot(2,2,2);
p2 = plot(rng_ax, absmagdb(IQ_DN(1:256)));
% p2 = plot(rng_ax, absmagdb(pkdClean1));
hold on
p2th = plot(rng_ax, absmagdb(dnTh1(1:256)));
win2 = scatter(cat(1,fb_idx1, fb_idx_end1), ones(2*nbins, 1)*BIN_MAG, ...
    2000, colors, 'Marker', '|', 'LineWidth',1.5);
hold off
title("LHS DOWN chirp flipped negative half")
xlabel("Range (m)")
ylabel("Magnitude (dB)")
axis(ax_dims)
% xticks(ax_ticks)
grid on

subplot(2,2,3)
% p3 = imagesc(rgMtx1);
p3 = plot(t_ax, safety);
title('Time of Arrival of Detected Target/s')
ylabel('Time (s)')
xlabel('Time of Arrival (s)')

rg_bin_lbl = strings(1,nbins);
rax = linspace(0,62,32);
for bin = 0:(nbins-1)
    first = round(rng_ax(bin*bin_width+1));
    last = round(rng_ax((bin+1)*bin_width));
    rg_bin_lbl(bin+1) = strcat(num2str(first), " to ", num2str(last));
end

subplot(2,2,4)
p4 = imagesc([], t_ax, spMtx1*3.6);
set(gca, 'XTick', 1:1:nbins, 'XTickLabel', rg_bin_lbl, 'CLim', [0 80], ...
    'YDir','normal')
colorbar
title('Time vs. Range vs. Speed')
xlabel("Range bin (meters)")
ylabel("Time (s)")