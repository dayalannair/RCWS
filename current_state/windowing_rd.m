sweeps = 1:1024;% 200:205;
[fc, c, lambda, tm, bw, k, iq_u, iq_d, t_stamps] = import_data(sweeps);
%F = 0.015; % see relevant papers


n_samples = size(iq_u,2);
n_sweeps = size(iq_u,1);

%%
gwin = gausswin(n_samples);

u = iq_u(200,:).';

uwin = u.*gwin;

close all
figure
plot(real(uwin))