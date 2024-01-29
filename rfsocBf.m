function [yspec, estimated_angle, bfSig] = rfsocBf(app, vsa, ch, bf, off, gap, cutter, ang_num, estimator, data_v, tcp_client, fc, dataChan, magic, ula)
test_z = zeros(1, gap);
% fc = 5.7e9;
% dataChan = 2^14; % Samples per channel (buffer size)

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

switch bf
    case 'Without'
        rawData = rawData;
    case 'Steering'
        rawData = steerBf(rawData, estimated_angle(ang_num), lambda);
    case 'MVDR'
        rawData = mvdrBf(rawData, estimated_angle(ang_num), magic, ula, fc, c);
    case 'LCMV'
        bf
    otherwise
        rawData = rawData;
end
% if bf
%     rawData = steerBf(rawData, estimated_angle(ang_num), lambda);
% end
rawSum = sum(rawData(:,ch), 2);


%% Cutter
if (cutter)
    [~, fb_lines, fe_lines, ~, ~] = sigFinder(rawSum, 1, 100);
    if isempty(fb_lines)
        cutInds = 1:dataChan;
    else
        if size(fb_lines) > 1
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
    end
else cutInds = 1:dataChan;
end

bfSig = rawSum(cutInds);

%% VSA
if (vsa)
    buff = zeros(size(rawSum));
    buff(cutInds) = bfSig;
    vsaSendData(buff, data_v)
end

