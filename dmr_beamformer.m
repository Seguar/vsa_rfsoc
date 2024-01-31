function [w, R_r] = dmr_beamformer(R, npc, numelements, angle)
%% Dominant mode rejection (Optimum Array Processing - 2002 - Van Trees.pdf P. 570)
% The idea is to construct autocorraltion matrix 
% with repaired eigenvalues and eigenvectors associated 
% with the white noise s.t. the the final 
% matrix would be eigenvectors of the signal and the interferers.

v_m = exp(1j*pi*((0:numelements-1)')*sin(deg2rad(angle)));
[V, D] = eig(R, 'vector');
[D, ind] = sort(D,"descend");
V = V(:, ind);
alpha = 1/(numelements-npc) * sum(D(npc+1:end));
D(npc+1:end) = alpha;
D_mat = diag(D);
SSI = D_mat;
U_SI = V;
R_r = U_SI*SSI*U_SI';
w = (v_m.'*U_SI*(SSI^-1)*U_SI')/((v_m'*U_SI*(SSI^-1)*U_SI'*v_m)^-1);
end