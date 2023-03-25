% 
% 
% x =data(3).ObjectDetections;
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
measuredPosition2_x = NaN(N,15);

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
car2_r_x = NaN(N, 1);

t   = NaN(N,1);
rhs_road_width = 1.5;
lhs_road_width = 3.0;
angle_offset = 15*pi/180;
angle_offset = 0;
disp(angle_offset)
for i = 1:N
    t(i) = data(i).Time;
    detections = data(i).ObjectDetections;
    for j = 1:length(detections)
        % Stack detections from radar 1 - RHS
        if detections{j}.SensorIndex == 1
            measuredVelocity1(i,j) = detections{j}.Measurement(3);
            measuredPosition1(i,j) = detections{j}.Measurement(2);
            
            % Angle corrected measurements
%             theta = asin(rhs_road_width/measuredPosition1(i,j));
%             measuredVelocity1(i,j) = ...
%                 detections{j}.Measurement(5)/cos(theta-angle_offset);

        % Stack detections from radar 2 - LHS
        else
            measuredVelocity2(i,j) = detections{j}.Measurement(3);
            % add the radar offset from the origin
            measuredPosition2(i,j) = detections{j}.Measurement(2); %+ 1.3628;
            measuredPosition2_x(i,j) = detections{j}.Measurement(1);
            % range not x and y:
%             measuredPosition2(i,j) = (detections{j}.Measurement(2)^2 + detections{j}.Measurement(1)^2)^0.5;

            % Angle corrected measurements
%             theta = asin(lhs_road_width/measuredPosition2(i,j));
%             measuredVelocity2(i,j) = ...
%                 detections{j}.Measurement(5)/cos(theta-angle_offset);
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


    car1_v(i) = data(i).ActorPoses(2).Velocity(2);
    car1_r(i) = data(i).ActorPoses(2).Position(2);

    car2_v(i) = data(i).ActorPoses(3).Velocity(2);
    car2_r(i) = data(i).ActorPoses(3).Position(2);
    car2_r_x(i) = data(i).ActorPoses(3).Position(1);

    % ENSURE HOST PLACED AT COORD 0,0,0!
    % Ensures tracks are correct for each target plot
    % If RHS range is negative, proceed as normal
    % If RHS range is positive, target is hklkas crossed over to other radar
%     if car1_r(i) > 0
%         actualVelocity2(i)   = data(i).ActorPoses(3).Velocity(2);
%         actualPosition2(i)   = data(i).ActorPoses(3).Position(2);
%     else
%         actualVelocity2(i)   = data(i).ActorPoses(2).Velocity(2);
%         actualPosition2(i)   = data(i).ActorPoses(2).Position(2);
% 
%     end
%     % if LHS range is negative, target crossed to other side
%     if car2_r(i) > 0
%         actualVelocity1(i)   = data(i).ActorPoses(2).Velocity(2);
%         actualPosition1(i)   = data(i).ActorPoses(2).Position(2);
%     else
%         actualVelocity1(i)   = data(i).ActorPoses(3).Velocity(2);
%         actualPosition1(i)   = data(i).ActorPoses(3).Position(2);
%     end

    
end
% Negative range is behind radar
car1_r_right = car1_r;
car2_r_right = car2_r;

car1_r_right(car1_r_right>0)=nan;
car2_r_right(car2_r_right>0)=nan;


car1_r(car1_r<0)=nan;
car2_r(car2_r<0)=nan;
% Negative speed is direction of travel
% car1_v(car1_v<0)=nan;
% car2_v(car2_v<0)=nan;
%% Position coordinates
% close all
% figure
% scatter(measuredPosition2, measuredPosition2_x)
% return
% 

% Calculate range from coordinates
y_offset = -0.9;
x_offset =  3.7;
y_rad    =  2 + y_offset;
x_rad    = -6 + x_offset;
% x_car = 1;
% lhs_x_range = -x_rad+x_car;

% account for radar coordinates not being at the origin
lhsActual_y = car2_r - y_rad;
lhsActual_x = car2_r_x - x_rad;
lhsActualRange = (lhsActual_x.^2 + lhsActual_y.^2).^0.5;


meas_y = measuredPosition2 - y_rad;
meas_x = measuredPosition2_x - x_rad;
lhsMeasRange = (meas_x.^2 + meas_y.^2).^0.5;


close all
figure
plot(t, lhsActualRange)
hold on
scatter(t, measuredPosition2)
hold off
return

%% Plots
close all
figure1 = figure('WindowState','maximized');
tl = tiledlayout(1, 2);
nexttile
hold on
scatter(t, abs(measuredVelocity2(:, :)), 70,'Marker','.')
p1 = plot(t, abs(car1_v), 'DisplayName', 'Car 1 Actual');
p2 = plot(t, abs(car2_v), 'DisplayName', 'Car 2 Actual');
% p1 = plot(t, abs(actualVelocity1), 'DisplayName', 'Car 1 Actual');
% p2 = plot(t, abs(actualVelocity2), 'DisplayName', 'Car 2 Actual');
title("LHS Radar Velocity Measurements")
xlabel("Time (s)")
ylabel("Speed (m/s)")
axis([0 max(t) 0 25])
legend([p1 p2],'Location', 'southeast')
% 
% nexttile
% hold on
% scatter(t, abs(measuredVelocity1(:, :)),70, 'Marker','.')
% % p2 = plot(t, abs(actualVelocity1), 'DisplayName', 'Actual');
% p12 = plot(t, abs(car1_v), 'DisplayName', 'Car 1 Actual');
% p22 = plot(t, abs(car2_v), 'DisplayName', 'Car 2 Actual');
% % p12 = plot(t, abs(actualVelocity1), 'DisplayName', 'Car 1 Actual');
% % p22 = plot(t, abs(actualVelocity2), 'DisplayName', 'Car 2 Actual');
% title("RHS Radar Velocity Measurements")
% xlabel("Time (s)")
% ylabel("Speed (m/s)")
% axis([0 max(t) 0 25])
% legend([p12 p22],'Location', 'southeast')

nexttile
hold on
scatter(t, abs(measuredPosition2(:, :)),70, 'Marker','.')
p3 = plot(t, abs(car1_r), 'DisplayName', 'Car 1 Actual');
p4 = plot(t, abs(car2_r), 'DisplayName', 'Car 2 Actual');
% p3 = plot(t, abs(actualPosition1), 'DisplayName', 'Car 1 Actual');
% p4 = plot(t, abs(actualPosition2), 'DisplayName', 'Car 2 Actual');
title("LHS Radar Range Measurements")
xlabel("Time (s)")
ylabel("Range (m)")
legend([p3, p4],'Location', 'southeast')

% nexttile
% hold on
% scatter(t, abs(measuredPosition1(:, :)), 70, 'Marker','.')
% % p5 = plot(t, abs(actualPosition1), 'DisplayName', 'Actual');
% p32 = plot(t, abs(car1_r_right), 'DisplayName', 'Car 1 Actual');
% p42 = plot(t, abs(car2_r_right), 'DisplayName', 'Car 2 Actual');
% % p32 = plot(t, abs(actualPosition1), 'DisplayName', 'Car 1 Actual');
% % p42 = plot(t, abs(actualPosition2), 'DisplayName', 'Car 2 Actual');
% title("RHS Radar Range Measurements")
% xlabel("Time (s)")
% ylabel("Range (m)")
% legend([p32, p42],'Location', 'southeast')
% % legend(p32,'Location', 'southeast')

tl.Padding = 'tight';
% tl.TileSpacing = 'compact';
%%
meanMeasuredPos2 = mean(measuredPosition2, 2, 'omitnan');
meanMeasuredVel2 = mean(measuredVelocity2, 2, 'omitnan');

meanMeasuredPos1 = mean(measuredPosition1, 2, 'omitnan');
meanMeasuredVel1 = mean(measuredVelocity1, 2, 'omitnan');
% numDets = 0;
% for i = 1:N
%     for j = 1:15
%         if (measuredPosition2(i,j).isNaN == 0)
%             numDets = numDets + 1;
%             tempPos(numDets) = measuredPosition2(i,j);
%         end
%         if (measuredVelocity2(i,j).isNaN == 0)
%             numDets = numDets + 1;
%             tempVel(numDets) = measuredPosition2(i,j);
%         end
%     end
% end
%%


% close all
% figure1 = figure('WindowState','maximized');
% tl = tiledlayout(1, 2);
% nexttile
% hold on
% scatter(t, abs(measuredVelocity2(:, :)), 70,'Marker','.')
% % p1 = plot(t, abs(car1_v), 'DisplayName', 'Car 1 Actual');
% % p2 = plot(t, abs(car2_v), 'DisplayName', 'Car 2 Actual');
% p1 = plot(t, abs(actualVelocity1), 'DisplayName', 'Car 1 Actual');
% p2 = plot(t, abs(actualVelocity2), 'DisplayName', 'Car 2 Actual');
% title("LHS Radar Velocity Measurements")
% xlabel("Time (s)")
% ylabel("Speed (m/s)")
% axis([0 max(t) 0 25])
% legend([p1 p2],'Location', 'southeast')
% 
% nexttile
% hold on
% scatter(t, abs(measuredPosition2(:, :)),70, 'Marker','.')
% p3 = plot(t, abs(car1_r), 'DisplayName', 'Car 1 Actual');
% p4 = plot(t, abs(car2_r), 'DisplayName', 'Car 2 Actual');
% % p3 = plot(t, abs(actualPosition1), 'DisplayName', 'Car 1 Actual');
% % p4 = plot(t, abs(actualPosition2), 'DisplayName', 'Car 2 Actual');
% title("LHS Radar Range Measurements")
% xlabel("Time (s)")
% ylabel("Range (m)")
% legend([p3, p4],'Location', 'southeast')
% 

%%

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

