clc
clear
close all
powCalc = @(x) round(max(db(fftshift(fft(x))))/2, 1); % Power from FFT calculations
dbmin = 20; % Limits of polar plot
dbmax = 30;
c = physconst('LightSpeed');
server_ip = 'pynq'; % Use the appropriate IP address or hostname
server_port = 4000; % Use the same port number used in the Python server
scan_bw = 180;
scan_res = 5;
scan_axis = -scan_bw/2:scan_res:scan_bw/2;
dataChan = 2^16;
tcp_client = rfsocConnect(server_ip, server_port, dataChan);
fc = 5.7e9;
fsRfsoc = 125e6;
bw = 1e6;
ch = 5;
bf = 'Without';
doa = 'MUSIC';
ula = antPrep(4, c, fc);
estimator = doaEst(doa, ula, scan_axis, 1, fc);

yspec_new = zeros(6, length(scan_axis));
min_ang = scan_axis(1);
max_ang = scan_axis(end);
while true
    [yspec, estimated_angle, bfSig, ~, rawData] = rfsocBf(0, 0, ch, bf, 0, 0, 0, 1, 0, tcp_client, fc, dataChan, 0, 0, ula, scan_axis, ...
        0, 0, fsRfsoc, bw, c, estimator);
    idx = find(scan_axis == estimated_angle(1));
    if pow2db(yspec(idx)) > yspec_new(6,idx)
        yspec_new(5, idx) = powCalc(bfSig)/4;
        yspec_new(1:4, idx) = powCalc(rawData(1:4,:));
        yspec_new(6,idx) = pow2db(yspec(idx));
    end
    polarplot(deg2rad(scan_axis), yspec_new)    
    ax = gca;
    ax.ThetaZeroLocation = 'top'; % Set 0 degree angle at the top
    ax.ThetaDir = 'clockwise';    % Rotate angles clockwise
    ax.ThetaLim = [min_ang, max_ang];
    ax.ThetaTick = [min_ang:scan_res:max_ang];
    rlim([dbmin dbmax])
    ax.RTick = [dbmin:20:dbmax];

    title(['Estimated angle: ' num2str(estimated_angle)])
end