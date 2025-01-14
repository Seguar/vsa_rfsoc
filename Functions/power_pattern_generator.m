function pow_claibration_intrp = power_pattern_generator(meas_mat, scan_axis, interpulation_resolution, num_elements)
    norm_sig = zeros(num_elements, length(scan_axis));
    for k=1:length(scan_axis)
        sig = meas_mat(:,:,k);
        norm_sig(:,k) = 20*log10(std(sig));
    end
    norm_sig_pow = 10.^(norm_sig/10);
    iterpulation_axis = scan_axis(1):interpulation_resolution:scan_axis(end);
    pow_claibration_src = norm_sig_pow;
    pow_claibration_intrp(:,1) = spline(scan_axis,pow_claibration_src(1,:), iterpulation_axis);
    pow_claibration_intrp(:,2) = spline(scan_axis,pow_claibration_src(2,:), iterpulation_axis);
    pow_claibration_intrp(:,3) = spline(scan_axis,pow_claibration_src(3,:), iterpulation_axis);
    pow_claibration_intrp(:,4) = spline(scan_axis,pow_claibration_src(4,:), iterpulation_axis);
    % pow_claibration_intrp = pow_claibration_intrp/(pow_claibration_src(1,7));
%     figure(8);
%     hold on;
%     plot(iterpulation_axis,db(pow_claibration_intrp)/2,LineStyle="-", LineWidth=3);
%     % plot(iterpulation_axis,pow_new,LineStyle="--", LineWidth=3);
%     title('Power Pattern');
%     xlabel('DOA (deg)');
%     ylabel('Power (dBm)');
%     legend('Ant 1','Ant 2','Ant 3','Ant 4', Location='nw');
%     set(gca, fontsize=15)
%     grid on;
end