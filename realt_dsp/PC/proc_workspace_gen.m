% This script generates a fixed parameter workspace for the default 
% system configuration
% HOW TO USE:
% 1. Edit and run this script
% 2. Save as/overwrite current config .mat file
% 3. Run python real time program
% Radar parameters
[c, lambda, k, Ns] = proc_param(); 
n_fft = 512;
% Taylor window
nbar = 4;
sll = -38;
[twinu, twind] = proc_twin(nbar, sll, Ns);

% Null feed through from this position
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);

% OS-CFAR
guard = 2*n_fft/Ns;
guard = floor(guard/2)*2;% make even
train = round(20*n_fft/Ns);
train = floor(train/2)*2;
rank = train;
Pfa = 15e-3;
OS = proc_oscfar(train, guard, rank, Pfa);

% Positive half frequency axis
f_pos = proc_faxis(n_fft);

% bin method
nbins = 16;
bin_width = (n_fft/2)/nbins;

% Data processing
t_safe = 3; % safe TOA fo target
fd_max = 3e3; % targets travelling faster are ignored


