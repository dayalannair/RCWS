format long g
subset = 200:210;
iq_tbl=readtable('../../data/urad_usb/IQ_sawtooth.txt','Delimiter' ,' ');
i_dat = table2array(iq_tbl(subset,1:200));
q_dat = table2array(iq_tbl(subset,201:400));
iq = i_dat + 1i*q_dat;
%%

n_samples = size(i_dat,2);
n_sweeps = size(i_dat,1);

% Removed due to imprecision!
% time = iq_tbl.Var401;
% t0 = time(1);
% t_sweeps = time - t0;
% periods = diff(t_sweeps)/1e9;
% avg_period = mean(periods);

% t = zeros(n_sweeps, n_samples);
% % Smart but low key smart
% for i = 2:length(t_sweeps)
%     t(i,:) = linspace(t_sweeps(i-1),t_sweeps(i), n_samples);
% end
%%
close all
figure
tiledlayout(3,1)
nexttile
plot(i_dat')
title("Sawtooth I data")
nexttile
plot(q_dat')
title("Sawtooth Q data")
nexttile
plot(real(iq.'))
title("Sawtooth IQ data")

%%
IQ = fft(iq, [], 2);
fs = 200e3;
f = f_ax(200, fs)/1000;

close all
figure
tiledlayout(2,1)
nexttile
plot(f, 20*log10(fftshift(abs(IQ.'))))
title("Sawtooth FFT magnitude")
xlabel("Frequency (kHz)")
ylabel("Magnitude (dB)")
nexttile
plot(f, fftshift(angle(IQ.')))
title("Sawtooth FFT phase")
xlabel("Frequency (kHz)")
%ylabel("Magnitude (dB)")

%%
fs = 200e3;
f = f_ax(200, fs);

close all
figure
for i = 1:n_sweeps
%     plot(abs(iq_up(i,:)));
%     stem(f/1000,  10*log10(IQ_UP_peaks(i,:))); % rows and columns opp to data
%     hold on
    %plot(fftshift(IQ_UP_normal(i,:)))
    plot(f/1000, 10*log10(abs(IQ2D(:,i).')))
    hold on
    plot(f/1000, 10*log10(rng_th(i,:)))
    hold off
    pause(1)
end


%% Results

close all
figure('WindowState','maximized');
movegui('east')
% tiledlayout(2,1)
% nexttile
plot(range_array)
title('Range estimations of APPROACHING targets')
%xlabel('Time (seconds)')
ylabel('Range (m)')
% nexttile
% plot(speed_array*3.6)
% title('Radial speed estimations of APPROACHING targets')
% %xlabel('Time (seconds)')
% ylabel('Speed (km/h)')

%% 2D FFT
fs = 200e3;
f = f_ax(200, fs);

rng_bins = beat2range(f.', sweep_slope, c);
%spd_bins = 
close all
figure
imagesc([],rng_bins, 10*log10(fftshift(abs(IQ2D))))
ylabel("Range bin index")
xlabel("Doppler bin index")
%% Range and Doppler FFTs



fs = 200e3;
f = f_ax(200, fs);

close all
figure
for i = 1:n_sweeps
    tiledlayout(2,1)
    nexttile
    plot(f/1000, 10*log10(fftshift(abs(fft_frames(:,i, 8).'))))
    title("Range FFT")
    nexttile
    plot(10*log10(abs(fftshift(fft_frames(i,:,8).'))))
    title("Doppler FFT")
    hold off
    pause(1)
end




%% CFAR

% close all
% figure
% imagesc([],rng_bins, 10*log10(fftshift(rng_det.*))
% ylabel("Range bin index")
% xlabel("Doppler bin index")


% close all
% figure
% imagesc([],rng_bins, )
% ylabel("Range bin index")
% xlabel("Doppler bin index")
