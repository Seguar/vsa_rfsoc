function rawDataAdj = steerBf(rawData, estimated_angle, lambda)
cPhSh = @(a) 360*(lambda/2)*sind(a)/lambda; % Calculation of constant phase shift between elements
deg2comp = @(a) exp(1i*deg2rad(a)); % Degrees to complex (1 round) convertion
%%
df = cPhSh(-estimated_angle);

an(1) = 1;
an(2) = deg2comp(df*1);
an(3) = deg2comp(df*2);
an(4) = deg2comp(df*3);
rawDataAdj(:,1) = rawData(:,1)*an(1);
rawDataAdj(:,2) = rawData(:,2)*an(2);
rawDataAdj(:,3) = rawData(:,3)*an(3);
rawDataAdj(:,4) = rawData(:,4)*an(4);
%Need to rework