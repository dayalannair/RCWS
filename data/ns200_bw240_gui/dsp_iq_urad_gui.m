%% Parameters
fc = 24.005e9;
c = physconst('LightSpeed');
lambda = c/fc;
tm = 1e-3;                      % Ramp duration
bw = 240e6;                     % Bandwidth
sweep_slope = bw/tm;

%% Import data
I_u = readtable('I_up_FMCW_triangle.txt','Delimiter' ,' ');
I_d = readtable('I_down_FMCW_triangle.txt','Delimiter' ,' ');
Q_u = readtable('Q_up_FMCW_triangle.txt','Delimiter' ,' ');
Q_d = readtable('Q_down_FMCW_triangle.txt','Delimiter' ,' ');
i = table2array(I_u(:,1:end-2)) + table2array(I_d(:,1:end-2));
q = table2array(Q_u(:,1:end-2)) + table2array(Q_d(:,1:end-2));
time = I_u.Var202;
iq = i + 1i*q;
%% FFT

% Ns = 400;
% iq = padarray(iq,[0 4096 - Ns], 'post');
Ns = size(iq, 2);
Fs = 200e3;
f = f_ax(Ns, Fs);
gwin = gausswin(Ns);

IQ = fftshift(fft(iq,[],2),2);

close all
figure
plot(f, abs(IQ))
%%
noise_level = 75; % dB
signal_level = 85;
SNR = signal_level/noise_level;
disp(SNR)

%% Extract peaks
sweeps = size(i,1);
IQ_mag = abs(IQ);
pks = zeros(sweeps, 2);
fbs = zeros(sweeps, 2);
freq_res = Fs/Ns; % Minimum separation between two targets
%% View peak detection
% close all
% figure
% %'MinPeakWidth',5*freq_res,
% % Specifying a minimum peak height can reduce processing time.
% % Prominence is roughly SNR
%findpeaks(IQ_mag(162,:), f,'MinPeakProminence',20, 'NPeaks', 3,'Annotate','extents');
%findpeaks(IQ_mag(162,:), f,'Annotate','extents')
%%
% Note: MinPeakDistance uses sort(descend) anyway
% "SortStr","descend"
close all
figure
fbu = zeros(344,1);
fbd = zeros(344,1);
IQ_mag(:, 1) = IQ_mag(:, 2);
for row = 1:sweeps
    %Extract the three tallest peaks
    pause(0.001)
    disp(row)
    findpeaks(IQ_mag(row,:), f/1000, 'MinPeakDistance', 1,'MinPeakProminence',1e4,'MinPeakHeight',0.5e4,'MinPeakWidth', 1, 'NPeaks', 4,'Annotate','extents');
   axis([-100 100 0 40e3])
    [peak, freq] = findpeaks(IQ_mag(row,:), f, 'MinPeakDistance', 1500,'MinPeakProminence',0.9e4,'MinPeakHeight',0.4e4,'MinPeakWidth', 1000, 'NPeaks', 4);
    % Ignore first peak due to feed through
        % Extract beat frequencies. Middle peak is from feed through
     if (numel(peak)>1)
         pk_sorted = sort(peak, 2, 'descend');
         idx = find(peak==pk_sorted(1));
         fq = freq(idx);
         if fq>1
            fbu(row) = fq;
            idx = find(peak==pk_sorted(2));
            fbd(row) = freq(idx);
         else
             fbd(row) = fq;
            idx = find(peak==pk_sorted(2));
            fbu(row) = freq(idx);
         end
     end
end

%% Estimates
% Extract distance
r = beat2range([fbu fbd],sweep_slope,c);
% Extract velocity
fd = (-fbd-fbu)/2;
%v = fd*lambda/2;
v = dop2speed(fd,lambda)/2;

for pos =  1:size(v,1)
    if abs(v(pos))>10 % check if v >10m/s
        v(pos) = v(pos-1);
    end
end

%% Plot estimates
t_total = time(end)-time(1);
t = linspace(0,t_total, size(r, 1));
close all
figure
tiledlayout(2,1)
nexttile
plot(t, r);
ylabel("Radial distance (m)")
xlabel("Time (s)")
nexttile
plot(t, v);
ylabel("Radial velocity (m/s)")
xlabel("Time (s)")
%% Plot peaks
% close all
% figure
% plot(fbs,pks);

%% Real-time view
% close all
% figure
% plot(f, 10*log(abs(IQ(50,:))))
% for row = 1:344
%     plot(f, 10*log(abs(IQ(row,:))))
%     yline(signal_level)
%     yline(noise_level)
%     pause(0.1)
% end














