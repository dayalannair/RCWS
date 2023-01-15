% 
% 
x =data(3).ObjectDetections;
% r = x(1)
% r = x{1}.Measurement(5)
% data = ans;
%%
% data = singleCarLeftToRight;
N = length(data);

measuredPosition1 = NaN(N,15);
measuredVelocity1 = NaN(N,15);
measuredPosition2 = NaN(N,15);
measuredVelocity2 = NaN(N,15);

numActors = 3;
actualPosition = NaN(15, numActors);
actualVelocity = NaN(15, numActors);

actualPosition1 = NaN(15, 1);
actualPosition2 = NaN(15, 1);
actualVelocity1 = NaN(15, 1);
actualVelocity2 = NaN(15, 1);

actualPosition3 = NaN(15, 1);
actualVelocity3 = NaN(15, 1);

car1_v = NaN(N, 1);
car2_v = NaN(N, 1);

car1_r = NaN(N, 1);
car2_r = NaN(N, 1);

t   = NaN(N,1);
for i = 1:N
    t(i) = data(i).Time;
    detectionsRadar1 = data(i).ObjectDetections;
    for j = 1:length(detectionsRadar1)
        % Stack detections from radar 1 - RHS
        if detectionsRadar1{j}.SensorIndex == 1
%             measuredVelocity1(i,j) = detectionsRadar1{j}.Measurement(5);
%             measuredPosition1(i,j) = detectionsRadar1{j}.Measurement(2);
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
    
    car1_v(i) = data(i).ActorPoses(2).Velocity(2);
    car2_v(i) = data(i).ActorPoses(3).Velocity(2);
    car1_r(i) = data(i).ActorPoses(2).Position(2);
    car2_r(i) = data(i).ActorPoses(3).Position(2);
    % Ensures tracks are correct for each target plot
    % If RHS range is negative, proceed as normal
    % If RHS range is positive, target is has crossed over to other radar
%     if ap2 > 0
%         actualVelocity1(i)   = data(i).ActorPoses(2).Velocity(2);
%         actualVelocity2(i)   = data(i).ActorPoses(3).Velocity(2);
%         actualPosition1(i)   = data(i).ActorPoses(2).Position(2);
%         actualPosition2(i)   = data(i).ActorPoses(3).Position(2);
% 
% %         actualPosition(:,1)
% %         actualPosition(:,1)
% %         actualPosition(:,1)
%     else
%         actualVelocity2(i)   = data(i).ActorPoses(2).Velocity(2);
%         actualVelocity1(i)   = data(i).ActorPoses(3).Velocity(2);
%         actualPosition2(i)   = data(i).ActorPoses(2).Position(2);
%         actualPosition1(i)   = data(i).ActorPoses(3).Position(2);
% 
%     end

    
end
% Negative range is behind radar
car1_r(car1_r<0)=nan;
car2_r(car2_r<0)=nan;
% Negative speed is direction of travel
% car1_v(car1_v<0)=nan;
% car2_v(car2_v<0)=nan;

%% Plots
close all
figure1 = figure('WindowState','maximized');
tl = tiledlayout(1, 2);
nexttile
hold on
scatter(t, abs(measuredVelocity2(:, :)), 70,'Marker','.')
p1 = plot(t, abs(car1_v), 'DisplayName', 'Car 1 Actual');
p2 = plot(t, abs(car2_v), 'DisplayName', 'Car 2 Actual');
title("LHS Radar Velocity Measurements")
xlabel("Time (s)")
ylabel("Speed (m/s)")
axis([0 max(t) 0 20])
legend([p1 p2],'Location', 'southeast')
% 
% nexttile
% hold on
% scatter(t, abs(measuredVelocity1(:, 1:5)),70, 'Marker','.')
% p2 = plot(t, abs(actualVelocity1), 'DisplayName', 'Actual');
% title("RHS Radar Velocity Measurements")
% xlabel("Time (s)")
% ylabel("Speed (m/s)")
% axis([0 max(t) 0 20])
% legend(p2,'Location', 'southeast')

nexttile
hold on
scatter(t, abs(measuredPosition2(:, :)),70, 'Marker','.')
p3 = plot(t, abs(car1_r), 'DisplayName', 'Car 1 Actual');
p4 = plot(t, abs(car2_r), 'DisplayName', 'Car 2 Actual');
title("LHS Radar Range Measurements")
xlabel("Time (s)")
ylabel("Range (m)")
legend([p3, p4],'Location', 'southeast')

% nexttile
% hold on
% scatter(t, abs(measuredPosition1(:, 1:5)), 70, 'Marker','.')
% p4 = plot(t, abs(actualPosition1), 'DisplayName', 'Actual');
% title("RHS Radar Range Measurements")
% xlabel("Time (s)")
% ylabel("Range (m)")
% legend(p4,'Location', 'southeast')

tl.Padding = 'tight';
% tl.TileSpacing = 'compact';

% Create textarrow
% annotation(figure1,'textarrow',[0.148958333333333 0.203125],...
%     [0.789598290598291 0.873931623931624],'String',{'Car 1'});
% 
% % Create textarrow
% annotation(figure1,'textarrow',[0.358854166666667 0.323958333333333],...
%     [0.75434188034188 0.841880341880342],'String',{'Car 2'});
% 
% % Create textarrow
% annotation(figure1,'textarrow',[0.213541666666667 0.189583333333333],...
%     [0.359042735042735 0.27991452991453],'String',{'Car 1'});
% 
% % Create textarrow
% annotation(figure1,'textarrow',[0.634895833333333 0.684895833333333],...
%     [0.757547008547009 0.870726495726496],'String',{'Car 2'});
% 
% % Create textarrow
% annotation(figure1,'textarrow',[0.799479166666667 0.771875],...
%     [0.776777777777778 0.862179487179487],'String',{'Car 1'});
% 
% % Create textarrow
% annotation(figure1,'textarrow',[0.3296875 0.359895833333333],...
%     [0.345153846153846 0.264957264957265],'String',{'Car 2'});
% 
% % Create textarrow
% annotation(figure1,'textarrow',[0.7 0.657291666666667],...
%     [0.36865811965812 0.286324786324786],'String',{'Car 2'});
% 
% % Create textarrow
% annotation(figure1,'textarrow',[0.768233387358185 0.80226904376013],...
%     [0.301245250431779 0.250431778929188],'String',{'Car 1'});

