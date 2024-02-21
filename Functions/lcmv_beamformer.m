function [rawDataAdj, weights] = lcmv_beamformer(rawData, estimated_angle, intrf_angle, ula, offset, fc)
    lcmvbeamformer = phased.LCMVBeamformer('WeightsOutputPort',true);
    steeringvec = phased.SteeringVector('SensorArray',ula);
    stv = steeringvec(fc,[estimated_angle intrf_angle-offset/2 intrf_angle+offset/2]);
    lcmvbeamformer.Constraint = stv;
    lcmvbeamformer.DesiredResponse = [1; db2pow(-100)/2; db2pow(-100)/2];
    [~,weights] = lcmvbeamformer(rawData);
    rawDataAdj(:,1) = rawData(:,1)*weights(1);
    rawDataAdj(:,2) = rawData(:,2)*weights(2);
    rawDataAdj(:,3) = rawData(:,3)*weights(3);
    rawDataAdj(:,4) = rawData(:,4)*weights(4);
    weights = weights.';
end