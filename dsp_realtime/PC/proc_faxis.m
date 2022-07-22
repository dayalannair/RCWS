% Ensure function f_ax is in path or same directory
% fs fixed for uRAD at 200 kHz
function [f_neg, f_pos] = proc_faxis(n_fft)
    fs = 200e3;
    f = f_ax(n_fft, fs);
    f_neg = f(1:n_fft/2);
    f_pos = f((n_fft/2 + 1):end);
end