function [rawDataAdj, weights] = qcb_beamformer_algo_2(rawData, ula, src_angle, ang_mis, gamma, alpha, iter, scan_res, fc)
    % Quadratically_Constrained_Beamforming_Robust_Against_Direction-of-Arrival_Mismatch
    % algo 2 - find gamma - the diagonal loading
    % alpha > 1 is the step size
    % scan_res value can be > 3;
    R_y = rawData'*rawData;
    R_y = R_y./max(abs(R_y));
    numelements = ula.NumElements;
    c = physconst('LightSpeed');
    lambda = c/fc;
    theta1 = src_angle - ang_mis;
    theta2 = src_angle + ang_mis;
    ang_scan = theta1:scan_res:theta2;
    stop_flag = 1;
    one_iter_flag = 1;
    while iter > 0 && stop_flag
        R_y = R_y + gamma*eye(size(R_y));
        w_gamma = qcb_beamformer_algo_1(R_y, numelements,src_angle, ang_mis, fc);
        if one_iter_flag
            w_1 = w_gamma;
            one_iter_flag = 0;
        end
        s = exp(1j*(pi)*((0:numelements-1)')*sin(deg2rad(ang_scan)));
        s_w_norm = abs(s'*w_gamma);
        s_w_flag = (sum(s_w_norm >= 1) == length(s_w_norm));
%         length(s_w_norm) - sum(s_w_norm >= 1)
        if s_w_flag
            stop_flag = 0;
        else
            gamma = alpha*gamma;
        end
        iter = iter - 1;
    end
    disp(iter)
    weights = w_gamma;
    weights = weights';
    rawDataAdj(:,1) = rawData(:,1)*weights(1);
    rawDataAdj(:,2) = rawData(:,2)*weights(2);
    rawDataAdj(:,3) = rawData(:,3)*weights(3);
    rawDataAdj(:,4) = rawData(:,4)*weights(4);
end