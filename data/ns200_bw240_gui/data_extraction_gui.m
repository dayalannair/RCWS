close all
tbl = readtable('results1.txt','Delimiter' ,' ');
results = table2array(tbl(:, 2:4));
time = tbl.Var9;
t_total = time(end) - time(1);
%%
%imagesc(usb_targ1(:,1), usb_targ1(:,2), usb_targ1(:,3));
% figure
% scatter(usb_targ1(:,1), usb_targ1(:,2), 50,  usb_targ1(:,3), 'filled')
% xlabel("distance")
% ylabel("velocity")
% title("USB Target 1 data");
% colorbar

%% filter velocity spikes
for pos =  1:height(tbl)
    if abs(results(pos, 2))>10 % check if v >10m/s
        results(pos,2) = results(pos-1,2);
    end
end

%%

figure
tiledlayout(3,1)

nexttile
plot(time,results(:,1))
ylabel("Distance (m)");
xlabel("Time");

nexttile
plot(time, -results(:,2))
ylabel("Velocity (m/s)");
xlabel("Time");

nexttile
plot(time, results(:,3))
ylabel("SNR (dB)");
xlabel("Time");

% nexttile
% plot(pi_targ1(:,3))
% ylabel("SNR (dB)");
% xlabel("Time");

% contour3(results.Var2, results.Var3, results.Var4)
% xlabel("distance");
% ylabel("velocity")
% zlabel("snr")

%% Moving plot
entries = height(tbl);

figure
t_ax = linspace(0,t_total,entries);
for pos = 1:entries
    %p = time(0.04);
    pause(0.04)
    tiledlayout(3,1)
    nexttile
    plot(t_ax(1:pos),results(1:pos,1))
    ylabel("Distance (m)");
    xlabel("Time (s)");
%     xlim([time(1) time(end)])
%     ylim([0 50])
    nexttile
    plot(t_ax(1:pos), -results(1:pos,2))
    ylabel("Velocity (m/s)");
    xlabel("Time (s)");
%     axis([time(1) time(end) 0 10])
    nexttile
    plot(t_ax(1:pos), results(1:pos,3))
    ylabel("SNR (dB)");
    xlabel("Time (s)");
%     axis([time(1) time(end) 0 30])
end




