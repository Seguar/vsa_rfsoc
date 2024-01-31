function [yspec, estimated_angle, bfSig, weights, rawData] = rfsocBf(app, vsa, ch, bf, off, gap, cutter, ang_num, estimator, data_v, tcp_client, fc, dataChan, magic, ula)
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
[yspec, estimated_angle] = estimator(rawData'*rawData);
%% Angles

if ch>4
    ch = 1:4;
end

npc = length(estimated_angle);

% estimated_angle = circshift(estimated_angle, -(ang_num-1));
estimated_angle = [estimated_angle(ang_num) estimated_angle];
estimated_angle(ang_num + 1) = [];
switch bf
    case 'Without'
        rawDataAdj = rawData;
        weights = ones(1,4);
    case 'Steering'
        [rawDataAdj, weights] = steerBf(rawData, estimated_angle(1), lambda);
    case 'MVDR'
        [rawDataAdj, weights] = mvdrBf(rawData, estimated_angle(1), magic, ula, fc, c);
        weights = weights';
    case 'DMR'
        [weights, rawDataAdj] = dmr_beamformer(rawData, npc, ula, estimated_angle(1));
    case 'PC'
        [weights, rawDataAdj] = pc_beamformer(rawData, npc, ula, estimated_angle(1));
    case 'LCMV'
        [rawDataAdj, weights] = lcmv_beamformer(rawData, estimated_angle(1), estimated_angle(2), ula, magic, fc);
    otherwise
        rawDataAdj = rawData;
end
% if bf
%     rawData = steerBf(rawData, estimated_angle(ang_num), lambda);
% end
rawSum = sum(rawDataAdj(:,ch), 2);


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
%             return
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

