%% Cell Averaging CFAR (Constant False Alarm Rate) peak detector
% Most basic/common CFAR algorithm
%% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
sweep_slope = bw/tm;

%% Import data
%iq_tbl=readtable('IQ_0_1024_sweeps.txt','Delimiter' ,' ');
iq_tbl=readtable('trig_fmcw_data\IQ_0_1024_sweeps.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ.txt','Delimiter' ,' ');
time = iq_tbl.Var801;
i_up = table2array(iq_tbl(:,1:200));
i_down = table2array(iq_tbl(:,201:400));
q_up = table2array(iq_tbl(:,401:600));
q_down = table2array(iq_tbl(:,601:800));

iq_up = i_up + 1i*q_up;
iq_down = i_down + 1i*q_down;

n_samples = size(i_up,2);
n_sweeps = size(i_up,1);

% v_max = 60km/h , fd max = 2.7kHz approx 3kHz
v_max = 60/3.6; 
%fd_max = speed2dop(v_max, lambda)*2;
fd_max = 3e3;
fb = zeros(n_sweeps,2);
range_array = zeros(n_sweeps,1);
fd_array = zeros(n_sweeps,1);
speed_array = zeros(n_sweeps,1);

fs = 200e3;
for i = 1:n_sweeps

    fbu = rootmusic(iq_up(i, :),2,fs);
    fbd= rootmusic(iq_down(i, :),2,fs);

    fb(i, 1) = fbu(2);
    fb(i, 2) = fbd(2);

    fd = -fb(i,1)-fb(i,2);

    fd_array(i) = fd/2;
    speed_array(i) = dop2speed(fd/2,lambda)/2;
    range_array(i) = beat2range([fb(i,1) fb(i,2)], sweep_slope, c);

end
% Determine range
% range_array = beat2range([ ])
%% Time Axis formulation
% subtract first time from all others to start at 0s
t0 = time(1);
time = time - t0;

%% Plots
% close all
figure('WindowState','maximized');
movegui('east')
tiledlayout(2,1)
nexttile
plot(time, range_array)
title('Range estimations of APPROACHING targets')
xlabel('Time (seconds)')
ylabel('Range (m)')

% plot markings for 8000 sample version
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
plot(time, speed_array*3.6)
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

