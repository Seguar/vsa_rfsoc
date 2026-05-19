function yspec = m_mvdr_fast_gpu(sig_final, scan_axis, num_elements, steering_correction_intep, pow_claibration_intrp)

sig_final = gpuArray(sig_final);
scan_axis = gpuArray(scan_axis);
steering_correction_intep = gpuArray(steering_correction_intep);
pow_claibration_intrp = gpuArray(pow_claibration_intrp);

elements_vec = gpuArray((0:num_elements-1).');

A = exp(-1j * pi * elements_vec * sind(scan_axis));
A = A .* steering_correction_intep.' .* pow_claibration_intrp.';

Rx = sig_final' * sig_final;
X = Rx \ A;

B = sum(conj(A) .* X, 1);

yspec = gather(abs(1 ./ B).');
end