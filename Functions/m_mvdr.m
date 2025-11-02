function yspec = m_mvdr(sig_final, scan_axis, num_elements, steering_correction_intep, pow_claibration_intrp)
% function yspec_fixed = calculate_fixed_spectrum(sig_final, scan_axis, num_elements, steering_correction, pow_claibration_intrp)
%
% Calculates the output spectrum (yspec) using an efficient vectorized beamforming method.
% The function implements an optimization where the power calibration
% is moved from a division operation on the data (sig_final) to a
% multiplication operation on the steering vector (A).
%
% This optimization allows for the calculation of only *one* uncalibrated
% covariance matrix and only *one* matrix inversion, instead of L
% calculations and inversions (where L is the number of scan angles).
%
% === Inputs ===
%
%   sig_final: [NxM] matrix of data samples (snapshots).
%       - N: Number of snapshots.
%       - M: Number of array elements (e.g., 4).
%       - Required to be a complex matrix.
%
%   scan_axis: [1xL] vector of scan angles (in degrees).
%       - L: Number of scan points (e.g., 1201).
%
%   num_elements: [1x1] scalar. The number of array elements (M).
%       - This value must match the second dimension of sig_final (M).
%
%   steering_correction: [LxM] matrix for steering vector correction.
%       - L: Must match the length of scan_axis.
%       - M: Must match num_elements.
%
%   pow_claibration_intrp: [LxM] matrix for power calibration.
%       - L: Must match the length of scan_axis.
%       - M: Must match num_elements.
%
% === Output ===
%
%   yspec_fixed: [Lx1] vector of the calculated spectrum (in dB).
%       - An L-length column vector.
%
% === Calculation Process ===
% 1. Calculate the basic steering vectors (A_all).
% 2. Apply calibrations (steering + power) to the steering vectors to create A_fixed_all.
% 3. Calculate the uncalibrated covariance matrix (Rx_fixed_all_3D) *only once*.
% 4. Invert the covariance matrix (Rx_Inv_fixed_all_3D) *only once*.
% 5. Vectorized calculation of B(t) = (A_fixed)' * Rx_Inv * (A_fixed) using pagemtimes.
% 6. Final conversion to dB.
%

% --- Step 1: Set dimensions and calculate steering vectors ---

    % L = Number of scan points
    L = length(scan_axis);
    % N = Number of samples (not directly needed for the rest of the calculation)
    % N = size(sig_final, 1); 
    
    % Create a vector of element indices (M x 1)
    % (This is the fix from the original script, to avoid overwriting num_elements)
    elements_vec = (0:num_elements-1)';
    
    % Create all basic steering vectors (M x L)
    % (M x 1) * (1 x L) -> (M x L)
    A_all = exp(-1j * pi * elements_vec * sind(scan_axis));
    
    % --- Step 2: Apply calibrations to the steering vectors (The Optimization) ---
    % Instead of dividing the data, we multiply the steering vector.
    % A_all (MxL) .* steering_correction' (MxL) .* pow_claibration_intrp' (MxL)
    A_fixed_all = A_all .* steering_correction_intep' .* pow_claibration_intrp.';
    
    % --- Step 3: Calculate uncalibrated covariance matrix (once) ---
    
    % Prepare the data for pagemtimes.
    % To ensure this works even if N=1, we add a third 'page' dimension.
    sig_final_3D = permute(sig_final, [1, 2, 3]); % NxMx1
    
    % Calculate the covariance (MxM)
    % pagemtimes( (MxNx1), (NxMx1) ) -> (MxMx1)
    Rx_fixed_all_3D = pagemtimes(pagectranspose(sig_final_3D), sig_final_3D);
    
    % --- Step 4: Invert the covariance matrix (once) ---
    % (MxMx1) -> (MxMx1)
    Rx_Inv_fixed_all_3D = pageinv(Rx_fixed_all_3D);
    
    % --- Step 5: Vectorized calculation of B(t) ---
    
    % Prepare the calibrated steering vectors for pagemtimes
    % (MxL) -> (Mx1xL)
    A_fixed_3D = permute(A_fixed_all, [1, 3, 2]);
    
    % B(t) = A_fixed' * Rx_Inv * A_fixed
    % We use broadcasting: The Rx_Inv matrix (MxMx1)
    % will be automatically duplicated L times to match the dimensions of A_fixed_3D (Mx1xL).
    
    % temp = A_fixed' * Rx_Inv
    % (1xMxL) = pagemtimes( (Mx1xL, 'C'), (MxMx1, 'N') )
    temp_B_fixed = pagemtimes(A_fixed_3D, 'C', Rx_Inv_fixed_all_3D, 'N');
    
    % B = temp * A_fixed
    % (1x1xL) = pagemtimes( (1xMxL, 'N'), (Mx1xL, 'N') )
    B_fixed_all_3D = pagemtimes(temp_B_fixed, 'N', A_fixed_3D, 'N');
    
    % --- Step 6: Convert to dB ---
    
    % Convert the page-dimension (1x1xL) to a vector (Lx1)
    B_fixed_all = squeeze(B_fixed_all_3D);
    
    % Convert to dB
    yspec = 10*log10(abs(1./B_fixed_all));
    yspec = db2pow(yspec);
    % Ensure the output is always a column vector
    if isrow(yspec)
        yspec = yspec.';
    end
end