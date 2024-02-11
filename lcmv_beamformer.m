function [rawDataAdj, weights] = lcmv_beamformer(rawData, estimated_angle, intrf_angle, ula, magic, fc)
    lcmvbeamformer = phased.LCMVBeamformer('WeightsOutputPort',true);
    steeringvec = phased.SteeringVector('SensorArray',ula);
    stv = steeringvec(fc,[estimated_angle intrf_angle+magic intrf_angle-magic]);
    lcmvbeamformer.Constraint = stv;
    lcmvbeamformer.DesiredResponse = [1; db2pow(-100)/2; db2pow(-100)/2];
    [rawDataAdj,weights] = lcmvbeamformer(rawData);
    weights = weights.';
end