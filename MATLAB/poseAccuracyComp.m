function poseAccuracyComp(dvsData,optitrackData,timeOffsetOpti)

Pd_raw = importdata(dvsData);
Po = importdata(optitrackData);

%eliminate duplicates in dvs data
Pd = unique(Pd_raw,'rows','stable');

%Pd = Pd_raw;
%dvs data
Td = Pd(:,1:3);
V_r = Pd(:,4:6);

timeD = Pd(:,15);
timeD = timeD - timeD(1);

RPY = zeros(size(V_r));

[m n] = size(V_r);

for i = 1:m
    RPY(i,:) = rpyAng(rodrigues(V_r(i,:)));
end;

RPY = radtodeg(RPY);

rollD = RPY(:,1);
pitchD = RPY(:,2);
yawD = RPY(:,3);

%optitrack data
To = Po(:,[2 1 3]);
To(:,2) = -To(:,2);

Qo = Po(:,4:7);

timeO = Po(:,8);
timeO = timeO - timeO(1) + timeOffsetOpti;

[yawO,pitchO,rollO] = quat2angle(Qo);

rollO = radtodeg(pitchO);
pitchO = radtodeg(yawO);
yawO = radtodeg(rollO);

% interpolate optitrack data
To_i(:,1) = interp1(timeO,To(:,1),timeD);
To_i(:,2) = interp1(timeO,To(:,2),timeD);
To_i(:,3) = interp1(timeO,To(:,3),timeD);

%determine rotation and translation to align both ref frames
T1 = Td';
T2 = To_i;

Q0 = ones(1,4);
t0 = zeros(3,1);

[m n] = size(T1);

fun = @(Q,t) sum(sqrt(sum( (T1 - ( quatrotate(Q,T2)' + repmat(t,1,n))).^2 )));

[Q_res t_res] = lsqnonlin(fun,Q0,t0);

% align to dvs referece frame
[m n] = size(To_i);
To_i = quatrotate(Q,To_i) + repmat(t_res',m,1);

%plotting
style = '-o';

subplot(2,2,1); plot(timeD,Td(:,1),style,timeD,To_i(:,1),style);
title('Translation x [m]');
xlabel('Time [s]');
ylabel('x');

subplot(2,2,2); plot(timeD,Td(:,2),style,timeD,To_i(:,2),style);
title('Translation y [m]');
xlabel('Time [s]');
ylabel('x');

subplot(2,2,3); plot(timeD,Td(:,3),style,timeD,To_i(:,3),style);
title('Translation z [m]');
xlabel('Time [s]');
ylabel('x');

% figure;
% 
% subplot(2,2,1); plot(timeD,yawD,style,timeO,yawO,style);
% title('Yaw');
% xlabel('Time [s]');
% ylabel('Degree');
% 
% subplot(2,2,2); plot(timeD,pitchD,style,timeO,pitchO,style);
% title('Yaw');
% xlabel('Time [s]');
% ylabel('Degree');
% 
% subplot(2,2,3); plot(timeD,rollD,style,timeO,rollO,style);
% title('Yaw');
% xlabel('Time [s]');
% ylabel('Degree');
