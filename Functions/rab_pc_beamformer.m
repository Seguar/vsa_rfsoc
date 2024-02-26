function [rawDataAdj, weights] = rab_pc_beamformer(rawData, npc, ula, estimated_angle, delta)
% Robust adaptive beamforming using worst-case performance
% optimization: a solution to the signal mismatch problem
% https://ieeexplore.ieee.org/document/1166614/authors#authors
%%
R = rawData'*rawData;
numelements = ula.NumElements;
[~, w_pc] = pc_beamformer(rawData, npc, ula, estimated_angle);
eps = norm(2*(w_pc)/norm(w_pc)*exp(-1j*angle(w_pc(1))) -  exp(1j*pi*((0:numelements-1))*sin(deg2rad(src_angle))));
weights = nonconvex_rab(R.', src_angle, numelements, delta*eps);
weights = weights.';
fprintf('eps = %.2f', eps)

rawDataAdj(:,1) = rawData(:,1)*weights(1);
rawDataAdj(:,2) = rawData(:,2)*weights(2);
rawDataAdj(:,3) = rawData(:,3)*weights(3);
rawDataAdj(:,4) = rawData(:,4)*weights(4);
end