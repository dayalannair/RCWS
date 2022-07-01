%% Easier to use a separate script for plotting
cfar_rd;
%% Verify peak detection
close all
figure
tiledlayout(2,1)
nexttile
stem(f/1000, 10*log10(abs(IQ_UP_peaks))')
axis([-100 100 0 40])
nexttile
stem(f/1000, 10*log10(abs(IQ_DOWN_peaks))')
axis([-100 100 0 40])
%% Verify CFAR
% close all
% figure
% for i = 1:n_sweeps
% %     plot(abs(iq_up(i,:)));
%     plot(f(101:200)/1000, 40*up_detections(101:200,i)); % rows and columns opp to data
%     hold on
%     %plot(fftshift(IQ_UP_normal(i,:)))
%     plot(f(101:200)/1000, 10*log10(abs(IQ_UP(i,101:200))))
%     hold off
%     pause(0.1)
% end
% for i = 1:n_sweeps
% %     plot(abs(iq_up(i,:)));
%     plot(f(1:100)/1000, 40*fftshift(down_detections(1:100,i))); % rows and columns opp to data
%     hold on
%     %plot(fftshift(IQ_UP_normal(i,:)))
%     plot(f(1:100)/1000, 10*log10(abs(IQ_DOWN(i,1:100))))
%     hold off
%     pause(0.1)
% end
%%
% flipped -- no need, can do at time of calculation
% dds = flip(down_detections(1:100,:));
% close all
% figure
% tiledlayout(2,1)
% nexttile
% stem(down_detections);
% nexttile
% stem(flip(down_detections));
% 
% %%
% close all
% figure
% tiledlayout(4,1)
% nexttile
% stem(f(101:200)/1000, up_detections(101:200,:));
% nexttile
% stem(f(101:100)/1000, flip(down_detections)(1:100,:));
% nexttile
% stem(f/1000, up_detections);
% nexttile
% stem(f/1000, down_detections);
%%
% close all
% figure
% tiledlayout(4,1)

%% Time Axis formulation
% subtract first time from all others to start at 0s
t0 = time(1);
time = time - t0;

%% Plots
close all
figure('WindowState','maximized');
movegui('east')
tiledlayout(2,1)
nexttile
plot(time(subset), range_array)
title('Range estimations of APPROACHING targets')
xlabel('Time (seconds)')
ylabel('Range (m)')
% plot markings
% hold on 
% rectangle('Position',[0 0 6.6 15.6], 'EdgeColor','r', 'LineWidth',1)
% text(0,17,'BMW')
% rectangle('Position',[3.7 0 9.4580 15.6], 'EdgeColor','g', 'LineWidth',1)
% text(3.7,17,'Renault+Nissan')
% rectangle('Position',[13 0 8 30], 'EdgeColor','k', 'LineWidth',1)
% text(13.5,25,'Pedestrians only')
% rectangle('Position',[21.5 0 3.5 34], 'EdgeColor','r', 'LineWidth',1)
% text(22,32,'Pedestrians+Mini')
% rectangle('Position',[25.4 0 5.3 25], 'EdgeColor','g', 'LineWidth',1)
% text(25.5,26,'Pedestrians+Hyundai')
% rectangle('Position',[39 0 10 17], 'EdgeColor','m', 'LineWidth',1)
% text(40,18,'VW followed by Toyota')
% rectangle('Position',[56 0 24 32], 'EdgeColor','r', 'LineWidth',1)
% text(57,33,'2x Toyota - Area of Interest')
nexttile
plot(time(subset), speed_array*3.6)
title('Radial speed estimations of APPROACHING targets')
xlabel('Time (seconds)')
ylabel('Speed (km/h)')


%%
% IQ_UP_normal = normalize(abs(IQ_UP));


%%
% for i = 1:52
%     plot(fbu(i,:)/1000);
%     title("up chirp beat frequency");
%     xlabel("sample number");
%     ylabel("Frequency (kHz)");
%     axis([0 200 -100 100]);
%     hold on
%     plot(fbd(i,:)/1000);
%     title("down chirp beat frequency");
%     xlabel("sample number");
%     ylabel("Frequency (kHz)");
%     axis([0 200 -100 100]);
%     %hold off
%     pause(1)
% end
% plot(fftshift(detections));
% hold on
% plot(10*log10(fftshift(abs(IQ_UP))));

% plot(fbu'/1000);
% title("up chirp beat frequency");
% xlabel("sample number");
% ylabel("Frequency (kHz)");
% axis([0 200 -100 100]);
% hold on
% plot(fbd'/1000);
% title("down chirp beat frequency");
% xlabel("sample number");
% ylabel("Frequency (kHz)");
% axis([0 200 -100 100]);

%% Windowing
close all
figure 
tiledlayout(2,1)
nexttile
plot(f/1000,10*log10(abs(IQ_UP(200:205, :))))
nexttile
plot(f/1000,10*log10(abs(IQ_DOWN(200:205, :))))




