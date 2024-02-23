function [rawDataAdj, weights] = steerBf(rawData, estimated_angle, ula, fc)
beamforming = phased.SteeringVector('SensorArray',ula);
weights = beamforming(fc, estimated_angle);
weights = weights';
rawDataAdj(:,1) = rawData(:,1)*weights(1);
rawDataAdj(:,2) = rawData(:,2)*weights(2);
rawDataAdj(:,3) = rawData(:,3)*weights(3);
rawDataAdj(:,4) = rawData(:,4)*weights(4);
