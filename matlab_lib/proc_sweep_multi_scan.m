% Update of proc_sweep to store scan indices in an array to show all of 
% the tracks

function [rgMtx, spMtx, spMtxCorr, pkuClean, ...
    pkdClean, fbu, fbd, fdMtx, beat_indices, beat_indices_end,...
    beat_count_out] = ...
    proc_sweep_multi_scan(bin_width, ... 
    lambda, k, c, dnDets, upDets, nbins, n_fft, f_pos, scan_width, ...
    calib, road_width, beat_count_in)
    % since these are indices, MATLAB needs ones instead of zeros
    beat_indices = ones(nbins,1);
    beat_indices_end = ones(nbins,1);
    fbu = zeros(1,nbins);
    fbd = zeros(1,nbins);
    rgMtx = zeros(1,nbins);
    fdMtx = zeros(1,nbins);
    spMtx = zeros(1,nbins);
    spMtxCorr = zeros(1,nbins);
    % beat_arr = zeros(1,nbins);
    pkuClean = zeros(1,n_fft/2);
    pkdClean = zeros(1,n_fft/2);
    beat_count_out = beat_count_in; % init counts from previous sweep
     for bin = 0:(nbins-1)
%     for bin = (nbins-1):0
        
        % find beat frequency in bin of down chirp
        bin_slice_d = dnDets(bin*bin_width+1:(bin+1)*bin_width);
        
        % extract peak of beat frequency and intra-bin index
        [magd, idx_d] = max(bin_slice_d);
        
        % if there is a non-zero maximum
        if magd ~= 0
            
            % index of beat frequency is bin index plus intra-bin index
            beat_index = bin*bin_width + idx_d;

            % store down-chirp beat frequency
            fbd(bin+1) = f_pos(beat_index);
           
            % handling edge case at the beginning of the sequence
           if (beat_index > bin_width)
               % set beat scan window width
               index_end = beat_index - scan_width;
               % get up chirp spectrum window
               bin_slice_u = upDets(index_end:beat_index);
            
           % if too close to the start edge, scan from DC to index
           else
                index_end = 1;
                bin_slice_u = upDets(1:beat_index);
           end
            
            % Get magnitude and intra-bin index of beat frequency
            [magu, idx_u] = max(bin_slice_u);
            
            % if detection is made and target not static
            if (magu ~= 0) && (idx_u ~= idx_d) 
                % Fixed targets have index up = index down
                % store up chirp beat frequency
                % NB - the bin index is not necessarily where the beat was
                % found!
                % ISSUE FIXED: index starts from index_end not bin*
                   
                % -1 because index_end is included in the slice
                fbu(bin+1) = f_pos(index_end + idx_u - 1); 


                % if both not DC and detection at the index is not static
                % clutter

                % Count clutter and filter
%                 if fbu(bin+1) ~= 0 && fbd(bin+1)~= 0 && ...
%                     beat_count_out(beat_index) < 5
                
                % If fbu < fbd, it is not 0 and the target has +ve Dopp
                if fbu(bin+1) < fbd(bin+1) 
                    % Doppler shift is twice the difference in beat 
                    % frequency
    %               calibrate beats for doppler shift
                    fd = ((-fbu(bin+1) + fbd(bin+1))*calib)/2;
                    fdMtx(bin+1) = fd;
                    
                    
                    % if less than max expected and filter clutter doppler
                    % removed the max condition as this is controlled by
                    % bin
                    % width (abs(fd/2) < fd_max) &&
                    % Doppler shift is limited by scan width
%                     if ( fd/2 > 1000)
                    % Capture data after all filters passed
                    beat_indices_end(bin+1) = index_end;
                    beat_indices(bin+1) = beat_index;
                    beat_count_out(beat_index) = ...
                        beat_count_out(beat_index) +1;
                    
                    spMtx(bin+1) = fd*lambda/2;
                    
                    rgMtx(bin+1) = calib*beat2range( ...
                        [fbu(bin+1) -fbd(bin+1)], k, c);

                    % Theta in radians
                    theta = asin(road_width/rgMtx(bin+1));

%                     real_v = dop2speed(fd/2,lambda)/(2*cos(theta));
                    real_v = fd*lambda/(2*cos(theta));
                    spMtxCorr(bin+1) = round(real_v,2);
%                     end
               
                end
                % for plot
                pkuClean( bin*bin_width + idx_u) = magu;
                pkdClean( bin*bin_width + idx_d) = magd;

            end
        end
    end