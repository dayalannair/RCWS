function [iq, fft_frames, iq_frames, n_frames] = import_frames(n_sweeps_per_frame)
    % path relative to folder that function is called in
    addpath('../../../../OneDrive - University of Cape Town/RCWS_DATA/');
    iq_tbl=readtable('IQ_sawtooth2048_bkyrd_fast.txt', 'Delimiter' ,' ');
    i_dat = table2array(iq_tbl(:,1:200));
    q_dat = table2array(iq_tbl(:,201:400));
    iq = i_dat + 1i*q_dat;
    
    n_samples = size(iq,2);
    n_sweeps = size(iq,1);
    n_frames = round(n_sweeps/n_sweeps_per_frame);

    fft_frames = zeros(n_samples, n_sweeps_per_frame, n_frames);
    iq_frames = zeros(n_samples, n_sweeps_per_frame, n_frames);
    for i = 1:n_frames
        p1 = (i-1)*n_sweeps_per_frame + 1;
        p2 = i*n_sweeps_per_frame;
        fft_frames(:,:,i) = fft2(iq(p1:p2, :).');
        iq_frames(:,:,i) = iq(p1:p2, :).';
    end
end