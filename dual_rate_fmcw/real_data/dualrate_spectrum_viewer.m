addpath('../../library/');
addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/m3_dual_11_07_2022/');
% iq_tbl=readtable('IQ_dual_240_200_06-24-54.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ_dual_240_200_06-25-41.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ_dual_240_200_06-27-17.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ_dual_240_200_06-27-33.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ_dual_240_100_06-30-46.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ_dual_240_200_06-34-00_GOOD.txt','Delimiter' ,' ');
iq_tbl=readtable('IQ_dual_240_200_06-34-59.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ_dual_240_200_06-27-17.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ_dual_240_200_06-27-33.txt','Delimiter' ,' ');
%iq_tbl=readtable('IQ_dual_240_100_06-30-46.txt','Delimiter' ,' ');

subset = 1:1024;
Ns = 200;
i_up1 = table2array(iq_tbl(subset,1:Ns));
i_dn1 = table2array(iq_tbl(subset,Ns+1:2*Ns));
q_up1 = table2array(iq_tbl(subset,2*Ns+1:3*Ns));
q_dn1 = table2array(iq_tbl(subset,3*Ns+1:4*Ns));

i_up2 = table2array(iq_tbl(subset, 4*Ns+1:4.75*Ns));
i_dn2 = table2array(iq_tbl(subset, 4.75*Ns+1:5.5*Ns));
q_up2 = table2array(iq_tbl(subset, 5.5*Ns+1:6.25*Ns));
q_dn2 = table2array(iq_tbl(subset, 6.25*Ns+1:7*Ns));

iq_up1 = i_up1 + 1i*q_up1;
iq_dn1 = i_dn1 + 1i*q_dn1;

iq_up2 = i_up2 + 1i*q_up2;
iq_dn2 = i_dn2 + 1i*q_dn2;

%% CA-CFAR + Gaussian Window
% Gaussian Window
% remember to increase fft point size
% n_sweeps = size(i_up,1);
gwinu1 = gausswin(200);
gwinu2 = gausswin(150);
gwind1 = gausswin(200);
gwind2 = gausswin(150);

iq_up1 = gwinu1.'.*iq_up1;
iq_dn1 = gwind1.'.*iq_dn1;
iq_up2 = gwinu2.'.*iq_up2;
iq_dn2 = gwind2.'.*iq_dn2;

% FFT
n_sweeps = length(subset);
n_fft1 = 200;%512;
n_fft2 = 150;
% iq_dn2 = padarray(iq_dn2,[0 (n_fft1-n_fft2)], 'post');
% iq_up2 = padarray(iq_up2,[0 (n_fft1-n_fft2)], 'post');
% n_fft2 = n_fft1;

% FFT
IQ_UP1 = fft(iq_up1,n_fft1,2);
IQ_DN1 = fft(iq_dn1,n_fft1,2);

IQ_UP2 = fft(iq_up2,n_fft2,2);
IQ_DN2 = fft(iq_dn2,n_fft2,2);

% Halve FFTs
IQ_UP1 = IQ_UP1(:, 1:n_fft1/2);
IQ_UP2 = IQ_UP2(:, 1:n_fft2/2);

IQ_DN1 = IQ_DN1(:, n_fft1/2+1:end);
IQ_DN2 = IQ_DN2(:, n_fft2/2+1:end);

% Null DC
null_width = 4;
IQ_UP1(:, 1:null_width) = 0;%IQ_UP1(:, 1:4);
IQ_UP2(:, 1:null_width) = 0;%IQ_UP1(:, 1:4);

IQ_DN1(:, end-null_width:end) = 0;%IQ_UP1(:, 1:4);
IQ_DN2(:, end-null_width:end) = 0;%IQ_UP1(:, 1:4);

close all
fig1 = figure;
movegui(fig1,'east')
for i = 1:n_sweeps
    tiledlayout(2,2)
%     nexttile
%     plot(absmagdb(IQ_DN1(i,:)))
%     title("Triangle 1 down chirp beat")
%     nexttile
%     plot(absmagdb(IQ_UP1(i,:)))
%     title("Triangle 1 up chirp beat")
%     nexttile
%     plot(absmagdb(IQ_DN2(i,:)))
%     title("Triangle 2 down chirp beat")
%     nexttile
%     plot(absmagdb(IQ_UP2(i,:)))
%     title("Triangle 2 up chirp beat")
    nexttile
    plot(abs(IQ_DN1(i,:)))
    title("Triangle 1 down chirp beat")
    nexttile
    plot(abs(IQ_UP1(i,:)))
    title("Triangle 1 up chirp beat")
    nexttile
    plot(abs(IQ_DN2(i,:)))
    title("Triangle 2 down chirp beat")
    nexttile
    plot(abs(IQ_UP2(i,:)))
    title("Triangle 2 up chirp beat")
    pause(0.001)
end

