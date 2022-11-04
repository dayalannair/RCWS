function [rgMtx, spMtx, spMtxCorr, pkuClean, ...
    pkdClean, fbu, fbd, fdMtx, beat_index] = proc_sweep(bin_width, ... 
    lambda, k, c, dnDets, upDets, nbins, n_fft, f_pos, scan_width, ...
    calib, road_width)

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
        
        % find beat frequency in bin of down chirp
        bin_slice_d = dnDets(bin*bin_width+1:(bin+1)*bin_width);
        
        % extract peak of beat frequency
        [magd, idx_d] = max(bin_slice_d);
        
        % if there is a non-zero maximum
        if magd ~= 0
            
            % index of beat frequency is the index in the bin plus
            % the index of the start of the bin
            beat_index = bin*bin_width + idx_d;

            % store beat frequency
            fbd(bin+1) = f_pos(beat_index);
           
            % if the beat index is further than one bin from the start
           if (beat_index>bin_width)
               
               % set beat scan window width
               index_end = beat_index - scan_width;

               % get up chirp spectrum window
               bin_slice_u = upDets(index_end:beat_index);
            
           % if not, start from DC
           else
                index_end = 1;
                bin_slice_u = upDets(1:beat_index);
            end
            
            [magu, idx_u] = max(bin_slice_u);
            
            if magu ~= 0
                
                % store up chirp beat frequency
                % NB - the bin index is not necessarily where the beat was
                % found!
                % ISSUE FIXED: index starts from index_end not bin*
                % bin_width
                fbu(bin+1) = f_pos(index_end + idx_u);
            end
            
            % if both not DC
            if and(fbu(bin+1) ~= 0, fbd(bin+1)~= 0)
                % Doppler shift is twice the difference in beat frequency
%               calibrate beats for doppler shift
                fd = (-fbu(bin+1) + fbd(bin+1))*calib;
                fdMtx(bin+1) = fd/2;
                
                
                % if less than max expected and filter clutter doppler
                % removed the max condition as this is controlled by bin
                % width (abs(fd/2) < fd_max) &&
                if ( fd/2 > 400)
                    spMtx(bin+1) = dop2speed(fd/2,lambda)/2;
                    
                    rgMtx(bin+1) = calib*beat2range( ...
                        [fbu(bin+1) -fbd(bin+1)], k, c);

                    % Theta in radians
                    theta = asin(road_width/rgMtx(bin+1));

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