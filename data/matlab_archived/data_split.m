%% Split large data set into portions as needed
n_sweeps = 8192;
f_name = 'IQ_0_8192_sweeps';

iq_tbl=readtable('IQ.txt','Delimiter' ,' ');
%%
writetable(iq_tbl(1:n_sweeps, :), f_name, WriteVariableNames=false, Delimiter=' ');
