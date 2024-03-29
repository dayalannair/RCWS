% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
Ns1 = 200;
Ns2 = 0.75*Ns1;
fs = 200e3;
delta_t = 1/fs;

tm1 = Ns1*delta_t;
tm2 = Ns2*delta_t;

bw = 240e6;                     % Bandwidth
k1 = bw/tm1;
k2 = bw/tm2;


addpath('../../library/');

% Import data
subset = 1:1024;%200:205;

addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/m3_dual_11_07_2022/');
% iq_tbl=readtable('IQ_dual_240_200_06-24-54.txt','Delimiter' ,' ');
iq_tbl=readtable('IQ_dual_240_200_06-34-00_GOOD.txt','Delimiter' ,' ');
i_up1 = table2array(iq_tbl(subset,1:Ns1));
i_dn1 = table2array(iq_tbl(subset,Ns1 + 1:2*Ns1));
q_up1 = table2array(iq_tbl(subset,2*Ns1 + 1:3*Ns1));
q_dn1 = table2array(iq_tbl(subset,3*Ns1 + 1:4*Ns1));

i_up2 = table2array(iq_tbl(subset,4*Ns1 + 1:4.75*Ns1));
i_dn2 = table2array(iq_tbl(subset,4.75*Ns1+1:5.5*Ns1));
q_up2 = table2array(iq_tbl(subset,5.5*Ns1+1:6.25*Ns1));
q_dn2 = table2array(iq_tbl(subset,6.25*Ns1+1:7*Ns1));

% Compare to square law detector
iq_up1 = i_up1 + 1i*q_up1;
iq_dn1 = i_dn1 + 1i*q_dn1;

iq_up2 = i_up2 + 1i*q_up2;
iq_dn2 = i_dn2 + 1i*q_dn2;

% Gaussian Window
% remember to increase fft point size
% n_sweeps = size(i_up,1);
% gwinu1 = gausswin(200);
% gwinu2 = gausswin(150);
% gwind1 = gausswin(200);
% gwind2 = gausswin(150);
% % iq_up1 = gwinu1.'.*iq_up1;
% % iq_dn1 = gwind1.'.*iq_dn1;
% % iq_up2 = gwinu2.'.*iq_up2;
% % iq_dn2 = gwind2.'.*iq_dn2;

% Taylor Window
nbar = 4;
sll = -38;
twinu = taylorwin(Ns1, nbar, sll);
twind = taylorwin(Ns1, nbar, sll);
iq_up1 = iq_up1.*twinu.';
iq_dn1 = iq_dn1.*twind.';

twinu = taylorwin(Ns2, nbar, sll);
twind = taylorwin(Ns2, nbar, sll);
iq_up2 = iq_up2.*twinu.';
iq_dn2 = iq_dn2.*twind.';

% FFT
n_sweeps = length(subset);
n_fft1 = 1024;%512;
% n_fft2 = 150;
n_fft2 = n_fft1;
% factor of signal to be nulled. 4% determined experimentally
% nul_width_factor = 0.1;
% num_nul1 = round((n_fft1/2)*nul_width_factor);
% num_nul2 = round((n_fft2/2)*nul_width_factor);
% FFT
IQ_UP1 = fft(iq_up1,n_fft1,2);
IQ_DN1 = fft(iq_dn1,n_fft1,2);

IQ_UP2 = fft(iq_up2,n_fft2,2);
IQ_DN2 = fft(iq_dn2,n_fft2,2);

% Define axes
f = f_ax(n_fft1, fs);
f_neg = f(1:n_fft1/2);
f_pos = f((n_fft1/2 + 1):end);

rng_ax1 = beat2range(f_pos',k1,c);
rng_ax2 = beat2range(f_pos',k2,c);

% Halve FFTs
IQ_UP1 = IQ_UP1(:, 1:n_fft1/2);
IQ_UP2 = IQ_UP2(:, 1:n_fft2/2);

IQ_DN1 = IQ_DN1(:, n_fft1/2+1:end);
IQ_DN2 = IQ_DN2(:, n_fft2/2+1:end);

% Nulling feedthrough
% NOTE: nulling affects CFAR. Rather 'null' CFAR i.e.
% Take detections above R min/fb min
% r_min = 10;
% fb_min1 = range2beat(r_min, k1,c);
% fb_min2 = range2beat(r_min, k2,c);
% 
% n_min = find(f_pos==fb_min1);
% 
% % Because same size FFT
% % Otherwise need diff axes for diff sizes
% num_nul1 = n_min;
% num_nul2 = n_min;
% 
% IQ_UP1(:, 1:num_nul1) = 0;
% IQ_UP2(:, 1:num_nul2) = 0;
% 
% IQ_DN1(:, end-num_nul1+1:end) = 0;
% IQ_DN2(:, end-num_nul2+1:end) = 0;

% Repmat is worse for CFAR
% IQ_UP1(:, 1:num_nul1) = repmat(IQ_UP1(:,num_nul1+1),1,num_nul1);
% IQ_UP2(:, 1:num_nul2) = repmat(IQ_UP2(:,num_nul2+1),1,num_nul2);
% 
% IQ_DN1(:, end-num_nul1+1:end) = repmat(IQ_DN1(:,end-num_nul1),1,num_nul1);
% IQ_DN2(:, end-num_nul2+1:end) = repmat(IQ_DN2(:,end-num_nul2),1,num_nul2);

% CFAR
guard1 = 2*n_fft1/Ns1;
guard1 = floor(guard1/2)*2; % make even

% guard2 = 2*n_fft2/Ns1;
% guard2 = floor(guard2/2)*2; % make even
% too many training cells results in too many detections
% train1 = round(20*n_fft1/Ns1);
% train1 = floor(train1/2)*2;

train = round(20*n_fft1/Ns1);
train = floor(train/2)*2;

% false alarm rate - sets sensitivity
F = 10e-3; % see relevant papers

OS = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',train);

% modify CFAR code to simultaneously record beat frequencies
% up_det1 = CFAR(abs(IQ_UP1)', 1:n_fft);
% dn_det1 = CFAR(abs(IQ_DN1)', 1:n_fft);
% 
% up_det2 = CFAR(abs(IQ_UP2)', 1:n_fft);
% dn_det2 = CFAR(abs(IQ_DN2)', 1:n_fft);

% GET APPROP TRAIN LENGTH FOR SHORTER TRIG
[up_det1, up_th1] = OS(abs(IQ_UP1)', 1:n_fft1/2);
[dn_det1, dn_th1] = OS(abs(IQ_DN1)', 1:n_fft1/2);

[up_det2, up_th2] = OS(abs(IQ_UP2)', 1:n_fft2/2);
[dn_det2, dn_th2] = OS(abs(IQ_DN2)', 1:n_fft2/2);

% Find peak magnitude/SNR
IQ_UP_pks1 = abs(IQ_UP1).*up_det1';
IQ_DN_pks1 = abs(IQ_DN1).*dn_det1';

IQ_UP_pks2 = abs(IQ_UP2).*up_det2';
IQ_DN_pks2 = abs(IQ_DN2).*dn_det2';

% Min range to elim CFAR feed through
r_min = 10;
% fb_min1 = range2beat(r_min, k1,c);
% fb_min2 = range2beat(r_min, k2,c);

% Using find needs exact values. Idx found manually and will be the same
% for nfft = 1024. Can find from range axis.
n_min1 = 83;
n_min2 = 111;
%%
Ntgt = 3;
% v_max = 60km/h , fd max = 2.7kHz approx 3kHz
v_max = 60/3.6; 
%fd_max = speed2dop(v_max, lambda)*2;
fd_max = 3e4;
fbu1 = zeros(n_sweeps,Ntgt);
fbd1 = zeros(n_sweeps,Ntgt);
fbu2 = zeros(n_sweeps,Ntgt);
fbd2 = zeros(n_sweeps,Ntgt);
rg1_array = zeros(n_sweeps,Ntgt);
fd1_array = zeros(n_sweeps,Ntgt);
sp1_array = zeros(n_sweeps,Ntgt);
rg2_array = zeros(n_sweeps,Ntgt);
fd2_array = zeros(n_sweeps,Ntgt);
sp2_array = zeros(n_sweeps,Ntgt);

true_rng = zeros(n_sweeps,Ntgt);
true_spd = zeros(n_sweeps,Ntgt);
count = 0;
% close all
% figure
for i = 1:n_sweeps
%    tiledlayout(2,2)
%     nexttile
%     plot(flip(rng_ax1(n_min1:end)),absmagdb(IQ_DN1(i,1:end-n_min1+1)))
%     title("Down chirp flipped FFT: Triangle 1")
%     xlabel("Range (m)")
%     hold on
%     stem(flip(rng_ax1(n_min1:end)),absmagdb(IQ_DN_pks1(i,1:end-n_min1+1)))
%     hold on
%     plot(flip(rng_ax1(n_min1:end)),absmagdb(dn_th1(1:end-n_min1+1,i)))
%     hold off
%     nexttile
%     plot(rng_ax1(n_min1:end), absmagdb(IQ_UP1(i,n_min1:end)))
%     title("Up chirp FFT: Triangle 1")
%     xlabel("Range (m)")
%     hold on
%     stem(rng_ax1(n_min1:end), absmagdb(IQ_UP_pks1(i,n_min1:end)))
%     hold on
%     plot(rng_ax1(n_min1:end), absmagdb(up_th1(n_min1:end,i)))
%     hold off
% 
%     nexttile
%     plot(flip(rng_ax2(n_min2:end)), absmagdb(IQ_DN2(i,1:end-n_min2+1)))
%     title("Down chirp flipped FFT: Triangle 2")
%     xlabel("Range (m)")
%     hold on
%     stem(flip(rng_ax2(n_min2:end)), absmagdb(IQ_DN_pks2(i,1:end-n_min2+1)))
%     hold on
%     plot(flip(rng_ax2(n_min2:end)), absmagdb(dn_th2(1:end-n_min2+1,i)))
%     hold off
%     nexttile
%     plot(rng_ax2(n_min2:end), absmagdb(IQ_UP2(i,n_min2:end)))
%     title("Up chirp FFT: Triangle 2")
%     xlabel("Range (m)")
%     hold on
%     stem(rng_ax2(n_min2:end), absmagdb(IQ_UP_pks2(i,n_min2:end)))
%     hold on
%     plot(rng_ax2(n_min2:end), absmagdb(up_th2(n_min2:end,i)))
%     hold off
%     pause(1)

    % Obtain highest peak - not good for multi targ and clutter
    [snru1, pk_idx_up1] = maxk(IQ_UP_pks1(i,n_min1:end), Ntgt);
    [snrd1, pk_idx_dn1] = maxk(IQ_DN_pks1(i,1:end-n_min1+1), Ntgt);
    [snru2, pk_idx_up2] = maxk(IQ_UP_pks2(i,n_min2:end), Ntgt);
    [snrd2, pk_idx_dn2] = maxk(IQ_DN_pks2(i,1:end-n_min2+1), Ntgt); 

    % Obtain beat frequencies
    fbu1(i,:) = f_pos(pk_idx_up1);
    fbd1(i,:) = f_neg(pk_idx_dn1);
    fbu2(i,:) = f_pos(pk_idx_up2);
    fbd2(i,:) = f_neg(pk_idx_dn2);

    % Obtain Doppler shifts
    fd1 = -fbd1(i,:) - fbu1(i,:);
    fd2 = -fbd2(i,:) - fbu2(i,:);

    % 400 used for 195 fd
%     if and(abs(fd)<=fd_max, fd > 400)
    for tgt = 1:Ntgt
        fd1_array(i,tgt) = fd1(tgt)/2;
        if ((abs(fd1(tgt)/2) < fd_max))% && (abs(fd1(tgt)/2) ~= 0))
            sp1_array(i,tgt) = round(dop2speed(fd1(tgt)/2,lambda)/2);
            rg1_array(i,tgt) = round(beat2range([fbu1(i,tgt) fbd1(i,tgt)], k1, c));
        end
        fd2_array(i,tgt) = fd2(tgt)/2;
        if ((abs(fd2(tgt)/2) < fd_max))% && (abs(fd2(tgt)/2) ~= 0))
            sp2_array(i,tgt) = round(dop2speed(fd2(tgt)/2,lambda)/2);
            rg2_array(i,tgt) = round(beat2range([fbu2(i,tgt) fbd2(i,tgt)], k2, c));
        end
        
        % What if there is Doppler shift which changes from one to 
        % other? for now using Dopp of first triangle
%         if (rg1_array(i,tgt) == rg2_array(i,tgt))
%             true_rng(i,tgt) = rg1_array(i,tgt);
%             true_spd(i,tgt) = sp1_array(i,tgt);
%         end
    end
%     for tgt = 1:Ntgt
%         % if target at range x from first trig is in the 
%         % set of targets from second trig
%         if (ismember(rg1_array(i,tgt),rg2_array(i,:)))
%             true_rng(i,tgt) = rg1_array(i,tgt);
%             true_spd(i,tgt) = sp1_array(i,tgt);
%         end
%     end
    true_rng(i,:) = ismember(rg1_array(i,:),rg2_array(i,:)).*rg1_array(i,:);
    true_spd(i,:) = ismember(sp1_array(i,:),sp2_array(i,:)).*sp1_array(i,:);

end

%% Plots
% tm + tm + 0.75tm + 0.75tm = 3.5
t = linspace(0,3.5*n_fft1*tm1, n_sweeps);
% True results - Dual Rate ghost removal
close all
figure      
tiledlayout(2,1)
nexttile
plot(t, true_rng)
nexttile
plot(t, true_spd.*3.6)
%%

% Results
% close all
figure
tiledlayout(4,1)
nexttile
plot(rg1_array)
title("Triangle 1 range estimates")
nexttile
plot(rg2_array)
title("Triangle 2 range estimates")
nexttile
plot(sp1_array)
title("Triangle 1 range estimates")
nexttile
plot(sp2_array)
title("Triangle 2 speed estimates")



% Determine range
% range_array = beat2range([ ])


