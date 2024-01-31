function [rawDataAdj, weights'] = mvdrBf(rawData, estimated_angle, magic, ula, fc, c)

    beamformer = phased.MVDRBeamformer('SensorArray',ula,...
'PropagationSpeed',c,'OperatingFrequency',fc,...
'Direction',[estimated_angle;0],'WeightsOutputPort',true, ...
'TrainingInputPort',false, 'DiagonalLoadingFactor', magic);

    [~,weights] = beamformer(rawData); 
    rawDataAdj(:,1) = rawData(:,1)*weights(1);
    rawDataAdj(:,2) = rawData(:,2)*weights(2);
    rawDataAdj(:,3) = rawData(:,3)*weights(3);
    rawDataAdj(:,4) = rawData(:,4)*weights(4);
