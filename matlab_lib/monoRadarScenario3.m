%% Scenario
% two cars one after the other, LHS
% CASE 4: Target overtake
car1_x_dist = -60;
car1_y_dist = 4;
car1_speed = 80/3.6;
car2_x_dist = -30;
car2_y_dist = 4;
car2_speed = 30/3.6;

car1_dist = sqrt(car1_x_dist^2 + car1_y_dist^2);
car2_dist = sqrt(car2_x_dist^2 + car2_y_dist^2);

car1_rcs = db2pow(min(10*log10(car1_dist),20));
car2_rcs = db2pow(min(10*log10(car2_dist),20));

% Define reflected signal
cartarget = phased.RadarTarget('MeanRCS',[car1_rcs car2_rcs], ...
    'PropagationSpeed',c,'OperatingFrequency',fc, 'Model', 'Swerling1');

% Define target motion - 2 targets
carmotion = phased.Platform('MotionModel', 'Acceleration', ...
    'InitialPosition',[car1_x_dist car2_x_dist; ...
    car1_y_dist car2_y_dist;0.5 0.5],...
    'InitialVelocity',[car1_speed car2_speed;0 0;0 0], ...
    'Acceleration',[-4.5 0; 0 0; 0 0]);

% Define propagation medium
channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs_wav,'TwoWayPropagation',true);

% Define radar motion
radar_speed = 0;
radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);
