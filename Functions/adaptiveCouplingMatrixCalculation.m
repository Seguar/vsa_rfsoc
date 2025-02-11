function coupling_matrix = adaptiveCouplingMatrixCalculation(meas_mat, norm_sig_pow, angle_claibration_src, cal_angles, fc, c, ula, num_elements, iter)
lambda = c / fc; % wavelength
d = lambda/2; % spacsing antenna elemnts
cal_angles = cal_angles.';
scan_axis = cal_angles(1):cal_angles(end);
estimator = phased.MUSICEstimator('SensorArray',ula,'ScanAngles',scan_axis,...
    'OperatingFrequency',fc,...
    'DOAOutputPort',true,'NumSignalsSource','Property',...
    'NumSignals', 1);

% correction coeffcients 
power_cal_src = norm_sig_pow';
angle_cal_src = angle_claibration_src';

% correction coeffcients 
str_mat_err = exp(1j*2*pi*d/lambda*sind(angle_cal_src)).*power_cal_src;
str_mat_gen = exp(1j*2*pi*d/lambda*(0:num_elements-1).*sind(cal_angles));

% correction matix - mutual coupling matrix
C = pinv(str_mat_gen.*str_mat_err)*str_mat_gen;

% temp coeff
cal_tmp = cal_angles;
str_mat_err_tmp = str_mat_err;
coupling_matrix = C;


% iter=100;
for q=1:iter
    for i=1:length(cal_angles)
        sig_rx = meas_mat(:,:,i);
        [~,doa] = estimator(sig_rx);
        cal_tmp(i) = doa;
        R = sig_rx'*sig_rx;
        [V, ~] = eig(R,'matrix');
        temp_str = V(:,end);
        str_mat_with_err_tmp(i,:) = coupling_matrix\temp_str;
    end
    str_mat_gen = exp(1j*2*pi*d/lambda*(0:num_elements-1).*sind(cal_tmp));
    C_tmp_prev = coupling_matrix;
    coupling_matrix = pinv(str_mat_with_err_tmp)*str_mat_gen;

    % tol
    % tol = norm(coupling_matrix-C_tmp_prev);
end

% output
% coupling_matrix;
% sig_fixed = (coupling_matrix.'*sig_rx').';
% 
% % appley on signal for DOA
% [y,doas_fixed] = estimator(sig_fixed);
% 
% % appley on signal for BF
% R = sig_fixed'*sig_fixed;
% [w, ~] = pc_beamformer(R,npc,numelemnts,src_angle);