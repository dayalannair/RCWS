addpath('../../library/');
addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby/');
iq_tbl=readtable('IQ_tri_20kmh.txt','Delimiter' ,' ');

%% 
% reform data to the uRAD output
subset = 1;
i_data = table2array(iq_tbl(subset,1:400));
q_data = table2array(iq_tbl(subset,401:800));

%%
% call function
safety = zeros(length(subset),1);
% nbins = 16;
% bin_width = (n_fft/2)/nbins;
% fbu = zeros(n_sweeps,nbins);
% fbd = zeros(n_sweeps,nbins);
% 
% rg_array = zeros(n_sweeps,nbins);
% fd_array = zeros(n_sweeps,nbins);
% sp_array = zeros(n_sweeps,nbins);
for s = 1:length(subset)
    [safety(s), IQ_UP1, IQ_DN1, rg_array1, sp_array1, fbu1, fbd1, os_pku1, os_pkd1] = process_trig_sweep(i_data(s, :), q_data(s, :));
end

close all
figure
tiledlayout(2,1)
nexttile
plot(rg_array)
nexttile
plot(sp_array)
% nexttile
% plot(abs(IQ_UP))
% nexttile
% plot(abs(IQ_DN))


