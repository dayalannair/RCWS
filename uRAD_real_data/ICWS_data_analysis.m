close all
urad_pi = readtable('uRAD_Pi_results.txt','Delimiter' ,' ');
urad_usb = readtable('uRAD_USB_results.txt','Delimiter' ,' ');

% extract target 1 and target 2 data
% since only two targets, can use if/else
% two for loops, since each sensor provides different amount of data
% (MTI enabled - data returned only for moving targets)

pi_targ1 = zeros(height(urad_pi), 3);
usb_targ1 = zeros(height(urad_usb), 3);

pi_targ2 = zeros(height(urad_pi), 3);
usb_targ2 = zeros(height(urad_usb), 3);

% Needed as gaps will occur in targ 1 array when targ 2 is next in table
array_index1 = 0;
array_index2 = 0;

for i = 1:height(urad_pi)
    if (urad_pi.Var1(i) == 1)
        array_index1 = array_index1 + 1;
        pi_targ1(array_index1,:) = table2array(urad_pi(i, 2:end-1));
    else
        array_index2 = array_index2 + 1;
        pi_targ2(array_index2,:) = table2array(urad_pi(i, 2:end-1));
    end
end
size_pitarg_1 = array_index1;
size_pitarg_2 = array_index2;

array_index1 = 0;
array_index2 = 0;

for i = 1:height(urad_usb)
    if (urad_usb.Var1(i) == 1)
        array_index1 = array_index1 + 1;
        usb_targ1(array_index1,:) = table2array(urad_usb(i, 2:end-1));
    else
        array_index2 = array_index2 + 1;
        usb_targ2(array_index2,:) = table2array(urad_usb(i, 2:end-1));        
    end
end

size_usbtarg_1 = array_index1;
size_usbtarg_2 = array_index2;

% resize arrays
pi_targ1 = pi_targ1(1:size_pitarg_1, :);
usb_targ1 = usb_targ1(1:size_usbtarg_1, :);

% verify there was second targets
if (size_pitarg_2 > 0)
    pi_targ2 = pi_targ2(1:size_pitarg_2, :);
end

if (size_usbtarg_2 > 0)
    usb_targ2 = usb_targ2(1:size_usbtarg_2, :);
end


%imagesc(usb_targ1(:,1), usb_targ1(:,2), usb_targ1(:,3));
figure
tiledlayout(1,2)
nexttile
scatter(usb_targ1(:,1), usb_targ1(:,2), 50,  usb_targ1(:,3), 'filled')
xlabel("distance")
ylabel("velocity")
title("USB Target 1 data");
colorbar
nexttile
scatter(pi_targ1(:,1), pi_targ1(:,2), 50,  pi_targ1(:,3), 'filled')
xlabel("distance")
ylabel("velocity")
title("RPi Target 1 data");
colorbar

figure
tiledlayout(2,2)

nexttile
plot(usb_targ1(:,1))
ylabel("Distance (m)");
xlabel("Time");

nexttile
plot(pi_targ1(:,1))
ylabel("Distance (m)");
xlabel("Time");

nexttile
plot(usb_targ1(:,2))
ylabel("Velocity (m/s)");
xlabel("Time");

nexttile
plot(pi_targ1(:,2))
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



