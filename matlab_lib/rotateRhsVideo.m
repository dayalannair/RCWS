%% FOR ROTATING RHS VID
addpath('rhsUpsideDown\')
directory_path = ['C:\Users\naird\OneDrive - University of Cape Town' ...
    '\RCWS_DATA\road_data_03_03_2023\iq_vid\rhsUpsideDown\'];
avi_files = dir(fullfile(directory_path, '*.avi'));
for i = 1:length(avi_files)
    vidName = avi_files(i).name;
    % vidName = 'rhs_vid_.avi';
    V = VideoReader(vidName); 
    
    vd = read(V);
    v2flip = rot90(vd, 2);
    V_flip = VideoWriter(strcat(....
        ['C:\Users\naird\OneDrive - ' ...
        'University of Cape Town\RCWS_DATA\' ...
        'road_data_03_03_2023\iq_vid\'], ...
        vidName),'Uncompressed AVI'); 
    open(V_flip)
    writeVideo(V_flip, v2flip)
    close(V_flip)
end