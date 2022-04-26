close all
urad_usb = readtable('test/results.txt','Delimiter' ,' ');

% extract target 1 and target 2 data
% since only two targets, can use if/else
% two for loops, since each sensor provides different amount of data
% (MTI enabled - data returned only for moving targets)

% usb_targ1 = zeros(height(urad_usb), 3);
% usb_targ2 = zeros(height(urad_usb), 3);
% 
% % Needed as gaps will occur in targ 1 array when targ 2 is next in table
% array_index1 = 0;
% array_index2 = 0;
% 
% for i = 1:height(urad_usb)
%     if (urad_usb.Var1(i) == 1)
%         array_index1 = array_index1 + 1;
%         usb_targ1(array_index1,:) = table2array(urad_usb(i, 2:end-2));
%     else
%         array_index2 = array_index2 + 1;
%         usb_targ2(array_index2,:) = table2array(urad_usb(i, 2:end-2));        
%     end
% end
% 
% size_usbtarg_1 = array_index1;
% size_usbtarg_2 = array_index2;
% 
% % resize arrays
% usb_targ1 = usb_targ1(1:size_usbtarg_1, :);
% 
% % verify there was second targets
% if (size_usbtarg_2 > 0)
%     usb_targ2 = usb_targ2(1:size_usbtarg_2, :);
% end

result_array = table2array(urad_usb(:,2:4));

%imagesc(usb_targ1(:,1), usb_targ1(:,2), usb_targ1(:,3));
%%
figure
scatter(result_array(:,1), result_array(:,2), 50,  result_array(:,3), 'filled')
xlabel("distance")
ylabel("velocity")
title("USB Target 1 data");
colorbar

%%
figure
tiledlayout(2,1)

nexttile
plot(usb_targ1(:,1))
ylabel("Distance (m)");
xlabel("Time");

nexttile
plot(usb_targ1(:,2))
ylabel("Velocity (m/s)");
xlabel("Time");

% nexttile
% plot(usb_targ1(:,3))
% ylabel("SNR (dB)");
% xlabel("Time");

% nexttile
% plot(pi_targ1(:,3))
% ylabel("SNR (dB)");
% xlabel("Time");

% contour3(results.Var2, results.Var3, results.Var4)
% xlabel("distance");
% ylabel("velocity")
% zlabel("snr")



