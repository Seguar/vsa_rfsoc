function [yspec, estimated_angle, bfSig, weights, rawData, vsa_time, adReset] = rfsocBf(app, vsa, ch, bf, off, gap, cutter, ang_num, num, data_v, tcp_client, fc, dataChan, diag, bwOff, ula, scan_axis, ...
    c1, c2, fsRfsoc, bw, c, estimator, alg_scan_res, mis_ang, alpha, gamma, iter, setup_v, debug, pow_claibration_intrp, coupling_matrix, IQcomp, adIQcomp, phComp, powComp, coupComp, sizeL, stepMU, adReset, steering_correction)
    % Inputs:
%   - app: Application object
%   - vsa: Flag indicating whether to perform VSA (Vector Signal Analyzer) operation
%   - ch: Channel number
%   - bf: Beamforming method ('Steering', 'MVDR', 'DMR', 'PC', 'LCMV', 'RVL', 'QCB')
%   - off: Offset value for cutter
%   - gap: Gap value for test_z
%   - cutter: Flag indicating whether to perform cutting operation
%   - ang_num: Angle number
%   - data_v: Data vector
%   - tcp_client: TCP client object
%   - fc: Center frequency
%   - dataChan: Number of data channels
%   - diag: Diagonal loading value for MVDR beamformer
%   - bwOff: Bandwidth offset value for LCMV beamformer
%   - ula: Uniform Linear Array object
%   - scan_axis: Scan axis values
%   - c1: Flag indicating whether to conjugate weights
%   - c2: Flag indicating whether to conjugate weights for specific channels
%   - fsRfsoc: Sampling frequency of RFSoC data
%   - bw: Bandwidth value
%   - c: Speed of light
%   - estimator: DOA estimation function
%   - alg_scan_res: Algorithm scan resolution
%   - mis_ang: Misalignment angle
%   - alpha: Alpha value for QCB beamformer
%   - gamma: Gamma value for RVL beamformer
%   - iter: Number of iterations for QCB beamformer
%
% Outputs:
%   - yspec: Spectrum of the estimated angle
%   - estimated_angle: Estimated angle
%   - bfSig: Beamformed signal
%   - weights: Beamforming weights
%   - rawData: Raw RFSoC data
%
% Description:
%   This function performs beamforming and direction of arrival (DOA) estimation on RFSoC data. It takes in various parameters and performs the following steps:
%   1. Receives RFSoC data through a TCP connection.
%   2. Filters the received data using a specified bandwidth.
%   3. Estimates the DOA using a specified DOA estimation algorithm.
%   4. Selects the desired channel(s) and calculates the power of the beamformed signal.
%   5. Performs beamforming based on the specified method.
%   6. Applies conjugation and normalization to the beamforming weights.
%   7. Cuts the beamformed signal based on specified parameters.
%   8. Optionally performs VSA operation by sending the beamformed signal to a Vector Signal Analyzer.
%
% Example:
%   [yspec, estimated_angle, bfSig, weights, rawData] = rfsocBf(app, true, 1, 'MVDR', 10, 5, true, 2, data_v, tcp_client, 2.4e9, 8, 0.1, ula, scan_axis, ...
%       true, false, 1e9, 100e6, 3e8, @doaEstimation, 0.01, 10, 0.5, 100);
%
% See also: tcpDataRec, filtSig, steerBf, mvdrBf, dmr_beamformer, pc_beamformer, lcmv_beamformer, rvl_beamformer, qcb_beamformer_algo_2
test_z = zeros(1, gap);

%% TCP
data_size = dataChan * 8;
channels = 8;
rawData = tcpDataRec(tcp_client, data_size, channels);
if debug
    rx_time = toc;
    disp(['rx time ' num2str(rx_time*1000) ' ms'])
end
%% Adaptive IQ compensation
if (adReset)
    correct_filter = zeros(sizeL, 4);
end
if adIQcomp
    stepSizeMat = diag(ones(size(correct_filter)));
    [~, w_opt, ~] = adaptiveIQCompensation(rawData(:,1), stepSizeMat*stepMU, correct_filter(:,1));
    correct_filter(:,1) = w_opt;
    [~, w_opt, ~] = adaptiveIQCompensation(rawData(:,2), stepSizeMat*stepMU, correct_filter(:,2));
    correct_filter(:,2) = w_opt;
    [~, w_opt, ~] = adaptiveIQCompensation(rawData(:,3), stepSizeMat*stepMU, correct_filter(:,3));
    correct_filter(:,3) = w_opt;
    [~, w_opt, ~] = adaptiveIQCompensation(rawData(:,4), stepSizeMat*stepMU, correct_filter(:,4));
    correct_filter(:,4) = w_opt;
end
%% IQ compensation application
if IQcomp
    rawData(:,1) = rawData(:,1) + conv(conj(rawData(:,1)), correct_filter(:,1), 'same');
    rawData(:,2) = rawData(:,2) + conv(conj(rawData(:,2)), correct_filter(:,2), 'same');
    rawData(:,3) = rawData(:,3) + conv(conj(rawData(:,3)), correct_filter(:,3), 'same');
    rawData(:,4) = rawData(:,4) + conv(conj(rawData(:,4)), correct_filter(:,4), 'same');
end
%% Coupling corrections
if coupComp
    rawData = (coupling_matrix*rawData.').';
end


%% Matlab MVDR DOA FUNC
rawData = filtSig(rawData, fsRfsoc, bw);

%% DOA
Rx = rawData'*rawData;    %Data covarivance matrix 
if isa(estimator, 'double')
    num_elements = 4;
    A = zeros(num_elements,1); 
    % rawData = normalize(rawData);
    
    Rx_Inv = Rx^(-1);           %Inverse of covariance matrix
    lambda = c/fc;
    d = lambda/2;
%     for t=1:length(scan_axis) 
%         A = exp(-1j*2*pi*d*(0:num_elements-1).'*sind(scan_axis(t))/lambda);
%         A_fixed = A.*estimator(t,:)';
%         B_fixed = A_fixed'*Rx_Inv*A_fixed;
% %         yspec(t) = 10*log10(abs(1/B_fixed)); 
%         yspec(t) = abs(1/B_fixed); 
%     end
    for t=1:length(scan_axis)
        A = exp(-1j*pi*(0:num_elements-1)'*sind(scan_axis(t)));
        A_fixed = A.*estimator(t,:)';
        % A_fixed = A.*estimator(t,:).';
        sig_final_fixed = rawData./(pow_claibration_intrp(t, :).^0.5);
        Rx_fixed = sig_final_fixed'*sig_final_fixed;    %Data covarivance matrix 
        Rx_Inv_fixed = Rx_fixed^(-1);           %Inverse of covariance matrix
        B_fixed = A_fixed'*Rx_Inv_fixed*A_fixed;
        % B = A'*Rx_Inv*A;
        % yspec(t) = 10*log10(abs(1/B)); 
        yspec(t) = 10*log10(abs(1/B_fixed)); %% yspec_fixed
        
    end
    [~,ind] = findpeaks(yspec,"SortStr","descend");
    ind = ind(1:num);
    estimated_angle = scan_axis(ind);
else
    try
        [yspec, estimated_angle] = estimator(Rx);
    catch
        estimated_angle = estimator(Rx);
        yspec = zeros(size(scan_axis));
    end
end
%% Angles
if ch>4
    ch = 1:4;
end
%% Signal choice
estimated_angle = estimated_angle(not(isnan(estimated_angle)));
npc = sum(~isnan(estimated_angle));
% if npc > 2
    
    % npc = 2;
% end
% estimated_angle = [estimated_angle(ang_num) estimated_angle];
% estimated_angle(ang_num + 1) = [];
powbp = zeros(1,npc);
for i = 1:npc
    [rawDataAdjM, ~] = steerBf(rawData, estimated_angle(i), ula, fc);
    rawSumM = sum(rawDataAdjM, 2);
    powbp(i,:) = bandpower(rawSumM,fsRfsoc,[-bw/2 bw/2]);
end
[~, idx] = sort(powbp, 'descend');
if idx(ang_num) == 2
    estimated_angle = flip(estimated_angle);
end
estimated_angle = estimated_angle(1:num);
%% Power and Phase corrections
ang_idx = find(scan_axis == estimated_angle(1));
if phComp
    try
        sig_correction = estimator(ang_idx,:);
    catch
        sig_correction = steering_correction(ang_idx,:);
    end
    
    pow_correction = pow_claibration_intrp(ang_idx,:).^0.5;
    rawData = conj(sig_correction).*rawData./pow_correction;
end
%% Beamforming
switch bf
    case 'Steering'
        [rawDataAdj, weights] = steerBf(rawData, estimated_angle(1), ula, fc);
    case 'MVDR'
        [rawDataAdj, weights] = mvdrBf(rawData, estimated_angle(1), diag, ula, fc, c);
        weights = conj(weights);
    case 'DMR'
        [rawDataAdj, weights] = dmr_beamformer(rawData, npc, ula, estimated_angle(1));
    case 'PC'
        [rawDataAdj, weights] = pc_beamformer(rawData, npc, ula, estimated_angle(1));
        weights = conj(weights);
    case 'PC_corr'
        [rawDataAdj, weights] = pc_beamformer(rawData, npc, ula, estimated_angle(1), estimator);
        weights = conj(weights) ;        
    case 'LCMV'
        [rawDataAdj, weights] = lcmv_beamformer(rawData, estimated_angle(1), estimated_angle(2), ula, bwOff, fc);
        weights = conj(weights);
    case 'RVL'
        [rawDataAdj, weights] = rvl_beamformer(rawData, gamma, ula, estimated_angle(1));
        weights = conj(weights);
    case 'RAB PC'
        [rawDataAdj, weights] = rab_pc_beamformer(rawData, npc, ula, estimated_angle(1), diag);
%         weights = conj(weights);
    case 'DL MVDR'
%         [rawDataAdj, weights] = dl_mvdr_beamformer(rawData, ula, estimated_angle(1));
% %         weights = conj(weights);
        diag = mean(var(rawData))*diag;
        [rawDataAdj, weights] = mvdrBf(rawData, estimated_angle(1), diag, ula, fc, c);
    case 'DL ITER MVDR'
        [rawDataAdj, weights] = dl_mvdr_beamformer(rawData, ula, estimated_angle(1));
%         weights = conj(weights);
    case 'QCB'
        [rawDataAdj, weights] = qcb_beamformer_algo_2(rawData, ula, estimated_angle(1), mis_ang, gamma, alpha, iter, alg_scan_res, fc);
    otherwise
        rawDataAdj = rawData;
        weights = ones(1,4);
end

% if c1
%     weights = conj(weights);
% end
weights = weights/norm(weights)*2;
rawDataAdj(:,1) = rawData(:,1)*weights(1);
rawDataAdj(:,2) = rawData(:,2)*weights(2);
rawDataAdj(:,3) = rawData(:,3)*weights(3);
rawDataAdj(:,4) = rawData(:,4)*weights(4);
rawSum = sum(rawDataAdj(:,ch), 2);
% if c2
%     weights = conj(weights);
% end
weights = weights(ch);
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
            end
        end
        if cut_e > dataChan
            cut_e = dataChan;
        end
        % cutInds = cut_b:cut_e;
        cutInds = fb_lines(1):fe_lines(end);
    end
else cutInds = 1:dataChan;
end

bfSig = rawSum(cutInds);
if debug
    bf_time = toc;
    disp(['bf time ' num2str((bf_time - rx_time)*1000) ' ms'])
end
%% VSA
if (vsa)
    buff = zeros(size(rawSum));
    buff(cutInds) = bfSig/2^16; % VSA normalization
    vsaSendData(buff, data_v)
    %     vsaSendData(bfSig, data_v)
    if debug
        vsa_time = toc;
        disp(['vsa time ' num2str((vsa_time - bf_time)*1000) ' ms'])
    else 
        vsa_time = 0;
    end
end