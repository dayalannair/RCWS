%% Scenario
% two cars passing by, RHS radar side
% CASE 4: Target overtake
car1_x_dist = 0;
car1_y_dist = 400;
car1_speed = -60/3.6;
car2_x_dist = 60;
car2_y_dist = 2;
car2_speed = 50/3.6;

car1_dist = sqrt(car1_x_dist^2 + car1_y_dist^2);
car2_dist = sqrt(car2_x_dist^2 + car2_y_dist^2);

car1_rcs = db2pow(min(10*log10(car1_dist)+5,20));
car2_rcs = db2pow(min(10*log10(car2_dist)+5,20));

% Define reflected signal
cartarget = phased.RadarTarget('MeanRCS',[car1_rcs car2_rcs], ...
    'PropagationSpeed',c,'OperatingFrequency',fc);

% Define target motion - 2 targets
carmotion = phased.Platform('InitialPosition',[car1_x_dist car2_x_dist; ...
    car1_y_dist car2_y_dist;0.5 0.5],...
    'Velocity',[-car1_speed -car2_speed;0 0;0 0]);

% Define propagation medium
channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs_wav,'TwoWayPropagation',true);

% Define radar motion
radar_speed = 0;
radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);
