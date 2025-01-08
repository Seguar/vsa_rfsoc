function estimator = doaEst(doa, ula, scan_axis, num, fc)
switch doa
    case 'MVDR'
        estimator = phased.MVDREstimator('SensorArray',ula,...
            'OperatingFrequency',fc,'ScanAngles',scan_axis,...
            'DOAOutputPort',true,'NumSignals', num);
    case 'MVDRman' 
        estimator = ones(size(scan_axis))';
    case 'MVDRman_corr' 
        load("steering_correction.mat");
        load("pow_claibration_intrp.mat");
        % if length(steering_correction) ~= length(scan_axis)
        %     len = abs(length(steering_correction) - length(scan_axis));
        %     steering_correction = wextend('1D','sym',steering_correction,len/2);
        % end
        estimator = steering_correction; 
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
%     case 'WSFR'
%         estimator = phased.RootWSFEstimator('SensorArray',ula,...
%             'OperatingFrequency',fc);
        %     case 'Monopulse'
        %         estimator = phased.SumDifferenceMonopulseTracker('SensorArray',ula,...
        %             'OperatingFrequency',fc);
    otherwise
        estimator = phased.MVDREstimator('SensorArray',ula,...
    'OperatingFrequency',fc,'ScanAngles',scan_axis,...
    'DOAOutputPort',true,'NumSignals', num);
end