function [rawDataAdj, weights] = dl_mvdr_beamformer(rawData, ula, estimated_angle)
% calc diagonal loading:
% Nonedegenerate elipsoied constraints
R = rawData'*rawData;
numelements = ula.NumElements;
% 1) Compute eigendecomposition of R
[U, D] = eig(R, 'vector');
[D, ind] = sort(D,'descend');
U = U(:, ind);

% 2) Solve Eq. (24) from the paper using Newton's method
a_hat = exp(1j*pi*((0:numelements-1)')*sin(deg2rad(estimated_angle)));
z = U'*a_hat;
lam = optimvar('lam');
eps = optimvar('eps');
prob = optimproblem;
prob.Objective = sum((abs(z).^2)./(1+lam*D.^2)) - eps;
prob.Constraints.cons1 = (norm(a_hat)-sqrt(eps))/(D(1)*sqrt(eps)) <= lam;
prob.Constraints.cons2 = (norm(a_hat)-sqrt(eps))/(D(4)*sqrt(eps)) >= lam;
prob.Constraints.cons3 = sqrt((1/eps)*sum((abs(z).^2)./(D.^2)))  >= lam;
prob.Constraints.cons4 = eps >= 0;
prob.Constraints.cons5 = lam >= 0;
x0.lam = D(3);
x0.eps = 1;
sol = solve(prob, x0);

% 3) MVDR beamformer
v_m = exp(1j*pi*((0:numelements-1)')*sin(deg2rad(estimated_angle)));
R_r = R + eye(numelements)*sol.lam;
weights = (v_m.'*(R_r)^-1)/(v_m'*(R_r)^-1*v_m);

rawDataAdj(:,1) = rawData(:,1)*weights(1);
rawDataAdj(:,2) = rawData(:,2)*weights(2);
rawDataAdj(:,3) = rawData(:,3)*weights(3);
rawDataAdj(:,4) = rawData(:,4)*weights(4);
end