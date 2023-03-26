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

car1_r_y = NaN(N, 1);
car2_r_y = NaN(N, 1);
car1_r_x = NaN(N, 1);
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

        % Stack detections from radar 2 - LHS
        else
            measuredVelocity2(i,j) = detections{j}.Measurement(3);
            % add the radar offset from the origin
            measuredPosition2(i,j) = detections{j}.Measurement(2); %+ 1.3628;
            measuredPosition2_x(i,j) = detections{j}.Measurement(1);
        end
    end
    
    car1_v(i) = data(i).ActorPoses(2).Velocity(2);
    car2_v(i) = data(i).ActorPoses(3).Velocity(2);
    
    % Account for distance of bumper from center coordinates
    % Range is to the closest point of the vehicle
    car1_r_y(i) = data(i).ActorPoses(2).Position(2)-1;
    car1_r_x(i) = data(i).ActorPoses(2).Position(1)-0.9;

    car2_r_y(i) = data(i).ActorPoses(3).Position(2)-3.7;
    car2_r_x(i) = data(i).ActorPoses(3).Position(1)-0.9;
end
% Negative range is behind radar
car1_r_right = car1_r_y;
car2_r_right = car2_r_y;

car1_r_right(car1_r_right>0)=nan;
car2_r_right(car2_r_right>0)=nan;


car1_r_y(car1_r_y<0)=nan;
car2_r_y(car2_r_y<0)=nan;
% Negative speed is direction of travel
% car1_v(car1_v<0)=nan;
% car2_v(car2_v<0)=nan;

%% Average each cluster
lhsRngClusterMean = mean(measuredPosition2, 2, "omitnan");
lhsVelClusterMean = mean(measuredVelocity2, 2, "omitnan");

%% Get range vector from x and y

% below not needed if measurement is spherical
% lhsRng = (measuredPosition2_x.^2 + measuredPosition2.^2).^0.5;
lhsRngActual = (car2_r_y.^2 + car2_r_x.^2).^0.5;
rhsRngActual = (car1_r_y.^2 + car1_r_x.^2).^0.5;

%% Plots
close all
% figure1 = figure('WindowState','maximized');
fig1 = figure();
% tl = tiledlayout(1, 2);
% nexttile
hold on
scatter(t, abs(measuredVelocity2), 70,'Marker','.')
% plot(t, abs(lhsVelClusterMean))
p1 = plot(t, abs(car1_v), 'DisplayName', 'Car 1 Actual');
p2 = plot(t, abs(car2_v), 'DisplayName', 'Car 2 Actual');
hold off
% p1 = plot(t, abs(actualVelocity1), 'DisplayName', 'Car 1 Actual');
% p2 = plot(t, abs(actualVelocity2), 'DisplayName', 'Car 2 Actual');
% title("LHS Radar Velocity vs. Time", 'FontSize', 14)
xlabel("Time (s)", 'FontSize', 14)
ylabel("Speed (m/s)", 'FontSize', 14)
axis([0 max(t) 0 25])
legend([p1 p2],'Location', 'northeast', 'FontSize', 13)
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

% nexttile
fig2 = figure();
hold on
scatter(t, abs(measuredPosition2),70, 'Marker','.')
% plot(t, lhsRngClusterMean)
p3 = plot(t, abs(lhsRngActual), 'DisplayName', 'Car 1 Actual');
p4 = plot(t, abs(rhsRngActual), 'DisplayName', 'Car 2 Actual');
hold off
% p3 = plot(t, abs(actualPosition1), 'DisplayName', 'Car 1 Actual');
% p4 = plot(t, abs(actualPosition2), 'DisplayName', 'Car 2 Actual');
% title("LHS Radar Range vs. Time")
xlabel("Time (s)", 'FontSize', 14)
ylabel("Range (m)", 'FontSize', 14)
legend([p3, p4],'Location', 'northeast', 'FontSize', 13)

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

% tl.Padding = 'tight';
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
% p3 = plot(t, abs(car1_r_y), 'DisplayName', 'Car 1 Actual');
% p4 = plot(t, abs(car2_r_y), 'DisplayName', 'Car 2 Actual');
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

