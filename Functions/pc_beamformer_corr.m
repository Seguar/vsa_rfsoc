function [rawDataAdj, weights] = pc_beamformer_corr(rawData, npc, ula, estimated_angle, corr)
%% Principal component (PC) Beamformer (Optimum Array Processing - 2002 - Van Trees.pdf P. 560)
% The idea is to construct reduced autocorraltion matrix 
% by elmintation of the eigenvalues and eigenvectors associated 
% with the white noise s.t. the components that will be in the final 
% matrix would be the eigenvectors of the signal and the interferers.
% npc - number of signals
if not(isa(corr, 'double'))
    corr = 1;
end
R = rawData'*rawData;
numelements = ula.NumElements;
v_m = exp(1j*pi*((0:numelements-1)')*sin(deg2rad(estimated_angle)));
[V, D] = eig(R, 'vector');
[~, ind] = sort(D,"descend");
V = V(:, ind);
[~, D_mat] = eig(R, 'matrix');
SSI_full = D_mat(ind, ind);
SSI = SSI_full(1:npc,1:npc);
U_SI = V(:,1:npc);
weights = (v_m.'*U_SI*(SSI^-1)*U_SI')/((v_m'*U_SI*(SSI^-1)*U_SI'*v_m)^-1).*corr;

rawDataAdj(:,1) = rawData(:,1)*weights(1);
rawDataAdj(:,2) = rawData(:,2)*weights(2);
rawDataAdj(:,3) = rawData(:,3)*weights(3);
rawDataAdj(:,4) = rawData(:,4)*weights(4);
end