function [allData, scenario, sensors] = threeCarLeftAndRight()
%threeCarLeftAndRight - Returns sensor detections
%    allData = threeCarLeftAndRight returns sensor detections in a structure
%    with time for an internally defined scenario and sensor suite.
%
%    [allData, scenario, sensors] = threeCarLeftAndRight optionally returns
%    the drivingScenario and detection generator objects.

% Generated by MATLAB(R) 9.12 (R2022a) and Automated Driving Toolbox 3.5 (R2022a).
% Generated on: 22-Dec-2022 07:17:16

% Create the drivingScenario object and ego car
[scenario, egoVehicle] = createDrivingScenario;

% Create all the sensors
[sensors, numSensors] = createSensors(scenario);

allData = struct('Time', {}, 'ActorPoses', {}, 'ObjectDetections', {}, 'LaneDetections', {}, 'PointClouds', {}, 'INSMeasurements', {});
running = true;
while running

    % Generate the target poses of all actors relative to the ego vehicle
    poses = targetPoses(egoVehicle);
    time  = scenario.SimulationTime;

    objectDetections = {};
    laneDetections   = [];
    ptClouds = {};
    insMeas = {};
    isValidTime = false(1, numSensors);

    % Generate detections for each sensor
    for sensorIndex = 1:numSensors
        sensor = sensors{sensorIndex};
        [objectDets, isValidTime(sensorIndex)] = sensor(poses, time);
        numObjects = length(objectDets);
        objectDetections = [objectDetections; objectDets(1:numObjects)]; %#ok<AGROW>
    end

    % Aggregate all detections into a structure for later use
    if any(isValidTime)
        allData(end + 1) = struct( ...
            'Time',       scenario.SimulationTime, ...
            'ActorPoses', actorPoses(scenario), ...
            'ObjectDetections', {objectDetections}, ...
            'LaneDetections', {laneDetections}, ...
            'PointClouds',   {ptClouds}, ... %#ok<AGROW>
            'INSMeasurements',   {insMeas}); %#ok<AGROW>
    end

    % Advance the scenario one time step and exit the loop if the scenario is complete
    running = advance(scenario);
end

% Restart the driving scenario to return the actors to their initial positions.
restart(scenario);

% Release all the sensor objects so they can be used again.
for sensorIndex = 1:numSensors
    release(sensors{sensorIndex});
end

%%%%%%%%%%%%%%%%%%%%
% Helper functions %
%%%%%%%%%%%%%%%%%%%%

% Units used in createSensors and createDrivingScenario
% Distance/Position - meters
% Speed             - meters/second
% Angles            - degrees
% RCS Pattern       - dBsm

function [sensors, numSensors] = createSensors(scenario)
% createSensors Returns all sensor objects to generate detections

% Assign into each sensor the physical and radar profiles for all actors
profiles = actorProfiles(scenario);
fc = 24.005e9;
bw = 240e6;

sensors{1} = drivingRadarDataGenerator('SensorIndex', 1, ...
    'MountingLocation', [3.7 -0.9 0.2], ...
    'MountingAngles', [-75 0 0], ...
    'RangeLimits', [0 62.5], ...
    'TargetReportFormat', 'Detections', ...
    'RangeRateResolution', 3, ...
    'RangeRateLimits', [-100 75], ...
    'RangeResolution', 1.5, ...
    'FieldOfView', [30 30], ...
    'Profiles', profiles, ...
    'CenterFrequency', fc, ...
    'Bandwidth', bw);
sensors{2} = drivingRadarDataGenerator('SensorIndex', 2, ...
    'MountingLocation', [3.7 0.9 0.2], ...
    'MountingAngles', [75 0 0], ...
    'RangeLimits', [0 62.5], ...
    'TargetReportFormat', 'Detections', ...
    'RangeRateLimits', [-75 75], ...
    'FieldOfView', [30 30], ...
    'Profiles', profiles, ...
    'CenterFrequency', fc, ...
    'Bandwidth', bw);
numSensors = 2;

function [scenario, egoVehicle] = createDrivingScenario
% createDrivingScenario Returns the drivingScenario defined in the Designer

% Construct a drivingScenario object.
scenario = drivingScenario;

% Add all road segments
roadCenters = [15 0 0;
    -15 0 0];
laneSpecification = lanespec(2);
road(scenario, roadCenters, 'Lanes', laneSpecification, 'Name', 'Road');

roadCenters = [0 75 0;
    0 -75 0];
laneSpecification = lanespec(2);
road(scenario, roadCenters, 'Lanes', laneSpecification, 'Name', 'Road1');

% Add the ego vehicle
egoVehicle = vehicle(scenario, ...
    'ClassID', 1, ...
    'Position', [-8 2 0], ...
    'Mesh', driving.scenario.carMesh, ...
    'Name', 'EgoCar');

% Add the non-ego actors
actor_vehicle = vehicle(scenario, ...
    'ClassID', 1, ...
    'Position', [-2 -75 0], ...
    'Mesh', driving.scenario.carMesh, ...
    'Name', 'Vehicle');
waypoints = [-2 -75 0;
    -2 75 0];
speed = [20;20];
waittime = [0;0];
trajectory(actor_vehicle, waypoints, speed, waittime);

car = vehicle(scenario, ...
    'ClassID', 1, ...
    'Position', [2 75 0], ...
    'Mesh', driving.scenario.carMesh, ...
    'Name', 'Car');
waypoints = [2 75 0;
    2 -75 0];
speed = [22;22];
waittime = [0;0];
trajectory(car, waypoints, speed, waittime);

car1 = vehicle(scenario, ...
    'ClassID', 1, ...
    'Position', [2 -10 0], ...
    'Mesh', driving.scenario.carMesh, ...
    'Name', 'Car1');
waypoints = [2 -10 0;
    2 -75 0];
speed = [15;15];
waittime = [0;0];
trajectory(car1, waypoints, speed, waittime);

