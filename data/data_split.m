%% Split large data set into portions as needed
n_sweeps = 1024;
f_name = 'IQ_0_1024_sweeps';

iq_tbl=readtable('IQ.txt','Delimiter' ,' ');
%%
writetable(iq_tbl(1:n_sweeps, :), f_name, WriteVariableNames=false, Delimiter=' ');
