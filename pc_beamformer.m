function [w, R_r] = pc_beamformer(R, npc, numelements, angle)
%% Principal component (PC) Beamformer (Optimum Array Processing - 2002 - Van Trees.pdf P. 560)
% The idea is to construct reduced autocorraltion matrix 
% by elmintation of the eigenvalues and eigenvectors associated 
% with the white noise s.t. the components that will be in the final 
% matrix would be the eigenvectors of the signal and the interferers.

v_m = exp(1j*pi*((0:numelements-1)')*sin(deg2rad(angle)));
[V, D] = eig(R, 'vector');
[D, ind] = sort(D,"descend");
V = V(:, ind);
[~, D_mat] = eig(R, 'matrix');
SSI_full = D_mat(ind, ind);
SSI = SSI_full(1:npc,1:npc);
U_SI = V(:,1:npc);
R_r = U_SI*SSI*U_SI';
w = (v_m.'*U_SI*(SSI^-1)*U_SI')/((v_m'*U_SI*(SSI^-1)*U_SI'*v_m)^-1);
end