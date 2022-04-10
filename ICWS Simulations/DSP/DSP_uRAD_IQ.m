% rng('default')
% A = randi(99,[4,4]);
% writematrix(A,'URAD_IQ_data\test1\I_down_FMCW_triangle.txt','Delimiter',' ')
% type('URAD_IQ_data\test1\I_down_FMCW_triangle.txt')

clear

% run("..\models\uRAD_model.m");

uRAD_model;
%% uRAD shipped DSP results
results = readtable('..\URAD_IQ_data\test_3hand_waves\results.txt','Delimiter' ,' ');

% results.Properties.VariableDescriptions
% class(results.Var9)
Nsamples = height(results);
t = zeros(Nsamples);
%sampling_rates = zeros(Nsamples);
% for i = 1:Nsamples
%     %sampling_rates(i) = seconds(results.Var9(i+1)-results.Var9(i));
%     t(i) = 
% end

% mean_rate = mean(sampling_rates(:,1))
% total_duration = seconds(results.Var9(Nsamples) - results.Var9(1))
% t = 1:mean_rate:total_duration;
%res = results{:,:};
% Max update rate is 69 samples/second
% after checking time between samples (see table), the update rate varies
% between 69 - 80 samples per second
% For plotting purposes, we could average the difference between sample
% rates to get an average rate

t = results.Var9;

% tiledlayout(3,1);
% nexttile
% plot(t, results.Var2)
% ylabel("Distance (m)");
% xlabel("Time");
% nexttile
% plot(t, results.Var3)
% ylabel("Velocity (m/s)");
% xlabel("Time");
% nexttile
% plot(t, results.Var4)
% ylabel("SNR (dB)");
% xlabel("Time");

% contour3(results.Var2, results.Var3, results.Var4)
% xlabel("distance");
% ylabel("velocity")
% zlabel("snr")

%% My DSP using IQ data

I_up = readtable('..\URAD_IQ_data\test_3hand_waves\I_up_FMCW_triangle.txt','Delimiter' ,' ');
I_down = readtable('..\URAD_IQ_data\test_3hand_waves\I_down_FMCW_triangle.txt','Delimiter' ,' ');
Q_up = readtable('..\URAD_IQ_data\test_3hand_waves\Q_up_FMCW_triangle.txt','Delimiter' ,' ');
Q_down = readtable('..\URAD_IQ_data\test_3hand_waves\Q_down_FMCW_triangle.txt','Delimiter' ,' ');

% each row is one measurement/sample with last 2 columns = date and time
measurements = width(I_down)-2;
% all four tables have same number of samples
Nsamples = height(I_down);

% extract measurements from table into matrix. exclude date and time
I_up_data = table2array(I_up(:, 1:end-2));
I_down_data = table2array(I_down(:, 1:end-2));

Q_up_data = table2array(Q_up(:, 1:end-2));
Q_down_data = table2array(Q_down(:, 1:end-2));

% sum IQ for up and down chirp
IQ_up = I_up_data + 1i.*Q_up_data;
IQ_down = I_down_data + 1i.*Q_down_data;



% NOTE: one sample is one row
% sample = IQ_up(1, :)


% Step 1: dechirp received signal by mixing with received signal

% need a reference signal for both up and down chirp?
ref_sig = step(waveform);
sample = zeros(250,1);
% numel(sample1(1:measurements))
% numel(IQ_up(1,:))
all_IQ_up_dechirp = zeros(Nsamples, 250);
all_IQ_down_dechirp = zeros(Nsamples, 250);
for u = 1:Nsamples
    % extract one row of measurements
    sample(1:measurements) = IQ_up(u,:);
    % dechirp sample
    sample = dechirp(sample, ref_sig);
    % reshape and add to array of dechirped samples
    all_IQ_up_dechirp(u, :) = reshape(sample, [1, 250]);

    sample(1:measurements) = IQ_down(u,:);
    sample = dechirp(sample, ref_sig);
    all_IQ_down_dechirp(u, :) = reshape(sample, [1, 250]);
end

%sample(1:measurements) = IQ_up(1,:);
%IQ_up_dechirp = dechirp(sample, ref_sig);
all_IQ_up_dechirp = reshape(all_IQ_up_dechirp, [250, Nsamples]);
all_IQ_down_dechirp = reshape(all_IQ_down_dechirp, [250, Nsamples]);
% get up and down chirp beat frequencies

fbu_rng = rootmusic(pulsint(all_IQ_up_dechirp,'coherent'),1,fs);
fbd_rng = rootmusic(pulsint(all_IQ_down_dechirp,'coherent'),1,fs);


rng_est = beat2range([fbu_rng fbd_rng],sweepSlope,c)

fd = -(fbu_rng+fbd_rng)/2;
v_est = dop2speed(fd,lambda)/2



% plot(real(IQ_up_dechirp))
% IQ_down_dechirp = dechirp(IQ_down, ref_sig);

% Step 2: Find beat frequency
% for triangle sweep, need to find up and down beat freqs

%%





rngdopresp = phased.RangeDopplerResponse('PropagationSpeed',c,...
    'DopplerOutput','Speed','OperatingFrequency',fc,'SampleRate',fs,...
    'RangeMethod','FFT','SweepSlope',sweepSlope,...
    'RangeFFTLengthSource','Property','RangeFFTLength',2048,...
    'DopplerFFTLengthSource','Property','DopplerFFTLength',256);



 clf;
% % Plot range Doppler map
 plotResponse(rngdopresp,all_IQ_up_dechirp);                     
% 
% small values because had gestures used
axis([-2 2 0 5])
% 
% colour limits
clim = caxis;


%sum_IQ_up = I_up.V


% tiledlayout(2,1);
% nexttile
% plot(I_up_data);
% title("I data for the up chirp");
% ylabel("I up");
% %xlabel("Time");
% nexttile
% plot(I_down_data);
% title("I data for the down chirp");
% ylabel("I down");
%xlabel("Time");
% nexttile
% plot(t, results.Var4)
% ylabel("SNR (dB)");
% xlabel("Time");










% tiledlayout(2,1);
% nexttile
% plot(abs(IQ_up));
% title("IQ magnitude for the up chirp");
% ylabel("I up");
% %xlabel("Time");
% nexttile
% plot(abs(IQ_down));
% title("IQ magnitude for the down chirp");
% ylabel("I down");


%% Range-Doppler map
% uRAD_model; % use uRAD model to provide parameters to range doppler response function
% 
% rngdopresp = phased.RangeDopplerResponse('PropagationSpeed',c,...
%     'DopplerOutput','Speed','OperatingFrequency',fc,'SampleRate',fs,...
%     'RangeMethod','FFT','SweepSlope',sweep_slope,...
%     'RangeFFTLengthSource','Property','RangeFFTLength',2048,...
%     'DopplerFFTLengthSource','Property','DopplerFFTLength',256);
% 
% % clear any open plots
% clf;
% % Plot range Doppler map
% plotResponse(rngdopresp,xr);                     
% 
% 
% axis([-v_max v_max 0 r_max])
% 
% % colour limits
% clim = caxis;
