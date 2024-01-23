function result = iqdownload(iqdata, fs, varargin)
% Download signal(s) to one or more AWG channels
%
% - iqdata - can be either 
%        a) a array of real or complex samples. Each column is considered
%           to be a real or complex waveform  (support for more than one
%           column is still in-the-works)
%        b) empty. In this case, only a connection check is carried out.
%           If the connection can not be established, an error message
%           is displayed and an empty result is returned
%
% - fs - sample rate in Hz
%
% additional parameters can be specified as attribute/value pairs:
% - 'segmentNumber' - specify the segment number to use (default = 1)
% - 'normalize' - auto-scale the data to max. DAC range (default = 1)
% - 'downloadToChannel - no longer supported
% - 'channelMapping' - new format for AWG channel mapping:
%              vector with 2*m columns and n rows. rows represent AWG channels,
%              Columns represent I and Q for each of column in iqdata.
%              (channelmapping must have twice the number of columns than
%              iqdata)
%              Each element is either 1 or 0, indicating whether the signal
%              is downloaded to the respective AWG channel
% - 'sequence' - description of the sequence table 
% - 'marker' - vector of integers that must have the same length as iqdata
%              low order bits correspond to marker outputs
% - 'arbConfig' - struct as described in loadArbConfig (default: [])
% - 'keepOpen' - if set to 1, will keep the connection to the AWG open
%              after downloading the waveform
% - 'run' - determines if the AWG will be started immediately after
%              downloading the waveform/sequence. (default: 1)
%
% If arbConfig is not specified as an additional parameter, the AWG configuration
% is taken from the default "arbConfig.mat" file (located at
% iqArbConfigFilename())
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

%% parse optional arguments
segmNum = 1;
result = [];
keepOpen = 0;
normalize = 1;
downloadToChannel = [];
channelMapping = [];
sequence = [];
arbConfig = [];
segmentLength = [];
segmentOffset = [];
lOamplitude = [];
lOfCenter = [];
segmName = [];
rms =[];

clear marker;
run = 1;
i = 1;
while (i <= nargin-2)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'segmentnumber';  segmNum = varargin{i+1};
            case 'keepopen'; keepOpen = varargin{i+1};
            case 'normalize'; normalize = varargin{i+1};
            case 'downloadtochannel'; downloadToChannel = varargin(i+1);
            case 'channelmapping'; channelMapping = varargin{i+1};
            case 'chmap'; channelMapping = varargin{i+1};       % synonym for channelmapping
            case 'marker'; marker = varargin{i+1};
            case 'sequence'; sequence = varargin{i+1};
            case 'arbconfig'; arbConfig = varargin{i+1};
            case 'run'; run = varargin{i+1};
            case 'segmentlength'; segmentLength = varargin{i+1};
            case 'segmentoffset'; segmentOffset = varargin{i+1};
            case 'loamplitude'; lOamplitude = varargin{i+1};
            case 'lofcenter'; lOfCenter = varargin{i+1};
            case 'segmname'; segmName = varargin{i+1};
            case 'rms'; rms = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end


% convert the old format for "downloadToChannel" to channelMapping
% new format is array with row=channel, column=I/Q
if (~isempty(downloadToChannel))
    warndlg('"downloadToChannel" is deprecated, please use "channelMapping" instead');
    if (iscell(downloadToChannel))
        downloadToChannel = downloadToChannel{1};
    end
    if (ischar(downloadToChannel))
        switch (downloadToChannel)
            case 'I+Q to channel 1+2'
                channelMapping = [1 0; 0 1];
            case 'I+Q to channel 2+1'
                channelMapping = [0 1; 1 0];
            case 'I to channel 1'
                channelMapping = [1 0; 0 0];
            case 'I to channel 2'
                channelMapping = [0 0; 1 0];
            case 'Q to channel 1'
                channelMapping = [0 1; 0 0];
            case 'Q to channel 2'
                channelMapping = [0 0; 0 1];
            case 'RF to channel 1'
                channelMapping = [1 1; 0 0];
            case 'RF to channel 2'
                channelMapping = [0 0; 1 1];
            case 'RF to channel 1+2'
                channelMapping = [1 1; 1 1];
            otherwise
                error(['unexpected value for downloadToChannel argument: ' downloadToChannel]);
        end
    end
end

% catch the case where channelMapping is (accidently) given as a string
if (ischar(channelMapping))
    errordlg('unexpected format for parameter channelMapping: string');
    error('unexpected format for parameter channelMapping: string');
end

% if markers are not specified, generate square wave marker signal
if (~exist('marker', 'var') || isempty(marker))
    marker = [15*ones(floor(length(iqdata)/2),1); zeros(length(iqdata)-floor(length(iqdata)/2),1)];
end

% make sure the data is in the correct format
if (size(iqdata,1) < size(iqdata,2))
    iqdata = iqdata.';
end

% try to load the configuration from the file arbConfig.mat
arbConfig = loadArbConfig(arbConfig);

% set default channelMapping is none was specified
if (isempty(channelMapping))
    if (isempty(iqdata))
        % make sure that multi-module systems get properly initialized
        channelMapping = zeros(size(arbConfig.channelMask, 2), 2*arbConfig.numChannels);
    elseif (size(iqdata, 2) > 1)
        switch (arbConfig.numChannels)
            case 1
                channelMapping = [1 0];
            case 2
                channelMapping = [1 0 0 0; ...
                                  0 0 1 0];
            otherwise
                channelMapping = [1 0 0 0 0 0 0 0; ...
                                  0 0 1 0 0 0 0 0; ...
                                  0 0 0 0 1 0 0 0; ...
                                  0 0 0 0 0 0 1 0];
        end
    else
        switch (arbConfig.numChannels)
            case 1
                channelMapping = [1 0];
            case 2
                channelMapping = [1 0; 0 1];
            otherwise
                channelMapping = [1 0; 0 1; 1 0; 0 1];
        end
    end
end

% make sure channelMapping has the right width
if (size(channelMapping, 2) < 2 * size(iqdata, 2))
    channelMapping(:, 2 * size(iqdata, 2)) = 0;
end

% normalize if required
if (normalize && ~isempty(iqdata))
    scale = max(max(max(abs(real(iqdata)), abs(imag(iqdata)))));
    if (scale > 1)
        if (normalize)
            iqdata = iqdata / scale;
        else
            errordlg('Data must be in the range -1...+1', 'Error');
        end
    end
end

% apply DAC range
if (isfield(arbConfig, 'DACRange') && arbConfig.DACRange ~= 1)
    iqdata = iqdata .* arbConfig.DACRange;
    % > 100% DAC range --> clip
    if (arbConfig.DACRange > 1)
        if (isreal(iqdata))
            iqdata(iqdata > 1) = 1;
            iqdata(iqdata < -1) = -1;
        else
            idata = real(iqdata);
            qdata = imag(iqdata);
            idata(idata > 1) = 1;
            idata(idata < -1) = -1;
            qdata(qdata > 1) = 1;
            qdata(qdata < -1) = -1;
            iqdata = complex(idata, qdata);
        end
    end
end
    
% apply I/Q gainCorrection if necessary
if (isfield(arbConfig, 'gainCorrection') && arbConfig.gainCorrection ~= 0)
    iqdata = complex(real(iqdata) * 10^(arbConfig.gainCorrection/20), imag(iqdata));
    scale = max(max(max(abs(real(iqdata)), abs(imag(iqdata)))));
    if (scale > 1)
        iqdata = iqdata ./ scale;
    end
end

% extract markers - assume there are two markers per channel
marker = reshape(marker, numel(marker), 1);
marker1 = bitand(uint16(marker),3);
marker2 = bitand(bitshift(uint16(marker),-2),3);

% check granularity
len = length(iqdata);
if (mod(len, arbConfig.segmentGranularity) ~= 0)
    errordlg(['Segment size is ' num2str(len) ', must be a multiple of ' num2str(arbConfig.segmentGranularity)], 'Error');
    return;
elseif (isempty(segmentLength) && len < arbConfig.minimumSegmentSize && len ~= 0)
    errordlg(['Segment size is ' num2str(len) ', must be >= ' num2str(arbConfig.minimumSegmentSize)], 'Error');
    return;
elseif (len > arbConfig.maximumSegmentSize)
    errordlg(['Segment size is ' num2str(len) ', must be <= ' num2str(arbConfig.maximumSegmentSize)], 'Error');
    return;
end

% interleaving --> split to two channels
% Data for channel N (N=1,2,3,...) will be split to channels (2*N-1) and (2*N)
if (~isempty(iqdata) && (isfield(arbConfig, 'interleaving') && arbConfig.interleaving))
    fs = fs / 2;
    iqresult = zeros(size(iqdata,1)/2, 1);      % start with one column; more will be added in the loop
    chMapResult = 0;                            % start with no channelmapping, array will be extended in the loop
    rcol = 1;                                   % start with column 1 in the result array
    for i = 1:size(channelMapping, 1)           % iterate over the channels
        k = find(channelMapping(i,:), 1);       % find out which signal shall be loaded into this channel
        if (k ~= 0)                             % check, if we have to do anything at all
            col = ceil(k/2);                    % determine the column from which to get data
            if (mod(k,2) == 1)                  % if k is odd, use real part, otherwise imag
                val = real(iqdata(:,col));
            else
                val = imag(iqdata(:,col));
            end
            % split into even/odd for the sub-DACs. Make it a complex number for backward compatibility
            iqresult(:,rcol) = complex(val(1:2:end), val(2:2:end));
            % Changes BK (update for M8199A-ILV)
            chMapResult(2*i-1, 2*rcol-1) = 1;   % real is in col 2*N-1
            chMapResult(2*i, 2*rcol) = 1;       % imag is in col 2*N
% re-mapping for M8199A-ILV is done in the iqdownload_M8199A.m
%             chMapResult(i, 2*rcol-1) = 1; % real is in col 2*N-1
%             chMapResult(i+2, 2*rcol) = 1; % imag is in col 2*N
            rcol = rcol + 1;
        end
    end
    iqdata = iqresult;                          % finally overwrite the old variables
    channelMapping = chMapResult;
    
    if (~isempty(marker1))
        marker1 = marker1(1:2:end);
        marker2 = marker2(1:2:end);
    end
end

    
%% establish a connection and download the data
try
    switch (arbConfig.model)
        case { '81180A' '81180B' }
            result = iqdownload_81180A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { 'M8190A' 'M8190A_base' 'M8190A_14bit' 'M8190A_12bit' 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }
            result = iqdownload_M8190A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run, segmentLength, segmentOffset);
        case { 'M8121A' 'M8121A_base' 'M8121A_14bit' 'M8121A_12bit' 'M8121A_DUC_x3' 'M8121A_DUC_x12' 'M8121A_DUC_x24' 'M8121A_DUC_x48' }
            result = iqdownload_M8121A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run, segmentLength, segmentOffset);
        case { 'M8195A_Rev0' }
            result = iqdownload_M8195A_Rev0(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case { 'M8195A_Rev1' }
            result = iqdownload_M8195A_Rev1(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case { 'M8195A_1ch' 'M8195A_1ch_mrk' 'M8195A_2ch' 'M8195A_2ch_mrk' 'M8195A_4ch' 'M8195A_2ch_256k' 'M8195A_4ch_256k' 'M8195A_2ch_dupl' }
            result = iqdownload_M8195A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run, segmentLength, segmentOffset);
        case { 'M8196A' }
            result = iqdownload_M8196A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case { 'M8194A' }
            result = iqdownload_M8194A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case { 'M8198A' }
            result = iqdownload_M8198A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
		case { 'M8199A' 'M8199A_ILV' }
            result = iqdownload_M8199A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case { 'M8199B' 'M8199B_NONILV' }
            result = iqdownload_M8199B(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
		case { 'M933xA' 'M9330A/M9331A' }
            result = iqdownload_M933xA(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case 'M9336A'
            result = iqdownload_M9336A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { 'M5300x_baseband' 'M5300x_modulated' 'M5300x_std' }
            result = iqdownload_M5300x(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { 'M5301x'}
            result = iqdownload_M5301x(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { 'M3201A' 'M3202A' 'M3201A_CLF' 'M3202A_CLF' 'M3201A_CLV' 'M3202A_CLV' }
            result = iqdownload_M3202A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case 'N824xA'
            result = iqdownload_N824xA(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { '81150A' '81160A' }
            result = iqdownload_81150A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case 'AWG7xxx'
            result = iqdownload_AWG7xxx(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case 'AWG7xxxx'
            result = iqdownload_AWG7xxxx(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { 'N5182A' 'N5182B' 'N5172B' 'N5166B' 'E8267D' 'N51xxA (MXG)' 'E4438C'}
            result = iqdownload_N51xxA(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName);
        case { 'M9384B' 'M9384B_1Ch' 'M9384B_2Ch_IND' 'M9384B_2Ch_COH' 'M9383B'}
            result = iqdownload_M9384B(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName, segmentLength, segmentOffset);        
        case { 'S91xxA_RfOutput', 'S91xxA_RRH1_RFHD1', 'S91xxA_RRH1_RFHD2'}
            result = iqdownload_S91xxA(arbConfig, fs, iqdata, marker1, marker2, keepOpen, lOamplitude, lOfCenter, segmName);
        case { 'S93072B_PNA' }
            result = iqdownload_S93072B_PNA(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case {'M9383A'}
            result = iqdownload_M9383A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName);
        case { 'M9381A' 'M938xA' }
            result = iqdownload_M9381A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { '3351x' '3352x' '3361x' '3362x' '3362x_64MS'}
            result = iqdownload_33xxx(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
        case { 'MUXDAC' }
            result = iqdownload_MUXDAC(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run);
        case {'M9410A'}
            result = iqdownload_M9410A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName);
        case {'M9415A'}
            result = iqdownload_M9415A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName);
        case {'M8135A'}
            result = iqdownload_M8135A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName);
        case { 'M9484C' 'M9484C_1Ch' 'M9484C_2Ch_IND' 'M9484C_2Ch_COH'}
            result = iqdownload_M9484C(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName, segmentLength, segmentOffset);        
        otherwise
            error(['instrument model ' arbConfig.model ' is not supported']);
    end
catch ex
    msg = sprintf('%s\n%s', ex.message, ex.identifier);
    for i=1:length(ex.stack)
        if (ex.stack(i).name(1) == '@')
            break;
        end
        msg = sprintf('%s\n%s, line %d', msg, ex.stack(i).name, ex.stack(i).line);
    end
    errordlg(msg);
end
end
