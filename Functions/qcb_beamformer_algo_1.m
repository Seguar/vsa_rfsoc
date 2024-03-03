function [w_0] = qcb_beamformer_algo_1(R_y, numelements,src_angle, ang_mis, fc)
    % Quadratically_Constrained_Beamforming_Robust_Against_Direction-of-Arrival_Mismatch
    % algo 1 - find w_0
    c = physconst('LightSpeed');
    lambda = c/fc;
    theta1 = src_angle - ang_mis;
    theta2 = src_angle + ang_mis;
    s1 = exp(1j*(pi)*((0:numelements-1)')*sin(deg2rad(theta1)));
    s2 = exp(1j*(pi)*((0:numelements-1)')*sin(deg2rad(theta2)));
    S = [s1,s2];
    V = (R_y^-1)*S;
    R = (S'*V)^-1;
    r = [abs(R(1,1)), abs(R(2,2)), abs(R(1,2))];
    phi = -angle(R(1,2)) + pi;
    rho_0_flag = (r(3)/r(1) <= 1);
    rho_1_flag = (r(3)/r(2) <= 1);
    rho0 = r(3)/r(1) - (r(3)/r(1)*rho_0_flag - 1)*rho_0_flag;
    rho1 = r(3)/r(2) - (r(3)/r(2)*rho_1_flag - 1)*rho_1_flag;
    w_0 = V*R*[rho0; rho1*exp(1j*phi)];
end