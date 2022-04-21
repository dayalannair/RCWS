%% Extract IQ data from text files
% I and Q is interleaved in raw data
I = readtable('I_trolley_test.txt','Delimiter' ,' ');
Q = readtable('Q_trolley_test.txt','Delimiter' ,' ');

I_up = table2array(I(:, 1:(end-1)/2));
I_down = table2array(I(:, (end-1)/2 + 1:end-1));

Q_up = table2array(Q(:, 1:(end-1)/2));
Q_down = table2array(Q(:, (end-1)/2 + 1:end-1));

u = I_up + 1i*Q_up;
d = I_down + 1i*Q_down;

