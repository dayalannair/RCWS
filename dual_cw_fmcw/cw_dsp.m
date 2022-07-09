addpath('../../library/');
% Import data
%iq_tbl=readtable('IQ_sawtooth4096_backyrd.txt', 'Delimiter' ,' ');
iq_tbl=readtable('iq_CW_fmcw_12-40-09.txt', 'Delimiter' ,' ');
i_dat = table2array(iq_tbl(:,1:200));
q_dat = table2array(iq_tbl(:,201:400));
iq = i_dat + 1i*q_dat;
%%
% Dimensions
n_samples = size(i_dat,2);
n_sweeps = size(i_dat,1);

IQ = fft(iq,[],2);
close all
figure
plot(sftmagdb(IQ).')
