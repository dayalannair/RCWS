% 
% 
x =data(3).ObjectDetections;
% r = x(1)
% r = x{1}.Measurement(5)

%%
% data = singleCarLeftToRight;
N = length(data);

measuredPosition1 = NaN(N,15);
measuredVelocity1 = NaN(N,15);
measuredPosition2 = NaN(N,15);
measuredVelocity2 = NaN(N,15);

actualPosition1 = NaN(N,15);
actualPosition2 = NaN(N,15);
actualVelocity1 = NaN(N,15);
actualVelocity2 = NaN(N,15);

t   = NaN(N,1);
for i = 1:N
    t(i) = data(i).Time;
    detectionsRadar1 = data(i).ObjectDetections;
    for j = 1:length(detectionsRadar1)
        % Stack detections from radar 1 - RHS
        if detectionsRadar1{j}.SensorIndex == 1
            measuredVelocity1(i,j) = detectionsRadar1{j}.Measurement(5);
            measuredPosition1(i,j) = detectionsRadar1{j}.Measurement(2);
        % Stack detections from radar 2 - LHS
        else
            measuredVelocity2(i,j) = detectionsRadar1{j}.Measurement(5);
            measuredPosition2(i,j) = detectionsRadar1{j}.Measurement(2);
        end
    end
%     measuredVelocity1(i) = data(i).ObjectDetections{1}.Measurement(5);
%     measuredPosition1(i) = data(i).ObjectDetections{1}.Measurement(2);
%     measuredVelocity2(i) = data(i).ObjectDetections{2}.Measurement(5);
%     measuredPosition2(i) = data(i).ObjectDetections{2}.Measurement(2);


%     actualVelocity1(i)   = data(i).ActorPoses(2).Velocity(2);
%     actualVelocity2(i)   = data(i).ActorPoses(3).Velocity(2);
%     actualPosition1(i)   = data(i).ActorPoses(2).Position(2);
%     actualPosition2(i)   = data(i).ActorPoses(3).Position(2);

    av1   = data(i).ActorPoses(2).Velocity(2);
    av2   = data(i).ActorPoses(3).Velocity(2);
    ap1   = data(i).ActorPoses(2).Position(2);
    ap2   = data(i).ActorPoses(3).Position(2);
    
    % Ensures tracks are correct for each target plot
    % If RHS range is negative, proceed as normal
    % If RHS range is positive, target is has crossed over to other radar
    if ap1 < 0
        actualVelocity1(i)   = data(i).ActorPoses(2).Velocity(2);
        actualVelocity2(i)   = data(i).ActorPoses(3).Velocity(2);
        actualPosition1(i)   = data(i).ActorPoses(2).Position(2);
        actualPosition2(i)   = data(i).ActorPoses(3).Position(2);
    else
        actualVelocity2(i)   = data(i).ActorPoses(2).Velocity(2);
        actualVelocity1(i)   = data(i).ActorPoses(3).Velocity(2);
        actualPosition2(i)   = data(i).ActorPoses(2).Position(2);
        actualPosition1(i)   = data(i).ActorPoses(3).Position(2);

    end

    
end

%% Plots
close all
fig = figure('WindowState','maximized');
tiledlayout(2, 2)
nexttile
hold on
scatter(t, abs(measuredVelocity2)*3.6, 'Marker','.')
plot(t, abs(actualVelocity2)*3.6)
title("LHS Velocity Measurements")
xlabel("Time (s)")
ylabel("Speed (km/h)")

nexttile
hold on
scatter(t, abs(measuredVelocity1)*3.6, 'Marker','.')
plot(t, abs(actualVelocity1)*3.6)
title("RHS Velocity Measurements")
xlabel("Time (s)")
ylabel("Speed (km/h)")
% axis([0 max(t) -25 -10])
nexttile
hold on
scatter(t, abs(measuredPosition2), 'Marker','.')
plot(t, abs(actualPosition2))
title("LHS Range Measurements")
xlabel("Time (s)")
ylabel("Range (m)")

nexttile
hold on
scatter(t, abs(measuredPosition1), 'Marker','.')
plot(t, abs(actualPosition1))
title("RHS Range Measurements")
xlabel("Time (s)")
ylabel("Range (m)")
