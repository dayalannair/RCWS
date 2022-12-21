% 
% 
% x = data(3).ObjectDetections(2);
% r = x(1)
% r = x{1}.Measurement(5)

%%
% data = singleCarLeftToRight;
N = length(data);

measuredPosition1 = zeros(N,1);
measuredVelocity1 = zeros(N,1);
measuredPosition2 = zeros(N,1);
measuredVelocity2 = zeros(N,1);

actualPosition1 = zeros(N,1);
actualPosition2 = zeros(N,1);
actualVelocity1 = zeros(N,1);
actualVelocity2 = zeros(N,1);

t   = zeros(N,1);
for i = 1:N
    t(i) = data(i).Time;
    measuredVelocity1(i) = data(i).ObjectDetections{1}.Measurement(5);
    measuredPosition1(i) = data(i).ObjectDetections{1}.Measurement(2);
    measuredVelocity2(i) = data(i).ObjectDetections{2}.Measurement(5);
    measuredPosition2(i) = data(i).ObjectDetections{2}.Measurement(2);
    actualVelocity1(i)   = data(i).ActorPoses(2).Velocity(2);
    actualVelocity2(i)   = data(i).ActorPoses(3).Velocity(2);
    actualPosition1(i)   = data(i).ActorPoses(2).Position(2);
    actualPosition2(i)   = data(i).ActorPoses(3).Position(2);
end


close all
figure
tiledlayout(2, 1)
nexttile
scatter(t, measuredVelocity1)
hold on
plot(t, actualVelocity1)
scatter(t, measuredVelocity2)
plot(t, actualVelocity2)
% axis([0 max(t) -25 -10])
nexttile
scatter(t, measuredPosition1)
hold on
plot(t, actualPosition1)
scatter(t, measuredPosition2)
hold on
plot(t, actualPosition2)
