% 
% 
% x = data(3).ObjectDetections(2);
% r = x(1)
% r = x{1}.Measurement(5)

%%
% data = singleCarLeftToRight;
measuredPosition = zeros(44,1);
measuredVelocity = zeros(44,1);
actualPosition = zeros(44,1);
actualVelocity = zeros(44,1);
N = length(data);
t   = zeros(N,1);
for i = 1:N
    t(i) = data(i).Time;
    measuredVelocity(i) = data(i).ObjectDetections{1}.Measurement(5);
    measuredPosition(i) = data(i).ObjectDetections{1}.Measurement(2);
    actualVelocity(i)   = data(i).ActorPoses(2).Velocity(2);
    actualPosition(i)   = data(i).ActorPoses(2).Position(2);
end


close all
figure
tiledlayout(2, 1)
nexttile
plot(t, measuredVelocity)
hold on
plot(t, actualVelocity)
% axis([0 max(t) -25 -10])
nexttile
plot(t, measuredPosition)
hold on
plot(t, actualPosition)
