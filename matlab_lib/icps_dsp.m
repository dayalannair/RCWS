function [ranges, speeds, toas, fft_up, fft_down] = icps_dsp(cfar_obj, ...
    iq_u, iq_d, win, n_fft, f_pos, fd_clut, n_bins, scan_width)

bin_width = (n_fft/2)/n_bins;
% Apply window
iq_u = iq_u.*win.';
iq_d = iq_d.*win.';

% FFT 
IQ_UP = fft(iq_u,n_fft, 2);
IQ_DN = fft(iq_d,n_fft, 2);

% Use to set fft output to full spectrum
% fft_up = IQ_UP;
% fft_down = IQ_DN;

% Halve FFTs
IQ_UP = IQ_UP(:, 1:n_fft/2);
IQ_DN = IQ_DN(:, n_fft/2+1:end);

% Null tx feedthrough
nul_width_factor = 0.04;
num_nul = round((n_fft/2)*nul_width_factor);
IQ_UP(:, 1:num_nul) = 0;
IQ_DN(:, end-num_nul+1:end) = 0;

% flip down spectrum
IQ_DN = flip(IQ_DN,2);

% Filter peaks/ peak detection
up_os = cfar_obj(abs(IQ_UP)', 1:n_fft/2);
dn_os = cfar_obj(abs(IQ_DN)', 1:n_fft/2);

% Find peak magnitude
os_pku = abs(IQ_UP).*up_os';
os_pkd = abs(IQ_DN).*dn_os';

% Pre-allocate memory
ranges = zeros(1, n_bins);
speeds = zeros(1, n_bins);
toas   = zeros(1, n_bins);

fft_up = IQ_UP;
fft_down = IQ_DN;

for bin = 0:(n_bins-1)
        
    % find beat frequency in bin of down chirp
    bin_slice_d = os_pkd(bin*bin_width+1:(bin+1)*bin_width);
    
    % extract peak of beat frequency
    [magd, idx_d] = max(bin_slice_d);
    
    % if there is a non-zero maximum in down chirp bin
    % NOTE: Detection in down chirp gates rest of the processing
    if magd ~= 0

        % index of beat frequency is the index in the bin plus
        % the index of the start of the bin
        beat_index = bin*bin_width + idx_d;

        % store beat frequency
        fbd = f_pos(beat_index);
       
        % if the beat index is further than one bin from the start
        if (beat_index>bin_width)
           
            % set beat scan window width
            index_end = beat_index - scan_width;

            % get up chirp spectrum window
            bin_slice_u = os_pku(index_end:beat_index);
        
        % if not, start from DC
        else
            index_end = 1;
            bin_slice_u = os_pku(1:beat_index);
        end
        
        % Obtain index and magnitude of the peak in the up chirp bin
        [magu, idx_u] = max(bin_slice_u);
        
        % If there was a peak in the up chirp bin
        % NOTE: This gates the rest of operations from this point
        if magu ~= 0 && (idx_u ~= idx_d) 
            fbu = f_pos(index_end + idx_u - 1);

             % if both not DC
            if and(fbu ~= 0, fbd ~= 0)
                % Doppler shift is twice the difference in beat frequency
                fd = (-fbu + fbd)/2;
                
                % Can add angle correction
                if ( fd/2 > fd_clut)
                    speeds(bin+1) = fd*lambda/2;
                    ranges(bin+1) = beat2range([fbu -fbd], k, c);
                end
            end
        end
    end
end

end