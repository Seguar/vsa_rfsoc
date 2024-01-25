function rawDataAdj = mvdrBf(rawData, estimated_angle, magic)

    beamformer = phased.MVDRBeamformer('SensorArray',ula,...
'PropagationSpeed',c,'OperatingFrequency',fc,...
'Direction',[estimated_angle;0],'WeightsOutputPort',true, ...
'TrainingInputPort',false, 'DiagonalLoadingFactor', magic);

    [~,w_est_ang] = beamformer(rawData); 

    rawDataAdj(:,1) = rawData(:,1)*w_est_ang(1);
    rawDataAdj(:,2) = rawData(:,2)*w_est_ang(2);
    rawDataAdj(:,3) = rawData(:,3)*w_est_ang(3);
    rawDataAdj(:,4) = rawData(:,4)*w_est_ang(4);
