function [rawDataAdj, weights] = rvl_beamformer(rawData, delta, ula, estimated_angle)
%% VL beamformer
R = rawData'*rawData;
numelements = ula.NumElements;
v_m = exp(1j*pi*((0:numelements-1)')*sin(deg2rad(estimated_angle)));
% [V, D] = eig(R, 'vector');
% [D, ind] = sort(D,"descend");
w_0 = ((R + delta*(R^-1))^-1)*v_m;
w = w_0/(v_m'*w_0);
weights = (w).';
rawDataAdj(:,1) = rawData(:,1)*weights(1);
rawDataAdj(:,2) = rawData(:,2)*weights(2);
rawDataAdj(:,3) = rawData(:,3)*weights(3);
rawDataAdj(:,4) = rawData(:,4)*weights(4);
end