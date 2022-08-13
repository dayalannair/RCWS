%% Process FMCW triangle sweep
% Dayalan Nair
% University of Cape Town
% July 2022

% Description

% Signal processing
% This script reads in I and Q data of an up and down FMCW sweep and
% performs Taylor windowing, FFT, and Ordered Statistic CFAR on the data.
% It calculates range and radial velocity of all targets in a set of 16
% range bins based on an input of 200 samples per I and Q per chirp/ramp.

% Data processing
% Only targets with a positive velocity are processed. The module outputs
% whether a turn is safe or not based on the target's time of arrival, max
% expected speed and host vehicle turn + acceleration time.

% Convert format
i_data = double(cell2mat(i_data));
q_data = double(cell2mat(q_data));

%     i_data = str2double(i_data);
%     q_data = str2double(q_data);
%     disp(i_data)
% Extract and combine IQ - square law detector
iq_u = i_data(1:200).^2 + q_data(1:200).^2;
iq_d = i_data(201:400).^2 + q_data(201:400).^2;
%     disp(iq_d)
% Taylor Window 
iq_u = iq_u.*twinu.';
iq_d = iq_d.*twind.';

% FFT    
IQ_UP = fft(iq_u,n_fft);
IQ_DN = fft(iq_d,n_fft);

% Halve FFTs
IQ_UP = IQ_UP(1:n_fft/2);
IQ_DN = IQ_DN(n_fft/2+1:end);

%     disp(IQ_DN)
% Null feedthrough
IQ_UP(1:num_nul) = 0;
IQ_DN(end-num_nul+1:end) = 0;

% flip
IQ_DN = flip(IQ_DN,2);

% Filter peaks/ peak detection
up_os = OS(abs(IQ_UP)', double(1:n_fft/2));
dn_os = OS(abs(IQ_DN)', double(1:n_fft/2));

% Find peak magnitude
os_pku = abs(IQ_UP).*up_os';
os_pkd = abs(IQ_DN).*dn_os';

% Set as fd_max = 3 kHz externally
%     v_max = 60/3.6; 
%     fd_max = speed2dop(v_max, lambda)*2;

% Divide into range bins of width 64
fbu = zeros(1, nbins);
fbd = zeros(1, nbins);

rg_array = zeros(1, nbins);
fd_array = zeros(1, nbins);
sp_array = zeros(1, nbins);
   
for bin = 0:(nbins-1)
    % extract bin
    bin_slice_u = os_pku(bin*bin_width+1:(bin+1)*bin_width);
    bin_slice_d = os_pkd(bin*bin_width+1:(bin+1)*bin_width);
    
    % find local maximum in bin
    [magu, idx_u] = max(bin_slice_u);
    [magd, idx_d] = max(bin_slice_d);
    
    % If there is a non zero maximum/detection
    if magu ~= 0
        fbu(bin+1) = f_pos(bin*bin_width + idx_u);
    end

    if magd ~= 0
        fbd(bin+1) = f_pos(bin*bin_width + idx_d);
    end

    % ensure both not DC
    if and(fbu(bin+1) ~= 0, fbd(bin+1)~= 0)
        fd = -fbu(bin+1) + fbd(bin+1);
        fd_array(bin+1) = fd/2;
        
        % if less than max expected and filter clutter doppler
        if ((abs(fd/2) < fd_max) && (fd/2 > 400))
            sp_array(bin+1) = dop2speed(fd/2,lambda)/2;
            rg_array(bin+1) = beat2range( ...
                [fbu(bin+1) -fbd(bin+1)], k, c);
        end
    end
end

% Once all bins processed, find unsafe targets
% TOA = Time of Arrival
TOA = rg_array./sp_array;
% if any unsafe. Faster than min as it stops once found
if (any(TOA<t_safe))
   % return a scaled value of safety. Min is most unsafe.
%    safety = min(TOA);
   % OPTIONAL: RETURN SPEED AND RANGE OF DANGEROUS TARG
   [safety, idx] = min(TOA);
   targ_rng = rg_array(idx);
   targ_vel = sp_array(idx);
else
   % else if safe, return number higher than t_safe
   safety =  10;
end