function [steering_correction, angle_claibration_src, angle_claibration_intrp] = phase_pattern_generator(meas_mat,scan_axis,interpulation_resolution,num_elements)
% PHASE_PATTERN_GENERATOR Generates phase pattern corrections for phased array.
% This function computes the steering phase corrections required for beamforming
% by applying phase calibration to the measured matrix. It interpolates the phase 
% calibration over a specified resolution to generate the necessary corrections
%
% Inputs:
%   meas_mat - Measured matrix of size [num_samples, num_elements, num_scans]
%   max_aperature - Maximum aperture for angle scanning
%   scanning_resolution - Resolution for angle scanning
%   interpulation_resolution - Resolution for angle interpolation
%   num_elements - Number of elements in the array
%
% Outputs:
%   steering_correction - Steering complex weights phase correction matrix
%   angle_claibration_src - Source angle calibration matrix (in degrees)
%   angle_claibration_intrp - Interpolated angle calibration matrix (in degrees)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    calibration_w = zeros(num_elements,length(scan_axis));
    for k=1:length(scan_axis)
        direction_w = exp(1j*pi*(0:num_elements-1)'*sind(scan_axis(k)));
        meas_mat(:,:,k) = meas_mat(:,:,k).*direction_w';
        [calibration_w(:,k), ~, ~] = cphase(meas_mat(:,:,k), 1); 
    end
    iterpulation_axis = scan_axis(1):interpulation_resolution:scan_axis(end);
    angle_claibration_src = rad2deg(angle(calibration_w));
    angle_claibration_intrp(:,1) = spline(scan_axis,angle_claibration_src(1,:), iterpulation_axis);
    angle_claibration_intrp(:,2) = spline(scan_axis,angle_claibration_src(2,:), iterpulation_axis);
    angle_claibration_intrp(:,3) = spline(scan_axis,angle_claibration_src(3,:), iterpulation_axis);
    angle_claibration_intrp(:,4) = spline(scan_axis,angle_claibration_src(4,:), iterpulation_axis);
    steering_correction = exp(-1j*deg2rad(angle_claibration_intrp));
    figure
    plot(iterpulation_axis, angle_claibration_intrp)
    title('Phase Pattern');
    xlabel('DOA (deg)');
    ylabel('Phase Mismatch (Deg)');
    legend('Ant 1','Ant 2','Ant 3','Ant 4', Location='best');
end