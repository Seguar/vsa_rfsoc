function p_manual = beamPatternCalc(weights, fc, scan_axis, num_elements)
sig_scan = exp(1j*2*pi*fc*(1/100e9:1/100e9:10/100e9));
sig_scan = [sig_scan;sig_scan;sig_scan;sig_scan]';
p_manual = zeros(length(scan_axis),1);
for i=1:length(scan_axis)
    w_scan = exp(1j * pi * (0:num_elements-1)' * sind(scan_axis(i)))*2;
    w_scan = (w_scan.*weights');
    r_weighted = w_scan.'*sig_scan.';
    p_manual(i) = norm(r_weighted);
end