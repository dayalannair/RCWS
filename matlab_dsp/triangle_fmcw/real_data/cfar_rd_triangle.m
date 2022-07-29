% Import data and parameters
subset = 1:512;%200:205;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(subset);
n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);

% Taylor Window
% nbar = 4;
% sll = -38;
% twinu = taylorwin(n_samples, nbar, sll);
% twind = taylorwin(n_samples, nbar, sll);
% iq_u = iq_u.*twinu.';
% iq_d = iq_d.*twind.';

% FFT
n_fft = 1024;%512;
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

IQ_UP = fft(iq_u,n_fft,2);
IQ_DN = fft(iq_d,n_fft,2);

% Halve FFTs
IQ_UP = IQ_UP(:, 1:n_fft/2);
IQ_DN = IQ_DN(:, n_fft/2+1:end);

% Null feedthrough
IQ_UP(:, 1:num_nul) = 0;
IQ_DN(:, end-num_nul+1:end) = 0;

% CFAR
guard = 2*n_fft/n_samples;
guard = floor(guard/2)*2; % make even
% too many training cells results in too many detections
train = round(20*n_fft/n_samples);
train = floor(train/2)*2;
% false alarm rate - sets sensitivity
F = 10e-3; 
N = train - guard;
rank = round(3*N/4);
OS = phased.CFARDetector('NumTrainingCells',train, ...
    'NumGuardCells',guard, ...
    'ThresholdFactor', 'Auto', ...
    'ProbabilityFalseAlarm', F, ...
    'Method', 'OS', ...
    'ThresholdOutputPort', true, ...
    'Rank',rank);

% Filter peaks/ peak detection
[up_os, os_thu] = OS(abs(IQ_UP)', 1:n_fft/2);
[dn_os, os_thd] = OS(abs(IQ_DN)', 1:n_fft/2);

% Find peak magnitude/SNR
os_pku = abs(IQ_UP).*up_os';
os_pkd = abs(IQ_DN).*dn_os';

% Define frequency axis
fs = 200e3;
f = f_ax(n_fft, fs);
f_neg = f(1:n_fft/2);
f_pos = f((n_fft/2 + 1):end);

% Define range axis
rng_ax = beat2range(f_pos',k,c);

% v_max = 60km/h , fd max = 2.7kHz approx 3kHz
v_max = 60/3.6; 
%fd_max = speed2dop(v_max, lambda)*2;
fd_max = 3e3;
Ntgt = 4;
fbu = zeros(n_sweeps,Ntgt);
fbd = zeros(n_sweeps,Ntgt);
rg_array = zeros(n_sweeps,Ntgt);
fd_array = zeros(n_sweeps,Ntgt);
sp_array = zeros(n_sweeps,Ntgt);

% Minimum sample number for 1024 point FFT corresponding to min range = 10m
n_min = 83;
%%
% close all
% figure
for i = 1:n_sweeps
    tiledlayout(2,1)
    nexttile
    plot(flip(rng_ax(n_min:end)),absmagdb(IQ_DN(i,1:end-n_min+1)))
    title("Down chirp flipped FFT")
    xlabel("Range (m)")
    hold on
    stem(flip(rng_ax(n_min:end)),absmagdb(os_pkd(i,1:end-n_min+1)))
    hold on
    plot(flip(rng_ax(n_min:end)),absmagdb(os_thd(1:end-n_min+1,i)))
    hold off
    nexttile
    plot(rng_ax(n_min:end), absmagdb(IQ_UP(i,n_min:end)))
    title("Up chirp FFT")
    xlabel("Range (m)")
    hold on
    stem(rng_ax(n_min:end), absmagdb(os_pku(i,n_min:end)))
    hold on
    plot(rng_ax(n_min:end), absmagdb(os_thu(n_min:end,i)))
    hold off
    pause(0.1)

    [magu, idx_u]= maxk(os_pku(i,:),Ntgt);
    [magd, idx_d] = maxk(os_pkd(i,:),Ntgt);

    fbu(i,:) = f_pos(idx_u);
    fbd(i,:) = f_neg(idx_d);

    fd = -fbu(i,:) - fbd(i,:);
    for tgt = 1:Ntgt
        fd_array(i,tgt) = fd(tgt)/2;
        if ((abs(fd(tgt)/2) < fd_max) && (abs(fd(tgt)/2) ~= 0))
            sp_array(i,tgt) = dop2speed(fd(tgt)/2,lambda)/2;
            rg_array(i,tgt) = beat2range([fbu(i,tgt) fbd(i,tgt)], k, c);
        end
    end
end

%% Previous Hold zero filter
% Similar to tracking. Find out if valid
% for col = 2:size(sp_array,2)
%     for row = 2:size(sp_array,1)
%         if (sp_array(row,col) == 0)
%             sp_array(row,col) = sp_array(row-1,col);
%         end
%         if (rg_array(row,col) == 0)
%             rg_array(row,col) = rg_array(row-1,col);
%         end
%     end
% end
%% Plots
t = linspace(0,n_sweeps*tm, n_sweeps);
% True results - Dual Rate ghost removal
close all
figure      
tiledlayout(2,1)
nexttile
plot(t, rg_array(:,3))
nexttile
plot(t, sp_array(:,3).*3.6)

