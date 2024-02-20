function [yspec, estimated_angle, bfSig, weights, rawData, estimator] = rfsocBf(app, vsa, ch, bf, off, gap, cutter, ang_num, doa, data_v, tcp_client, fc, dataChan, magic, ula, num, scan_axis, ...
    c1, c2, fsRfsoc, bw)
test_z = zeros(1, gap);

c = physconst('LightSpeed'); % propagation velocity [m/s]
lambda = c / fc; % wavelength


%% TCP prep
data_size = dataChan * 8;
channels = 8;
dataLen = data_size/channels;
%% TCP
rawData = tcpDataRec(tcp_client, data_size, channels);
%% Matlab MVDR DOA FUNC
rawData = filtSig(rawData, fsRfsoc, bw);
%% DOA
switch doa
    case 'MVDR'
        estimator = phased.MVDREstimator('SensorArray',ula,...
            'OperatingFrequency',fc,'ScanAngles',scan_axis,...
            'DOAOutputPort',true,'NumSignals', num);
    case 'MUSIC'
        estimator = phased.MUSICEstimator('SensorArray',ula,...
            'OperatingFrequency',fc,'ScanAngles',scan_axis,...
            'DOAOutputPort',true);
    case 'MUSICR'
        estimator = phased.RootMUSICEstimator('SensorArray',ula,...
            'OperatingFrequency',fc);
    case 'Beamscan'
        estimator = phased.BeamscanEstimator('SensorArray',ula,...
            'OperatingFrequency',fc,'ScanAngles',scan_axis,...
            'DOAOutputPort',true,'NumSignals', num);
    case 'ESPRITE'
        estimator = phased.ESPRITEstimator('SensorArray',ula,...
            'OperatingFrequency',fc);
    case 'ESPRITEBS'
        estimator = phased.BeamspaceESPRITEstimator('SensorArray',ula,...
            'OperatingFrequency',fc);
    case 'WSFR'
        estimator = phased.RootWSFEstimator('SensorArray',ula,...
            'OperatingFrequency',fc);
        %     case 'Monopulse'
        %         estimator = phased.SumDifferenceMonopulseTracker('SensorArray',ula,...
        %             'OperatingFrequency',fc);
end
try
    [yspec, estimated_angle] = estimator(rawData'*rawData);
catch
    estimated_angle = estimator(rawData'*rawData);
    yspec = zeros(size(scan_axis));
end
%% Angles

if ch>4
    ch = 1:4;
end

npc = sum(~isnan(estimated_angle));

estimated_angle = [estimated_angle(ang_num) estimated_angle];
estimated_angle(ang_num + 1) = [];
switch bf
    case 'Steering'
        [rawDataAdj, weights] = steerBf(rawData, estimated_angle(1), lambda);
    case 'MVDR'
        [rawDataAdj, weights] = mvdrBf(rawData, estimated_angle(1), magic, ula, fc, c);
    case 'DMR'
        [rawDataAdj, weights] = dmr_beamformer(rawData, npc, ula, estimated_angle(1));
    case 'PC'
        [rawDataAdj, weights] = pc_beamformer(rawData, npc, ula, estimated_angle(1));
        weights = conj(weights) ;
    case 'LCMV'
        [rawDataAdj, weights] = lcmv_beamformer(rawData, estimated_angle(1), estimated_angle(2), ula, magic, fc);
        weights = conj(weights);
    case 'RVL'
        [rawDataAdj, weights] = rvl_beamformer(rawData, magic, ula, estimated_angle(1));
        weights = conj(weights);
    otherwise
        rawDataAdj = rawData;
        weights = ones(1,4);
end

if c1
    weights = conj(weights);
end
weights = weights/norm(weights)*2;
rawDataAdj(:,1) = rawData(:,1)*weights(1);
rawDataAdj(:,2) = rawData(:,2)*weights(2);
rawDataAdj(:,3) = rawData(:,3)*weights(3);
rawDataAdj(:,4) = rawData(:,4)*weights(4);
rawSum = sum(rawDataAdj(:,ch), 2);
if c2
    weights = conj(weights);
end
%% Cutter
if (cutter)
    [~, fb_lines, fe_lines, ~, ~] = sigFinder(rawSum, 1, 100);
    if isempty(fb_lines)
        cutInds = 1:dataChan;
    else
        if length(fb_lines) > 1
            n = 2;
        else
            n = 1;
        end

        cut_b = fb_lines(n)-off;
        cut_e = fe_lines(n)+off;
        if cut_b < 1
            cut_b = 1;
            if size(fb_lines) > 1
                n = 2;
                cut_b = fb_lines(n)-off;
                cut_e = fe_lines(n)+off;
            else

            end
        end
        if cut_e > dataLen
            cut_e = dataLen;
        end
        cutInds = cut_b:cut_e;
        %         cutInds = fb_lines(1):fe_lines(end);
    end
else cutInds = 1:dataChan;
end

bfSig = rawSum(cutInds);

%% VSA
if (vsa)
    buff = zeros(size(rawSum));
    buff(cutInds) = bfSig;
    vsaSendData(buff, data_v)
    %     vsaSendData(bfSig, data_v)
end