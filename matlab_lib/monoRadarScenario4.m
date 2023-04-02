%% Scenario
% two cars passing by, LHS radar side
% two extra cars going right to left
% CASE 4: Target overtake

% These parameters were adjusted to morph the 3 target scenario as needed
car1_x_dist = -60;
car1_y_dist = 3.3;
car1_speed = 45/3.6;

car2_x_dist = -40;
car2_y_dist = 3.3;
car2_speed = 60/3.6;

car3_x_dist = 60;
car3_y_dist = 1.1;
car3_speed = -70/3.6;

car4_x_dist = 30;
car4_y_dist = 1.1;
car4_speed = -30/3.6;

car1_dist = sqrt(car1_x_dist^2 + car1_y_dist^2);
car2_dist = sqrt(car2_x_dist^2 + car2_y_dist^2);
car3_dist = sqrt(car3_x_dist^2 + car3_y_dist^2);
car4_dist = sqrt(car4_x_dist^2 + car4_y_dist^2);

% Since the antenna is not simulated, the RCS of the outer-lane
% target is manually reduced
car1_rcs = db2pow(min(10*log10(car1_dist)+5,20));
car2_rcs = db2pow(min(10*log10(car2_dist)+5,20))+5;
car3_rcs = db2pow(min(10*log10(car3_dist)+5,20))+5;
car4_rcs = db2pow(min(10*log10(car4_dist)+5,20))+5;

% Define reflected signal
cartarget = phased.RadarTarget('MeanRCS', ...
    [car1_rcs car2_rcs car3_rcs car4_rcs], ...
    'PropagationSpeed',c,'OperatingFrequency',fc, 'Model','Swerling1');

% Define target motion - 2 targets
carmotion = phased.Platform('InitialPosition', ...
    [car1_x_dist car2_x_dist car3_x_dist car4_x_dist; ...
    car1_y_dist car2_y_dist car3_y_dist car4_y_dist;0.5 0.5 0.5 0.5],...
    'Velocity', ...
    [car1_speed car2_speed car3_speed car4_speed;0 0 0 0;0 0 0 0]);

% Define propagation medium
channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs_wav,'TwoWayPropagation',true);

% Define radar motion
radar_speed = 0;
radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);
