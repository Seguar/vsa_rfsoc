function [rawDataAdj,wLCMV] = lcmv_beamformer(Rxdata, src_angle, intrf_angle, ula, magic, fc)
    lcmvbeamformer = phased.LCMVBeamformer('WeightsOutputPort',true);
    steeringvec = phased.SteeringVector('SensorArray',ula);
    stv = steeringvec(fc,[src_angle intrf_angle+magic intrf_angle-magic]);
    lcmvbeamformer.Constraint = stv;
    lcmvbeamformer.DesiredResponse = [1; db2pow(-100)/2; db2pow(-100)/2];
    [yLCMV,wLCMV] = lcmvbeamformer(Rxdata);

    rawDataAdj(:,1) = Rxdata(:,1)*wLCMV(1);
    rawDataAdj(:,2) = Rxdata(:,2)*wLCMV(2);
    rawDataAdj(:,3) = Rxdata(:,3)*wLCMV(3);
    rawDataAdj(:,4) = Rxdata(:,4)*wLCMV(4);
end