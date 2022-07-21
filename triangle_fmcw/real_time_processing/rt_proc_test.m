addpath('../../library/');
addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
iq_tbl=readtable('IQ_tri_20kmh.txt','Delimiter' ,' ');

%% 
% reform data to the uRAD output
subset = 1:2000;
i_data = table2array(iq_tbl(subset,1:400));
q_data = table2array(iq_tbl(subset,401:800));

%%
% call function
safety1 = zeros(length(subset),1);
% nbins = 16;
% bin_width = (n_fft/2)/nbins;
% fbu = zeros(n_sweeps,nbins);
% fbd = zeros(n_sweeps,nbins);
% 
% rg_array = zeros(n_sweeps,nbins);
% fd_array = zeros(n_sweeps,nbins);
% sp_array = zeros(n_sweeps,nbins);
for s = 1:2%length(subset)
    tic
    safety1(s) = process_trig_sweep(i_data(s, :), q_data(s, :));
    toc
end

% Compare plot below to the matrix version in triangle_multi_data_proc.m
% close all
figure
plot(safety1)
% tiledlayout(2,1)
% nexttile
% plot(rg_array1)
% nexttile
% plot(sp_array1)
% nexttile
% plot(abs(IQ_UP))
% nexttile
% plot(abs(IQ_DN))


