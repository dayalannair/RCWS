ipAddr = '192.168.0.106';
username = 'pi';
passwd = 'raspberry';

rpi = raspi(ipAddr,username,passwd)
cam = cameraboard(rpi,'Resolution','640x480');
%%
% Initialise uRAD here

% loop for n sweeps
for i = 1:100
    % Request uRAD data
    % Plot uRAD data

    % Request and plot/display camera data
    img = snapshot(cam);
    image(img);
    drawnow;
end

% NB:
%The record command starts video recording. It does not block the MATLAB 
% command prompt. You can perform MATLAB operations while video 
% recording is in progress. However, you cannot take snapshots from the 
% camera. To check if the recording is complete, use the Recording
% property of the cameraboard object.


% openShell(rpi)
%%

% system(rpi, 'ls -l')
system(rpi,'ping raspberrypi')
% system(rpi, 'git clone https://github.com/dayalannair/RCWS')
% system(rpi, 'git remote set-url --push origin https://github.com/dayalannair/RCWS')