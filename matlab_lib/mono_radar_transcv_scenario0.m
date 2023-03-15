%% Scenario

% Target parameters

% CASE 1: Static target at 50m
% car1_x_dist = 50;
% car1_y_dist = 2;
% car1_speed = 0/3.6;
% car2_x_dist = 50;
% car2_y_dist = -1000;
% car2_speed = 0/3.6;

% CASE 2: Static targets at 50 and 51m
% Test range resolution
% car1_x_dist = 50;
% car1_y_dist = 2;
% car1_speed = 0/3.6;
% car2_x_dist = 51;
% car2_y_dist = 2;
% car2_speed = 0/3.6;

% CASE 3: Static targets at 50m separated by 2m
% Test cross range resolution
% car1_x_dist = 50;
% car1_y_dist = 10;
% car1_speed = 0/3.6;
% car2_x_dist = 50;
% car2_y_dist = -10;
% car2_speed = 0/3.6;

% CASE 4: Target overtake
% car1_x_dist = 60;
% car1_y_dist = 2;
% car1_speed = 20/3.6;
% car2_x_dist = 30;
% car2_y_dist = 2;
% car2_speed = 60/3.6;

car1_x_dist = 40;
car1_y_dist = -2;
car1_speed = 0;


% Target positions
car1_dist = sqrt(car1_x_dist^2 + car1_y_dist^2);

% Target RCS
car1_rcs = db2pow(min(10*log10(car1_dist)+5,20))*10000;

% RCS Signature
car1_rcs_signat = rcsSignature("Pattern", ...
    [car1_rcs, car1_rcs; car1_rcs, car1_rcs], ...
    "Azimuth", [-30 30], 'Elevation', [-30 30], ...
    'Frequency', [fc (fc+bw)], 'FluctuationModel', 'Swerling1');


carmotion = phased.Platform( ...
    'InitialPosition', [car1_x_dist; car1_y_dist ;0.5],...
    'Velocity',[-car1_speed;0;0]);

% Targets on the y-axis
% carmotion = phased.Platform('InitialPosition',[car1_x_dist car2_x_dist; ...
%     car1_y_dist car2_y_dist;0.5 0.5],...
%     'Velocity',[0 0;-car1_speed -car2_speed;0 0]);

% Define propagation medium
channel = phased.FreeSpace( ...
    'PropagationSpeed',c,...
    'OperatingFrequency',fc, ...
    'SampleRate',fs_wav, ...
    'TwoWayPropagation',true);

% Define radar motion
% Not needed for transceiver simulation
% radar_speed = 0;
% radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
%     'Velocity',[radar_speed;0;0]);