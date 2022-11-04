function [rgMtx, spMtx, spMtxCorr, pkuClean, ...
    pkdClean, fbu, fbd, fdMtx] = proc_sweep(bin_width, fd_max, ...
    lambda, k, c, dnDets, upDets)

    fbu = zeros(1,nbins);
    fbd = zeros(1,nbins);
    rgMtx = zeros(1,nbins);
    fdMtx = zeros(1,nbins);
    spMtx = zeros(1,nbins);
    spMtxCorr = zeros(1,nbins);
    % beat_arr = zeros(1,nbins);
    pkuClean = zeros(1,n_fft/2);
    pkdClean = zeros(1,n_fft/2);
    
    for bin = 0:(nbins-1)
        % find beat in down chirp bin
        bin_slice_d = dnDets(bin*bin_width+1:(bin+1)*bin_width);
        [magd, idx_d] = max(bin_slice_d);
        
        beat_index = bin*bin_width + idx_d;
        if magd ~= 0
            fbd(bin+1) = f_pos(beat_index);
            % set up bin slice to range of expected beats
            % See freqs from 0 to index 15 - determined from 60kmh (VERIFY)
            % check if far enough from center
            if (beat_index>bin_width)
                bin_slice_u = upDets(beat_index - 15:beat_index);
            % if not, start from center
            else
                bin_slice_u = upDets(1:beat_index);
            end
            % index is index in the subset
            [magu, idx_u] = max(bin_slice_u);
            if magu ~= 0
                fbu(bin+1) = f_pos(beat_index - 15 + idx_u);
            end
            
            % if both not DC
            if and(fbu(bin+1) ~= 0, fbd(bin+1)~= 0)
                fd = -fbu(bin+1) + fbd(bin+1);
                fdMtx(bin+1) = fd/2;
                
                % if less than max expected and filter clutter doppler
                if ((abs(fd/2) < fd_max) && (fd/2 > 400))
                    spMtx(bin+1) = dop2speed(fd/2,lambda)/2;
                    rgMtx(bin+1) = beat2range( ...
                        [fbu(bin+1) -fbd(bin+1)], k, c);
        
                    % Angle correction
                   
                    % Theta in radians
                    theta = asin(road_width/rgMtx(bin+1))*...
                        correction_factor;
        
        %                     real_v = dop2speed(fd/2,lambda)/(2*cos(theta));
                    real_v = fd*lambda/(4*cos(theta));
                    spMtxCorr(bin+1) = round(real_v,2);
                end
            end
            % for plot
            pkuClean( bin*bin_width + idx_u) = magu;
            pkdClean( bin*bin_width + idx_d) = magd;
        
        end
    end